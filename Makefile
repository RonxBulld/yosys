# Generic Memory Template Synthesis Makefile
# 通用内存模板综合自动化Makefile

# 默认目标平台
PLATFORM ?= generic

# 工具和路径配置
YOSYS = yosys
PYTHON = python3

# 源文件
VERILOG_SOURCES = generic_memory_template.v usage_examples.v
SYNTHESIS_SCRIPTS = memory_synthesis_flow.tcl platform_specific_flows.tcl
CONFIG_GENERATOR = memory_config_generator.py

# 输出目录
OUTPUT_DIR = synthesis_output
LOG_DIR = logs

# 创建输出目录
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(LOG_DIR):
	mkdir -p $(LOG_DIR)

# 默认目标
.PHONY: all
all: help

# 帮助信息
.PHONY: help
help:
	@echo "Generic Memory Template Synthesis Makefile"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  help              - Show this help message"
	@echo "  check-syntax      - Check Verilog syntax"
	@echo "  generate-config   - Generate memory configurations"
	@echo "  synth-generic     - Run generic synthesis flow"
	@echo "  synth-xilinx      - Run Xilinx FPGA synthesis"
	@echo "  synth-intel       - Run Intel FPGA synthesis"
	@echo "  synth-asic        - Run ASIC synthesis"
	@echo "  synth-memory      - Run memory-optimized synthesis"
	@echo "  synth-debug       - Run debug synthesis with stages"
	@echo "  synth-all         - Run all synthesis flows"
	@echo "  clean             - Clean output files"
	@echo "  clean-all         - Clean all generated files"
	@echo ""
	@echo "Variables:"
	@echo "  PLATFORM=<name>   - Target platform (generic,xilinx,intel,asic,memory,debug)"
	@echo "  VERBOSE=1         - Enable verbose output"
	@echo ""
	@echo "Examples:"
	@echo "  make synth-xilinx"
	@echo "  make synth-asic VERBOSE=1"
	@echo "  make generate-config"

# 语法检查
.PHONY: check-syntax
check-syntax: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Checking Verilog syntax..."
	$(YOSYS) -p "read_verilog $(VERILOG_SOURCES); hierarchy -check -auto-top; check" \
		> $(LOG_DIR)/syntax_check.log 2>&1
	@echo "Syntax check completed. See $(LOG_DIR)/syntax_check.log"

# 生成内存配置
.PHONY: generate-config
generate-config: $(OUTPUT_DIR)
	@echo "Generating memory configurations..."
	$(PYTHON) $(CONFIG_GENERATOR) --preset single_port --full_module \
		--output $(OUTPUT_DIR)/single_port_memory.v
	$(PYTHON) $(CONFIG_GENERATOR) --preset dual_port --full_module \
		--output $(OUTPUT_DIR)/dual_port_memory.v
	$(PYTHON) $(CONFIG_GENERATOR) --preset register_file --full_module \
		--output $(OUTPUT_DIR)/register_file_memory.v
	$(PYTHON) $(CONFIG_GENERATOR) --preset cache_line --full_module \
		--output $(OUTPUT_DIR)/cache_line_memory.v
	@echo "Memory configurations generated in $(OUTPUT_DIR)/"

# 通用综合流程
.PHONY: synth-generic
synth-generic: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running generic synthesis flow..."
	cd $(OUTPUT_DIR) && $(YOSYS) -s ../memory_synthesis_flow.tcl \
		> ../$(LOG_DIR)/synth_generic.log 2>&1
	@echo "Generic synthesis completed. Output: $(OUTPUT_DIR)/synthesized_memory.v"

# Xilinx FPGA综合
.PHONY: synth-xilinx
synth-xilinx: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running Xilinx FPGA synthesis flow..."
	cd $(OUTPUT_DIR) && PLATFORM=xilinx $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_xilinx.log 2>&1
	@echo "Xilinx synthesis completed. Output: $(OUTPUT_DIR)/synthesized_xilinx.v"

# Intel FPGA综合
.PHONY: synth-intel
synth-intel: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running Intel FPGA synthesis flow..."
	cd $(OUTPUT_DIR) && PLATFORM=intel $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_intel.log 2>&1
	@echo "Intel synthesis completed. Output: $(OUTPUT_DIR)/synthesized_intel.v"

# ASIC综合
.PHONY: synth-asic
synth-asic: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running ASIC synthesis flow..."
	cd $(OUTPUT_DIR) && PLATFORM=asic $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_asic.log 2>&1
	@echo "ASIC synthesis completed. Output: $(OUTPUT_DIR)/synthesized_asic.v"

