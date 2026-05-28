NAME = cpu
SRC = cpu/*.v vga/*.v vga/hdl/*.sv vga/hdl/*.v
DUT = cpu2
LPF = icepi-zero.lpf
PROGRAM = programs/jumps.s

validate:
	@ iverilog cpu/*.v -I ./
	@ echo "All verilog files valid."

compile:
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o program.o ${PROGRAM}
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x00000000 -o program.elf program.o
	riscv64-unknown-elf-objcopy -O binary program.elf program.bin
	xxd -c 4 -e program.bin | awk '{print $$2}' > program.hex

	@ echo "\nProgram successfully compiled."

wave:
	iverilog cpu/*.v ./testbenches/$(DUT)_tb.v
	vvp a.out
	gtkwave wave.vcd

build: compile
	yosys -p "synth_ecp5 -top top -noflatten -json $(NAME).json; stat" $(SRC)
	nextpnr-ecp5 --25k --package CABGA256 --json $(NAME).json --lpf $(LPF) --textcfg $(NAME).config
	ecppack --svf $(NAME).svf $(NAME).config $(NAME).bit

run: build
	openFPGALoader -cft231X --pins=7:3:5:6 $(NAME).bit

load:
	openFPGALoader -cft231X --pins=7:3:5:6 $(NAME).bit

flash: build
	openFPGALoader -cft231X --pins=7:3:5:6 $(NAME).bit -f

clean:
	rm $(NAME).json $(NAME).config $(NAME).svf $(NAME).bit \
	program.hex program.bin program.o wave.vcd a.out program.elf
