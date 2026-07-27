# RISC-V project Makefile (Verilator + assembler)
# Default target: build/sim (RTL simulator only)
# To generate instruction memory: make data (or make asm)

AS       = riscv64-elf-as
LD       = riscv64-elf-ld
OBJDUMP  = riscv64-elf-objdump
ARCH     = rv32im
ASM_SOURCE ?= data/instr_file.s 
ASM_BASENAME = $(basename $(ASM_SOURCE))
ASM_OBJECT   = $(ASM_BASENAME).o
ASM_ELF      = $(ASM_BASENAME).elf
ASM_MEM      = data/instr_file.mem  

ASFLAGS  = -march=$(ARCH)
LDFLAGS  = -m elf32lriscv -Ttext=0x0
OBJDUMPFLAGS = -d

VERILATOR = verilator
COMMON_FLAGS = -Wall -Wno-fatal
BUILD_FLAGS  = --build -j 0 --trace
LINT_FLAGS   = --lint-only

INCLUDE_DIRS = -Iheaders -Isrc/core -Isrc/fetch -Isrc/decode -Isrc/execute -Isrc/memory -Isrc/writeback

RTL_SOURCES = $(shell find src -name "*.sv")
TB_TOP_SOURCE = tb/tb_top.sv
TB_MEMORY_SOURCE = tb/tb_memory_map.sv
SOURCES = $(RTL_SOURCES) $(TB_TOP_SOURCE)

.PHONY: data asm run run_tb_memory_map lint clean clean_all

# Default target: build RTL simulator only
build/sim: $(SOURCES)
	mkdir -p build
	$(VERILATOR) --binary --top-module tb_top $(COMMON_FLAGS) $(BUILD_FLAGS) $(INCLUDE_DIRS) $^
	mv obj_dir/Vtb_top $@

build/tb_memory_map: $(RTL_SOURCES) $(TB_MEMORY_SOURCE)
	mkdir -p build
	$(VERILATOR) --binary --top-module tb_memory_map $(COMMON_FLAGS) $(BUILD_FLAGS) $(INCLUDE_DIRS) $^
	mv obj_dir/Vtb_memory_map $@

# Generate instruction memory file (separate target)
data: $(ASM_MEM)
asm: data

$(ASM_MEM): $(ASM_SOURCE)
	mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $< -o $(ASM_OBJECT)
	$(LD) $(LDFLAGS) $(ASM_OBJECT) -o $(ASM_ELF)
	$(OBJDUMP) $(OBJDUMPFLAGS) $(ASM_ELF) | \
		awk '/^[[:space:]]*[0-9a-f]+:/ {print $$2}' | \
		grep -v '^$$' > $@

run: build/sim
	./build/sim

run_tb_memory_map: build/tb_memory_map
	./build/tb_memory_map

lint:
	$(VERILATOR) $(LINT_FLAGS) --top-module tb_top $(COMMON_FLAGS) $(INCLUDE_DIRS) $(SOURCES)

clean:
	rm -rf build obj_dir sim.vcd
	rm -f $(ASM_OBJECT) $(ASM_ELF)

clean_all: clean
	rm -f $(ASM_MEM)
