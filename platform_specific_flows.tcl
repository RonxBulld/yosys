# Platform-Specific Memory Synthesis Flows
# 针对不同平台的内存综合流程
#
# 使用方法:
# yosys -s platform_specific_flows.tcl -p "PLATFORM=xilinx"
# yosys -s platform_specific_flows.tcl -p "PLATFORM=intel"
# yosys -s platform_specific_flows.tcl -p "PLATFORM=asic"

# =============================================================================
# 通用前端处理 (Common Frontend Processing)
# =============================================================================

proc common_frontend {} {
    # 读取设计文件
    read_verilog generic_memory_template.v
    read_verilog usage_examples.v
    
    # 自动检测顶层
    hierarchy -check -auto-top
    
    # 基本前端优化
    proc
    opt_expr
    opt_clean
    check
    opt -nodffe -nosdff
    fsm
    opt
    
    print "Common frontend processing completed."
}

# =============================================================================
# Xilinx FPGA 综合流程
# =============================================================================

proc xilinx_synthesis {} {
    print "Starting Xilinx FPGA synthesis flow..."
    
    common_frontend
    
    # Xilinx特定的内存处理
    # 保持内存结构以便后续映射到Block RAM
    memory -nomap
    opt_clean
    
    # 位宽缩减和基本优化
    wreduce
    peepopt
    opt_clean
    alumacc
    share
    opt
    
    # 内存映射 - 针对Xilinx优化
    # 先尝试映射到BRAM，失败则映射到分布式RAM或逻辑
    
    # 使用Xilinx综合流程
    synth_xilinx -flatten -nowidelut -nodsp -nocarry -nobram
    
    # 或者手动步骤:
    # opt -fast -full
    # memory_bram -rules +/xilinx/brams.txt
    # techmap -map +/xilinx/arith_map.v
    # memory_map
    # dffsr2dff
    # dff2dffe
    # techmap -map +/xilinx/cells_map.v
    # opt_lut_ins
    # abc -luts 2:2,3,6:5,10,20
    
    # 输出结果
    write_verilog -noattr synthesized_xilinx.v
    write_edif synthesized_xilinx.edf
    
    print "Xilinx synthesis completed."
    print "Output: synthesized_xilinx.v, synthesized_xilinx.edf"
}

# =============================================================================
# Intel/Altera FPGA 综合流程  
# =============================================================================

proc intel_synthesis {} {
    print "Starting Intel FPGA synthesis flow..."
    
    common_frontend
    
    # Intel特定的内存处理
    memory -nomap
    opt_clean
    
    # 基本优化
    wreduce
    peepopt  
    opt_clean
    alumacc
    share
    opt
    
    # 使用Intel综合流程
    synth_intel -family cyclone10lp
    
    # 或者手动步骤:
    # opt -fast -full
    # memory_bram -rules +/intel/common/brams.txt
    # techmap -map +/intel/common/arith_map.v
    # memory_map
    # techmap -map +/intel/common/cells_map.v
    # abc -lut 4
    
    # 输出结果
    write_verilog -noattr synthesized_intel.v
    write_blif synthesized_intel.blif
    
    print "Intel synthesis completed."
    print "Output: synthesized_intel.v, synthesized_intel.blif"
}

# =============================================================================
# ASIC 综合流程
# =============================================================================

proc asic_synthesis {} {
    print "Starting ASIC synthesis flow..."
    
    common_frontend
    
    # ASIC特定处理 - 更激进的优化
    wreduce
    peepopt
    opt_clean
    
    # 内存处理 - 完全映射到逻辑
    # ASIC通常使用编译器内存或将内存映射到标准单元
    memory -nomap
    opt_clean
    
    # 算术优化
    alumacc
    share
    opt
    
    # 细粒度优化
    opt -fast -full
    
    # 内存映射到逻辑 (对于小内存)
    memory_map
    
    # 或者保持内存抽象等待后端工具处理:
    # 这种情况下注释掉memory_map，保持$mem单元
    
    # 技术映射
    techmap
    opt -fast
    
    # ABC优化 (如果有标准单元库)
    # dfflibmap -liberty standard_cells.lib  
    # abc -liberty standard_cells.lib -script "+strash;ifraig;retime,-D,{D};strash;dch,-f;map,-M,1,{D}"
    
    # 简单ABC优化 (无库文件)
    abc -fast
    
    # 最终优化
    opt -fast
    
    # 输出结果
    write_verilog -noattr synthesized_asic.v
    write_json synthesized_asic.json
    
    print "ASIC synthesis completed."
    print "Output: synthesized_asic.v, synthesized_asic.json"
}

