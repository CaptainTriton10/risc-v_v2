NAME = cpu
SRC = cpu/*.v vga/*.v vga/hdl/*.sv vga/hdl/*.v
DUT = cpu2
LPF = icepi-zero.lpf

validate:
	iverilog cpu/*.v -I ./

wave:
	iverilog cpu/*.v ./testbenches/$(DUT)_tb.v
	vvp a.out
	gtkwave wave.vcd

build:
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
	rm $(NAME).json $(NAME).config $(NAME).svf $(NAME).bit
