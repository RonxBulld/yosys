# Generic Memory Template Synthesis Flow
# 针对通用内存模板的Yosys综合指令流
#
# 使用方法:
# yosys -s memory_synthesis_flow.tcl
# 或者在yosys中执行: script memory_synthesis_flow.tcl

# =============================================================================
# 第一阶段：前端解析和层级处理 (Frontend & Hierarchy)
# =============================================================================

# 读取设计文件
read_verilog generic_memory_template.v
read_verilog usage_examples.v

# 设置顶层模块 (可以根据需要修改)
# hierarchy -check -top single_port_memory_example
hierarchy -check -auto-top

# 显示当前设计状态
stat

# =============================================================================
# 第二阶段：粗粒度优化 (Coarse-Grain Optimization)
# =============================================================================

# 过程块处理：将always块转换为组合逻辑和时序元件
proc

# 表达式优化：简化布尔表达式和算术表达式
opt_expr

# 清理未使用的线网和单元
opt_clean

# 设计规则检查
check

# 基本优化：删除冗余逻辑，不优化DFF使能和同步复位
opt -nodffe -nosdff

# 有限状态机优化 (如果有FSM的话)
fsm

# 层级优化
opt

# 位宽缩减：移除未使用的高位
wreduce

# 窥孔优化：局部模式匹配优化
peepopt

# 再次清理
opt_clean

# 算术单元累积器优化：优化加法器链
alumacc

# 资源共享：识别和共享相同的子电路
share

# 层级优化
opt

# =============================================================================
# 第三阶段：内存处理 (Memory Processing)
# =============================================================================

# 内存相关处理（不进行映射，保持$mem单元）
# -nomap: 不将内存映射到基本单元，保持高级内存抽象
# -nordff: 不将DFF合并到内存读端口
memory -nomap

# 清理优化
opt_clean

# =============================================================================
# 第四阶段：细粒度优化 (Fine-Grain Optimization)
# =============================================================================

# 快速全面优化
opt -fast -full

# 内存映射：将$mem单元转换为基本逻辑单元
# 这一步会将我们的通用内存模板转换为标准的D触发器和多路选择器
memory_map

# 全面优化
opt -full

# 技术映射：将通用单元映射到目标技术库
# 这里使用通用技术映射，可以根据目标平台添加特定映射文件
techmap

# 快速优化
opt -fast

# =============================================================================
# 第五阶段：平台特定映射 (Platform-Specific Mapping)
# =============================================================================

# 根据目标平台选择不同的映射策略

# 选项1：FPGA LUT映射 (使用-lut选项时)
# techmap -map +/gate2lut.v -D LUT_WIDTH=4
# clean
# opt_lut

# 选项2：ABC优化 (通用逻辑优化)
# abc -fast

# 选项3：特定FPGA映射 (例如：Xilinx)
# synth_xilinx -top top_module

# 选项4：ASIC标准单元映射
# dfflibmap -liberty standard_cells.lib
# abc -liberty standard_cells.lib

# =============================================================================
# 第六阶段：内存特定优化 (Memory-Specific Optimizations)
# =============================================================================

# 如果需要将内存重新映射到块RAM，可以使用以下命令：

# 内存块RAM映射 (需要提供RAM配置文件)
# memory_bram -rules rams.txt

# 内存库映射 (使用内存编译器生成的库)
# memory_libmap -lib memory_lib.txt

# =============================================================================
# 第七阶段：后端优化和验证 (Backend Optimization & Verification)
# =============================================================================

# 最终层级检查
hierarchy -check

# 显示综合结果统计
stat

# 最终设计规则检查
check

# =============================================================================
# 输出生成 (Output Generation)
# =============================================================================

# 输出Verilog网表
write_verilog -noattr synthesized_memory.v

# 输出其他格式 (根据需要选择)
# write_blif synthesized_memory.blif
# write_json synthesized_memory.json
# write_ilang synthesized_memory.il

# =============================================================================
# 调试和分析输出 (Debug & Analysis)
# =============================================================================

# 显示设计层级
hierarchy -check

# 显示所有模块
ls

# 显示当前模块的单元
ls -m

# 生成设计统计报告
stat -detailed

# 显示关键路径信息 (如果支持)
# timing

# 输出图形化表示 (可选)
# show -format svg -prefix memory_design

print "Memory synthesis flow completed successfully!"
print "Output files:"
print "- synthesized_memory.v : Synthesized Verilog netlist"
print ""
print "Statistics and verification completed."