# =============================================================================
# 仿真友好的综合流程
# =============================================================================

proc simulation_synthesis {} {
    print "Starting simulation-friendly synthesis flow..."
    
    common_frontend
    
    # 保持内存结构以便仿真
    # 不进行memory_map，保持行为级描述
    memory -nomap
    opt_clean
    
    # 基本优化但保持可读性
    wreduce
    opt_clean
    share
    opt
    
    # 轻度技术映射，保持结构清晰
    techmap -map +/simlib.v
    opt_clean
    
    # 输出仿真友好的网表
    write_verilog -noattr synthesized_sim.v
    
    print "Simulation synthesis completed."
    print "Output: synthesized_sim.v (simulation-friendly)"
}

# =============================================================================
# 内存优化综合流程
# =============================================================================

proc memory_optimized_synthesis {} {
    print "Starting memory-optimized synthesis flow..."
    
    common_frontend
    
    # 内存特定优化
    # 内存端口合并
    memory_share
    
    # 内存窄化 - 将宽端口分解为窄端口
    memory_narrow
    
    # 内存DFF优化 - 将DFF合并到内存端口
    memory_dff
    
    # 内存收集 - 将分散的内存访问合并
    memory_collect
    
    # 保持内存抽象
    memory -nomap
    opt_clean
    
    # 基本优化
    wreduce
    alumacc  
    share
    opt
    
    # 内存到BRAM映射 (需要配置文件)
    # memory_bram -rules memory_rules.txt
    
    # 如果没有BRAM，映射到逻辑
    memory_map
    
    # 最终优化
    techmap
    abc -fast
    opt
    
    # 输出结果
    write_verilog -noattr synthesized_memory_opt.v
    
    print "Memory-optimized synthesis completed."  
    print "Output: synthesized_memory_opt.v"
}

# =============================================================================
# 调试和分析流程
# =============================================================================

proc debug_synthesis {} {
    print "Starting debug synthesis flow..."
    
    common_frontend
    
    # 保持所有中间表示
    memory -nomap
    
    # 生成各个阶段的输出
    write_verilog -noattr debug_stage1_frontend.v
    
    # 内存处理
    memory_share
    memory_collect  
    write_verilog -noattr debug_stage2_memory.v
    
    # 优化
    wreduce
    share
    opt
    write_verilog -noattr debug_stage3_optimized.v
    
    # 映射
    memory_map
    techmap
    write_verilog -noattr debug_stage4_mapped.v
    
    # 最终处理
    abc -fast
    opt
    write_verilog -noattr debug_stage5_final.v
    
    # 生成统计信息
    stat -detailed > synthesis_stats.txt
    
    print "Debug synthesis completed."
    print "Outputs: debug_stage1-5.v, synthesis_stats.txt"
}

# =============================================================================
# 主执行逻辑
# =============================================================================

# 根据平台参数选择执行流程
if {[info exists env(PLATFORM)]} {
    set platform $env(PLATFORM)
} else {
    set platform "generic"
}

switch $platform {
    "xilinx" {
        xilinx_synthesis
    }
    "intel" -
    "altera" {
        intel_synthesis  
    }
    "asic" {
        asic_synthesis
    }
    "simulation" -
    "sim" {
        simulation_synthesis
    }
    "memory" {
        memory_optimized_synthesis
    }
    "debug" {
        debug_synthesis
    }
    default {
        print "Available platforms:"
        print "  xilinx    - Xilinx FPGA synthesis"
        print "  intel     - Intel FPGA synthesis" 
        print "  asic      - ASIC synthesis"
        print "  simulation- Simulation-friendly synthesis"
        print "  memory    - Memory-optimized synthesis"
        print "  debug     - Debug synthesis with intermediate outputs"
        print ""
        print "Usage: yosys -s platform_specific_flows.tcl -p \"PLATFORM=xilinx\""
        print "Or set environment variable: export PLATFORM=xilinx"
        
        # 默认执行通用流程
        print ""
        print "Running generic synthesis flow..."
        common_frontend
        memory -nomap
        opt_clean
        wreduce
        share
        opt
        memory_map
        techmap
        abc -fast
        opt
        write_verilog -noattr synthesized_generic.v
        print "Generic synthesis completed."
        print "Output: synthesized_generic.v"
    }
}

print ""
print "Synthesis flow completed!"
hierarchy -check
stat