# 内存优化综合
.PHONY: synth-memory
synth-memory: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running memory-optimized synthesis flow..."
	cd $(OUTPUT_DIR) && PLATFORM=memory $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_memory.log 2>&1
	@echo "Memory-optimized synthesis completed. Output: $(OUTPUT_DIR)/synthesized_memory_opt.v"

# 调试综合
.PHONY: synth-debug
synth-debug: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running debug synthesis flow..."
	cd $(OUTPUT_DIR) && PLATFORM=debug $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_debug.log 2>&1
	@echo "Debug synthesis completed. See $(OUTPUT_DIR)/debug_stage*.v files"

# 仿真友好综合
.PHONY: synth-sim
synth-sim: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running simulation-friendly synthesis flow..."
	cd $(OUTPUT_DIR) && PLATFORM=simulation $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_sim.log 2>&1
	@echo "Simulation synthesis completed. Output: $(OUTPUT_DIR)/synthesized_sim.v"

# 运行所有综合流程
.PHONY: synth-all
synth-all: synth-generic synth-xilinx synth-intel synth-asic synth-memory synth-debug synth-sim
	@echo "All synthesis flows completed!"
	@echo "Results summary:"
	@echo "  Generic:     $(OUTPUT_DIR)/synthesized_generic.v"
	@echo "  Xilinx:      $(OUTPUT_DIR)/synthesized_xilinx.v"
	@echo "  Intel:       $(OUTPUT_DIR)/synthesized_intel.v"
	@echo "  ASIC:        $(OUTPUT_DIR)/synthesized_asic.v"
	@echo "  Memory-opt:  $(OUTPUT_DIR)/synthesized_memory_opt.v"
	@echo "  Simulation:  $(OUTPUT_DIR)/synthesized_sim.v"
	@echo "  Debug:       $(OUTPUT_DIR)/debug_stage*.v"

# 自定义综合（使用环境变量）
.PHONY: synth-custom
synth-custom: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Running custom synthesis flow for platform: $(PLATFORM)"
	cd $(OUTPUT_DIR) && PLATFORM=$(PLATFORM) $(YOSYS) -s ../platform_specific_flows.tcl \
		> ../$(LOG_DIR)/synth_$(PLATFORM).log 2>&1
	@echo "Custom synthesis completed for $(PLATFORM)"

# 统计和分析
.PHONY: analyze
analyze: $(OUTPUT_DIR) $(LOG_DIR)
	@echo "Analyzing synthesis results..."
	@if [ -f $(OUTPUT_DIR)/synthesized_generic.v ]; then \
		echo "=== Generic Synthesis Statistics ===" > $(OUTPUT_DIR)/analysis.txt; \
		grep -E "(Number of|cells:|wires:|bits:|modules:)" $(LOG_DIR)/synth_generic.log >> $(OUTPUT_DIR)/analysis.txt; \
	fi
	@if [ -f $(OUTPUT_DIR)/synthesized_xilinx.v ]; then \
		echo "=== Xilinx Synthesis Statistics ===" >> $(OUTPUT_DIR)/analysis.txt; \
		grep -E "(Number of|cells:|wires:|bits:|modules:)" $(LOG_DIR)/synth_xilinx.log >> $(OUTPUT_DIR)/analysis.txt; \
	fi
	@echo "Analysis completed. See $(OUTPUT_DIR)/analysis.txt"

# 测试配置生成器
.PHONY: test-generator
test-generator:
	@echo "Testing memory configuration generator..."
	$(PYTHON) $(CONFIG_GENERATOR) --list
	@echo ""
	@echo "Generating test configurations..."
	$(PYTHON) $(CONFIG_GENERATOR) --preset dual_port
	@echo ""
	$(PYTHON) $(CONFIG_GENERATOR) --custom --rd_ports 4 --wr_ports 2 --size 1024 --width 32

# 运行仿真（如果有仿真器）
.PHONY: simulate
simulate: synth-sim
	@echo "Running simulation (if simulator available)..."
	@if command -v iverilog >/dev/null 2>&1; then \
		echo "Using Icarus Verilog..."; \
		iverilog -o $(OUTPUT_DIR)/sim_test $(OUTPUT_DIR)/synthesized_sim.v; \
		vvp $(OUTPUT_DIR)/sim_test; \
	else \
		echo "No Verilog simulator found. Please install iverilog or other simulator."; \
	fi

# 清理输出文件
.PHONY: clean
clean:
	@echo "Cleaning output files..."
	rm -rf $(OUTPUT_DIR)
	rm -rf $(LOG_DIR)

