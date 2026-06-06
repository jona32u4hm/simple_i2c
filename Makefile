
TB = sim/testbench.v
MTB = sim/master_testbench.v
STB = sim/slave_testbench.v
OUT = build/output.out




all: $(TB) syn/synth.ys
	make synthesize
	make simulate

simulate:
	@mkdir -p build
	iverilog -o $(OUT) $(TB)
	vvp $(OUT)
	gtkwave i2c_simulation.vcd
simulate_master:
	@mkdir -p build
	iverilog -o $(OUT) $(MTB)
	vvp $(OUT)
	gtkwave i2c_simulation.vcd
simulate_slave:
	@mkdir -p build
	iverilog -o $(OUT) $(STB)
	vvp $(OUT)
	gtkwave i2c_simulation.vcd


synthesize:
	@mkdir -p build
	yosys -s syn/synth.ys