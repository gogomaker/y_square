# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles

# -------------------------------------------------------------------
# 📝 MPU를 테스트할 가상의 어셈블리 프로그램 (기계어 매핑)
# -------------------------------------------------------------------
# PC는 32 (0x0020)에서 시작합니다.
# 
# [Assembly]                 [Machine Code]      [설명]
# ADDI R1, R0, 3           -> 0x0403           # R1 = 3
# ADDI R2, R0, 4           -> 0x0804           # R2 = 4
# ADD  R3, R1, R2          -> 0x8CA0           # R3 = R1 + R2 = 7
# SW   R3, R0, 8           -> 0xEC08           # Mem[8](Digital Out) = 7 (uo_out에 7 출력)
# SLL  R4, R3, R1          -> 0x919E           # R4 = R3 << R1 = 7 << 3 = 56
# SW   R4, R0, 8           -> 0xF008           # Mem[8](Digital Out) = 56 (uo_out에 56 출력)
# J    32                  -> 0x6040           # 다시 32번지로 점프 (무한 루프)
# -------------------------------------------------------------------
memory = {
    32: 0x0403, 
    33: 0x0804, 
    34: 0x8CA0, 
    35: 0xEC08, 
    36: 0x919E, 
    37: 0xF008, 
    38: 0x6040, 
}

# -------------------------------------------------------------------
# 💾 가상의 SPI FRAM Slave 인터페이스 (Coroutine)
# -------------------------------------------------------------------
async def spi_slave(dut):
    """CPU의 SPI 읽기 요청을 가로채서 메모리 값을 MISO로 반환합니다."""
    dut.uio_in.value = 0
    state = "WAIT"
    counter = 0
    cmd_addr = 0
    data_to_send = 0
    
    while True:
        # 클럭의 Falling Edge에서 SPI 신호를 샘플링 (CPU는 Rising에서 처리하므로 안정적)
        await FallingEdge(dut.clk)
        
        try:
            out_val = dut.uio_out.value.integer
        except ValueError:
            out_val = 0
            
        cs_n = (out_val >> 4) & 1  # uio_out[4]
        mosi = (out_val >> 6) & 1  # uio_out[6]
        
        if cs_n == 1:
            state = "WAIT"
            counter = 0
            continue
            
        if state == "WAIT":
            state = "RCV_CMD"
            counter = 0
            cmd_addr = 0
            
        if state == "RCV_CMD":
            # MOSI로부터 32비트(CMD 8bit + ADDR 24bit)를 수신
            cmd_addr = (cmd_addr << 1) | mosi
            counter += 1
            if counter == 32:
                state = "SEND_DATA"
                counter = 0
                cmd = (cmd_addr >> 24) & 0xFF
                # SPI.v에서 주소를 1비트 좌측 시프트해서 보내므로 다시 복구
                addr = ((cmd_addr & 0xFFFFFF) >> 1) 
                
                if cmd == 0x03: # READ 명령어인 경우
                    data_to_send = memory.get(addr, 0x0000)
                else:
                    data_to_send = 0x0000
                    
        elif state == "SEND_DATA":
            # 16비트 데이터를 MISO(uio_in[7])로 송신
            bit = (data_to_send >> (15 - counter)) & 1
            current_uio = dut.uio_in.value.integer if dut.uio_in.value.is_resolvable else 0
            dut.uio_in.value = (current_uio & ~0x80) | (bit << 7)
            counter += 1
            if counter == 16:
                state = "WAIT"


# -------------------------------------------------------------------
# 🚀 메인 테스트 시나리오
# -------------------------------------------------------------------
@cocotb.test()
async def test_project(dut):
    dut._log.info("== Y_SQUARE MPU Test Start ==")

    # 40MHz 클럭 생성 (25ns 주기)
    clock = Clock(dut.clk, 25, unit="ns")
    cocotb.start_soon(clock.start())

    # SPI Slave 모의 장치 백그라운드 실행
    cocotb.start_soon(spi_slave(dut))

    # CPU Reset 초기화
    dut._log.info("Resetting CPU...")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("CPU is now running and fetching instructions via SPI...")

    # 1. 첫 번째 연산 결과 대기 (R3 = 7 -> SW명령어로 uo_out에 7 출력)
    timeout = 0
    while (not dut.uo_out.value.is_resolvable) or (dut.uo_out.value.integer != 7):
        await ClockCycles(dut.clk, 10)
        timeout += 10
        if timeout > 3000:
            assert False, "Timeout! uo_out 단자에서 '7'이 출력되지 않았습니다."
            
    dut._log.info(f"✅ Success 1: uo_out output is {dut.uo_out.value.integer} (Expected 7)")

    # 2. 두 번째 연산 결과 대기 (R4 = 56 -> SW명령어로 uo_out에 56 출력)
    timeout = 0
    while (not dut.uo_out.value.is_resolvable) or (dut.uo_out.value.integer != 56):
        await ClockCycles(dut.clk, 10)
        timeout += 10
        if timeout > 3000:
            assert False, "Timeout! uo_out 단자에서 '56'이 출력되지 않았습니다."
            
    dut._log.info(f"✅ Success 2: uo_out output is {dut.uo_out.value.integer} (Expected 56)")
    
    dut._log.info("== All Instructions Executed Successfully! ==")