# 清理所有生成文件
.PHONY: clean-all
clean-all: clean
	@echo "Cleaning all generated files..."
	rm -f *.v.bak *.log *.tmp
	rm -f synthesis_stats.txt

# 检查依赖项
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@echo -n "Yosys: "
	@if command -v $(YOSYS) >/dev/null 2>&1; then \
		$(YOSYS) -V | head -1; \
	else \
		echo "NOT FOUND - Please install Yosys"; \
	fi
	@echo -n "Python3: "
	@if command -v $(PYTHON) >/dev/null 2>&1; then \
		$(PYTHON) --version; \
	else \
		echo "NOT FOUND - Please install Python3"; \
	fi

# 安装钩子
.PHONY: install-hooks
install-hooks:
	@echo "Installing git hooks..."
	@if [ -d .git ]; then \
		cp hooks/pre-commit .git/hooks/; \
		chmod +x .git/hooks/pre-commit; \
		echo "Git hooks installed."; \
	else \
		echo "Not a git repository."; \
	fi

# 文档生成
.PHONY: docs
docs:
	@echo "Generating documentation..."
	@echo "# Synthesis Results" > $(OUTPUT_DIR)/README.md
	@echo "" >> $(OUTPUT_DIR)/README.md
	@echo "This directory contains synthesis results for the generic memory template." >> $(OUTPUT_DIR)/README.md
	@echo "" >> $(OUTPUT_DIR)/README.md
	@echo "## Files:" >> $(OUTPUT_DIR)/README.md
	@echo "" >> $(OUTPUT_DIR)/README.md
	@ls -la $(OUTPUT_DIR)/*.v 2>/dev/null | awk '{printf "- %s: %s bytes\n", $$9, $$5}' >> $(OUTPUT_DIR)/README.md 2>/dev/null || true

# 打包结果
.PHONY: package
package: synth-all docs
	@echo "Packaging synthesis results..."
	tar -czf memory_synthesis_$(shell date +%Y%m%d_%H%M%S).tar.gz \
		$(OUTPUT_DIR)/ $(LOG_DIR)/ $(VERILOG_SOURCES) $(SYNTHESIS_SCRIPTS) \
		$(CONFIG_GENERATOR) Makefile README.md
	@echo "Package created: memory_synthesis_$(shell date +%Y%m%d_%H%M%S).tar.gz"

# 显示状态
.PHONY: status
status:
	@echo "Synthesis Status:"
	@echo "================"
	@echo "Source files:"
	@ls -la $(VERILOG_SOURCES) 2>/dev/null || echo "  Source files not found"
	@echo ""
	@echo "Output directory:"
	@if [ -d $(OUTPUT_DIR) ]; then \
		echo "  $(OUTPUT_DIR)/ exists ($(shell ls $(OUTPUT_DIR) | wc -l) files)"; \
		ls -la $(OUTPUT_DIR)/; \
	else \
		echo "  $(OUTPUT_DIR)/ does not exist"; \
	fi
	@echo ""
	@echo "Log directory:"
	@if [ -d $(LOG_DIR) ]; then \
		echo "  $(LOG_DIR)/ exists ($(shell ls $(LOG_DIR) | wc -l) files)"; \
		ls -la $(LOG_DIR)/; \
	else \
		echo "  $(LOG_DIR)/ does not exist"; \
	fi

# 交互式菜单
.PHONY: menu
menu:
	@echo "Generic Memory Template Synthesis Menu"
	@echo "======================================"
	@echo "1) Check syntax"
	@echo "2) Generate configurations"
	@echo "3) Run generic synthesis"
	@echo "4) Run Xilinx synthesis"
	@echo "5) Run Intel synthesis"
	@echo "6) Run ASIC synthesis"
	@echo "7) Run all synthesis flows"
	@echo "8) Analyze results"
	@echo "9) Clean outputs"
	@echo "0) Exit"
	@echo ""
	@read -p "Select option [0-9]: " choice; \
	case $$choice in \
		1) make check-syntax ;; \
		2) make generate-config ;; \
		3) make synth-generic ;; \
		4) make synth-xilinx ;; \
		5) make synth-intel ;; \
		6) make synth-asic ;; \
		7) make synth-all ;; \
		8) make analyze ;; \
		9) make clean ;; \
		0) echo "Goodbye!" ;; \
		*) echo "Invalid option" ;; \
	esac

.PHONY: phony
phony: help check-syntax generate-config synth-generic synth-xilinx synth-intel synth-asic \
       synth-memory synth-debug synth-sim synth-all synth-custom analyze test-generator \
       simulate clean clean-all check-deps install-hooks docs package status menu
