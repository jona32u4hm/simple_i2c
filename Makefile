
TB = sim/testbench.v
OUT = build/output.out




all: $(TB) syn/synth.ys
	make synthesize
	make simulate

simulate:
	@mkdir -p build
	iverilog -o $(OUT) $(TB)
	vvp $(OUT)
	gtkwave i2c_simulation.vcd

testrom2:
	@mkdir -p build
	iverilog -o $(OUT) $(TB) -Dtestrom2
	vvp $(OUT)
	gtkwave i2c_simulation.vcd


synthesize:
	@mkdir -p build
	yosys -s syn/synth.ys