![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# y_square
Project in ROKA. I want to make digital circuit even if here is desert of digital.

## 프로젝트 소개
이 프로젝트는 내가 전자공학 학부생으로서 배웠던 디지털회로 제작 지식을 가지고 극한의 환경에서 MPU 및 firmware를 만들어 보는 것에 초점을 두고 있다. 이를 통해 ASIC칩 제작 경험 및 불가능을 해냈다는 자신감을 가지고자 한다. 프로젝트는 데스크톱 크롬(웹환경) 및 스마트폰에서만 작성하였다. 자세한 내용은 아래에 작성되어 있다. 

## How to set up this Verilog project

1. Add your Verilog files to the `src` folder.
2. Edit the [info.yaml](info.yaml) and update information about your project, paying special attention to the `source_files` and `top_module` properties. If you are upgrading an existing Tiny Tapeout project, check out our [online info.yaml migration tool](https://tinytapeout.github.io/tt-yaml-upgrade-tool/).
3. Edit [docs/info.md](docs/info.md) and add a description of your project.
4. Adapt the testbench to your design. See [test/README.md](test/README.md) for more information.

The GitHub action will automatically build the ASIC files using [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/).

프로젝트는 다음과 같은 환경에서 제작되었다:
- ASIC making (https://tinytapeout.com/)
- Verilog simulator (https://edaplayground.com/)

## 프로젝트 구성
프로젝트는 크게 4가지 파트로 구성된다.
1. 실제 MPU설계를 위한 도식 및 verilog code
2. ASIC 제작을 위한 파일
3. firmware assambly code
4. (가능하다면) parser code for MPU

## 저작권 및 사용권 정보
이 프로젝트는 오픈소스이다. 원하는 누구든 이 레포지토리의 출처만 밝히고 사용해도 된다. 
나 또한 Gemini의 도움을 많이 받아 제작한 프로젝트이다. 
충분한 열정과 제반지식이 있다면, 이 프로젝트를 보는 모든 사람들이 스스로 AI와 함께 이러한 칩을 제작할 수 있으리라 생각한다. 

## MPU 소개
y_square architecture는 다음과 같은 특징 및 구성을 가지고 있다. 

- 16-bit processor
- 8 general purpose register: R0 for zero, R6 for stack pointer, R7 for link register
- It has an ISA shown below.

| assembly format | RTL | OPcode | Func | IsImmSigned | type |
| :-: | :-: | :-: | :-: | :-: | :-: |
| ADD Rd, Rs1, Rs2 | Rd <- Rs1 + Rs2 | 0000 | 000 | - | R |
| SUB Rd, Rs1, Rs2 | Rd <- Rs1 - Rs2 | 0000 | 001 | - | R |
| AND Rd, Rs1, Rs2 | Rd <- Rs1 & Rs2 | 0000 | 010 | - | R |
| OR  Rd, Rs1, Rs2 | Rd <- Rs1 or Rs2 | 0000 | 011 | - | R |
| XOR Rd, Rs1, Rs2 | Rd <- Rs1 xor Rs2 | 0000 | 100 | - | R |
| SLT Rd, Rs1, Rs2 | Rd <- (Rs1 < Rs2) ? 1:0 | 0000 | 101 | - | R |
| SLR Rd, Rs1, Rs2 | Rd <- Rs1 >> Rs2 | 0000 | 110 | - | R |
| SLL Rd, Rs1, Rs2 | Rd <- Rs1 << Rs2 | 0000 | 111 | - | R |
| LW Rd, Rs, imm | Rd <- Mem[Rs + imm] | 0100 | - | True | I |
| SW Rd, Rs, imm | Mem[Rs + imm] <- Rd | 0101 | - | True | I |
| ADDI Rd, Rs, imm | Rd <- Rs + imm | 1000 | - | True | I |
| BEQ Rd, Rs, imm | if(Rd == Rs), PC <- PC + imm | 1001 | - | True | I |
| ANDI Rd, Rs, imm | Rd <- Rs & imm | 1010 | - | False | I |
| J imm | PC <- PC[15:13] + imm << 1 | 1100 | - | False | J |
| JAL imm | PC <- PC[15:13] + imm << 1, LR <- PC | 1101 | - | False | J |
| JR | PC <- LR | 1110 | - | - | J |


## 개발일지
2026-01-29: 전입 온 군부대에 싸지방이 있는 것을 확인하고 바로 CPU제작을 할 수 있다는 사실에 기뻐하며 CPU를 어떻게 만들지 생각하게 되었음.

2026-02-11: 이 날은 처음으로 공책을 펴서 CPU를 만들겠다는 목표를 시작한 날이었다. 만들고자 하는 것을 정하려고 시도했고, 이러한 목표를 확실히 하기 위한 일련의 작업을 하였다. 

2026-02-12: 이 날은 내가 전에 구성해 두었던 ISA를 공책에 배껴적고, 이를 기반으로 어떠한 시스템을 만들지 생각해 보았다. 이전까지는 실제 컴퓨터 같이 작동하는 시스템을 만들고자 하였으나, 이것이 불가능하다는 사실을 깨닫고, 목표를 낮추기 시작했다. 
이 날 모든 구성은 완성되었다. y_square라는 이름도, MPU로 만들어서 외부를 제어하는 간단한 펌웨어를 탑제하겠다는 것도 이 날 정했다. 

2026-02-13: 이 날은 공책에 CPU의 ISA를 정의하였다. 16bit에 맞게, 2000개라는 로직 게이트 제약에 맞게, 최대한 적은 수의 명령어와 효율적인 방식의 명령어 구성을 택하였다. 

2026-02-14: 이 날은 어떻게 해야 실제 ASIC을 만들 수 있는지 조사하고, 이 Gihub repository를 제작하였다. 생각보다 verilog code가 asic으로 가는 길은 복잡고도 험했다. 이를 타개하기 위해 노력해야 할 것이다. 오늘은 가능한 한 최대한 많이 datapath도 그려볼 예정이다. 파이팅이다. 나는 끝까지 이 프로젝트를 성공시킬 것이다. 목표는 올해 11월. 

2026-02-15: 이 날은 외출이 있었던 날이다. 외출로 PC방에 와서 남은 리드미 파일을 작성하고, 어떻게 해야 내 프로젝트를 ASIC으로 변환할 수 있는지, 구체적으로는 나의 verilog file이 어떻게 asic을 만드는 도면으로 바뀌는지 알아보았다. 생각보다 복잡지는 않다. 하지만, 프로그램을 설치해야 하는 일이 존재해, 싸지방에서는 어려울 것 같다. 우선은 Verilog code만 짜서 디버깅하는 쪽으로 방향을 잡아야 할 듯 하다. 

2026-02-20: 이 날은 IHP shuttle submission templete에 내 프로젝트를 이식하였다. 이 때문에 불필요한 레포지토리를 지우고 새로 작성하였다. 추가로, 기존에 작성하였던 몇 가지 베릴로그 코드도 업로드하였다. 

2026-02-21: 이 날은 CPU의 dapapath에 들어갈 모든 코드를 작성 완료했다. 테스트는 아직 진행하지 않았다. 컨트롤 모듈을 모두 작성한 후에, 큰 테스트벤치를 하나 만들어 돌려보려 한다. 
