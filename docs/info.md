## How it works

My project is 16-bit MPU. If you arrange external hardware correctly and program it with binary code, It will be works.
Here is ISA for MPU.

| assembly format | RTL | OPcode | Func | IsImmSigned | type |
| :-: | :-: | :-: | :-: | :-: | :-: |
| ADD Rd, Rs1, Rs2 | Rd <- Rs1 + Rs2 | 101 | 000 | - | R |
| SUB Rd, Rs1, Rs2 | Rd <- Rs1 - Rs2 | 101 | 001 | - | R |
| AND Rd, Rs1, Rs2 | Rd <- Rs1 & Rs2 | 101 | 010 | - | R |
| OR  Rd, Rs1, Rs2 | Rd <- Rs1 or Rs2 | 101 | 011 | - | R |
| XOR Rd, Rs1, Rs2 | Rd <- Rs1 xor Rs2 | 101 | 100 | - | R |
| SLT Rd, Rs1, Rs2 | Rd <- (Rs1 < Rs2) ? 1:0 | 101 | 101 | - | R |
| SLR Rd, Rs1, Rs2 | Rd <- Rs1 >> Rs2 | 101 | 110 | - | R |
| SLL Rd, Rs1, Rs2 | Rd <- Rs1 << Rs2 | 101 | 111 | - | R |
| LW Rd, Rs, imm | Rd <- Mem[Rs + imm] | 110 | - | True | I |
| SW Rd, Rs, imm | Mem[Rs + imm] <- Rd | 111 | - | True | I |
| ADDI Rd, Rs, imm | Rd <- Rs + imm | 000 | - | True | I |
| BEQ Rd, Rs, imm | if(Rd == Rs), PC <- PC + imm | 001 | - | True | I |
| ANDI Rd, Rs, imm | Rd <- Rs & imm | 010 | - | False | I |
| J imm | PC <- PC[15:13] + imm << 1 | 011 | - | False | J |
| JAL imm | PC <- PC[15:13] + imm << 1, LR <- PC | 1010 | - | False | J |
| JR | PC <- LR | 1011 | - | - | J |

R-type: OPcode(3) / Rd(3) / Rs1(3) / Rs2(3) / Func(3) / NC(1)

I-type: OPcode(3) / Rd(3) / Rs(3) / imm(7)

J instruction: OPcode(3) / address(13)

JAL & JR : OPcode(4) / address(12) 

For example, if you want to add R3 and R4 and save it to R2, you can write assembly code like

ADD R2 R3 R4, and binary code is 1010 0100 1110 0000.


Memory address map of MPU is shown below.

I use MMIO, so if you want to use IO device, you should use LW and SW instructions for communication.

| Address number | Device |
| :---: | :---: |
| 0x0000~0x0007 | Digital in |
| 0x0008~0x000F | Digital out |
| 0x0010~0x0017 | UART RX buffer |
| 0x0018~0x001F | UART TX buffer |
| 0x0020~0xFFFF | QSPI FRAM |

## How to test

I will write IO test binary codes (maybe 3 code sets) here. 

## External hardware

1. 8 LEDs for output pins. (Can change)
2. 8 switchs for input pins. (Can change)
3. PC or arduino for UART communcation. (Not essential)
4. 64kB QSPI FRAM for memory of MPU. (Essential)

Here is pinmap of my MPU. 
| PIN number | IN | OUT | INOUT |
| :---: | :---: | :---: | :---: |
| 0 | Input pin 0 | Ounput pin 0 | RX |
| 1 | Input pin 1 | Ounput pin 1 | TX |
| 2 | Input pin 2 | Ounput pin 2 | INTERRUPT |
| 3 | Input pin 3 | Ounput pin 3 | NC |
| 4 | Input pin 4 | Ounput pin 4 | CS |
| 5 | Input pin 5 | Ounput pin 5 | SCLK |
| 6 | Input pin 6 | Ounput pin 6 | MOSI |
| 7 | Input pin 7 | Ounput pin 7 | MISO |
