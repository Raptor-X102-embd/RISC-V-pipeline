# RISC-V project Makefile (Verilator + assembler)
# Uses macros (-D) for reliable parameter override.
# Each test gets its own VCD file.

AS       = riscv64-elf-as
LD       = riscv64-elf-ld
OBJDUMP  = riscv64-elf-objdump
ARCH     = rv32im

VERILATOR = verilator
COMMON_FLAGS = -Wall -Wno-fatal
BUILD_FLAGS  = --build -j 0 --trace
LINT_FLAGS   = --lint-only

INCLUDE_DIRS = -Iheaders -Isrc/core -Isrc/fetch -Isrc/decode -Isrc/execute -Isrc/memory -Isrc/writeback

RTL_SOURCES = $(shell find src -name "*.sv")
TB_TOP_SOURCE = tb/tb_top.sv
SOURCES = $(RTL_SOURCES) $(TB_TOP_SOURCE)

# Default test (manual) - uses data/instr_file.s and data/instr_file.mem
DEFAULT_ASM_SOURCE = data/instr_file.s
DEFAULT_MEM = data/instr_file.mem
DEFAULT_ELF = data/instr_file.elf
DEFAULT_OBJ = data/instr_file.o

# List of tests (explicit)
TESTS_DIR = tests
TESTS = branch_tests jal_tests load_store_tests   # <-- добавлен новый тест

# Template for each test
define TEST_template
TEST_SRC_$(1) = $(TESTS_DIR)/$(1)/instr_file.s
TEST_MEM_$(1) = $(TESTS_DIR)/$(1)/instr_file.mem
TEST_ELF_$(1) = $(TESTS_DIR)/$(1)/instr_file.elf
TEST_OBJ_$(1) = $(TESTS_DIR)/$(1)/instr_file.o
TEST_EXPECT_$(1) = $(wildcard $(TESTS_DIR)/$(1)/expect.txt)

data-$(1): $$(TEST_MEM_$(1))

$$(TEST_MEM_$(1)): $$(TEST_SRC_$(1))
	mkdir -p $$(dir $$@)
	$$(AS) -march=$(ARCH) $$< -o $$(TEST_OBJ_$(1))
	$$(LD) -m elf32lriscv -Ttext=0x0 $$(TEST_OBJ_$(1)) -o $$(TEST_ELF_$(1))
	$$(OBJDUMP) -d $$(TEST_ELF_$(1)) | \
		awk '/^[[:space:]]*[0-9a-f]+:/ {print $$$$2}' | \
		grep -v '^$$$$' > $$@

sim-$(1): $$(SOURCES) $$(TEST_MEM_$(1))
	mkdir -p build
ifneq ($$(TEST_EXPECT_$(1)),)
	$$(VERILATOR) --binary --top-module tb_top $$(COMMON_FLAGS) $$(BUILD_FLAGS) $$(INCLUDE_DIRS) \
		-DINIT_DATA_FILE=\"$$(TEST_MEM_$(1))\" \
		-DEXPECT_FILE=\"$$(TEST_EXPECT_$(1))\" \
		-DVCD_FILE=\"sim_$(1).vcd\" \
		$$(SOURCES)
else
	$$(VERILATOR) --binary --top-module tb_top $$(COMMON_FLAGS) $$(BUILD_FLAGS) $$(INCLUDE_DIRS) \
		-DINIT_DATA_FILE=\"$$(TEST_MEM_$(1))\" \
		-DVCD_FILE=\"sim_$(1).vcd\" \
		$$(SOURCES)
endif
	mv obj_dir/Vtb_top build/sim_$(1)

run-$(1): sim-$(1)
	./build/sim_$(1)

disasm-$(1): $$(TEST_ELF_$(1))
	$$(OBJDUMP) -d $$<

clean-$(1):
	rm -f $$(TEST_OBJ_$(1)) $$(TEST_ELF_$(1)) $$(TEST_MEM_$(1))
endef

$(foreach test,$(TESTS),$(eval $(call TEST_template,$(test))))

# Targets for running all tests
.PHONY: test-all
test-all: $(addprefix run-,$(TESTS))

# Default targets (manual test with data/)
.PHONY: all data disasm view-mem run lint clean clean_all

all: build/sim

build/sim: $(SOURCES) $(DEFAULT_MEM)
	mkdir -p build
	$(VERILATOR) --binary --top-module tb_top $(COMMON_FLAGS) $(BUILD_FLAGS) $(INCLUDE_DIRS) \
		-DINIT_DATA_FILE=\"$(DEFAULT_MEM)\" \
		-DVCD_FILE=\"sim.vcd\" \
		$(SOURCES)
	mv obj_dir/Vtb_top $@

data: $(DEFAULT_MEM)

$(DEFAULT_MEM): $(DEFAULT_ASM_SOURCE)
	mkdir -p data
	$(AS) -march=$(ARCH) $< -o $(DEFAULT_OBJ)
	$(LD) -m elf32lriscv -Ttext=0x0 $(DEFAULT_OBJ) -o $(DEFAULT_ELF)
	$(OBJDUMP) -d $(DEFAULT_ELF) | \
		awk '/^[[:space:]]*[0-9a-f]+:/ {print $$2}' | \
		grep -v '^$$' > $@

disasm:
	$(OBJDUMP) -d $(DEFAULT_ELF)

view-mem: $(DEFAULT_MEM)
	cat $<

run: build/sim
	./build/sim

lint:
	$(VERILATOR) $(LINT_FLAGS) --top-module tb_top $(COMMON_FLAGS) $(INCLUDE_DIRS) $(SOURCES)

clean:
	rm -rf build obj_dir
	rm -f sim.vcd sim_*.vcd
	rm -f $(DEFAULT_OBJ) $(DEFAULT_ELF)

clean_all: clean
	rm -f $(DEFAULT_MEM)
	rm -f $(foreach test,$(TESTS),$(TESTS_DIR)/$(test)/instr_file.o $(TESTS_DIR)/$(test)/instr_file.elf $(TESTS_DIR)/$(test)/instr_file.mem)

.PHONY: $(addprefix data-,$(TESTS)) $(addprefix sim-,$(TESTS)) $(addprefix run-,$(TESTS)) $(addprefix disasm-,$(TESTS)) $(addprefix clean-,$(TESTS))
