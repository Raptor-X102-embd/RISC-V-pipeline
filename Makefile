VERILATOR = verilator
COMMON_FLAGS = -Wall -Wno-fatal
BUILD_FLAGS = --build -j 0 --trace
LINT_FLAGS = --lint-only

INCLUDE_DIRS = -Iheaders -Isrc/core -Isrc/fetch -Isrc/decode -Isrc/execute -Isrc/memory -Isrc/writeback

RTL_SOURCES = $(shell find src -name "*.sv")
TB_TOP_SOURCE = tb/tb_top.sv
TB_MEMORY_SOURCE = tb/tb_memory_map.sv
SOURCES = $(RTL_SOURCES) $(TB_TOP_SOURCE)

all: build/sim

build/sim: $(SOURCES)
	mkdir -p build
	$(VERILATOR) --binary --top-module tb_top $(COMMON_FLAGS) $(BUILD_FLAGS) $(INCLUDE_DIRS) $^
	mv obj_dir/Vtb_top $@

build/tb_memory_map: $(RTL_SOURCES) $(TB_MEMORY_SOURCE)
	mkdir -p build
	$(VERILATOR) --binary --top-module tb_memory_map $(COMMON_FLAGS) $(BUILD_FLAGS) $(INCLUDE_DIRS) $^
	mv obj_dir/Vtb_memory_map $@

run: build/sim
	./build/sim

run_tb_memory_map: build/tb_memory_map
	./build/tb_memory_map

lint:
	$(VERILATOR) $(LINT_FLAGS) --top-module tb_top $(COMMON_FLAGS) $(INCLUDE_DIRS) $(SOURCES)

clean:
	rm -rf build obj_dir sim.vcd
