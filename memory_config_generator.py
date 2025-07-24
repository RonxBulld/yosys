#!/usr/bin/env python3
"""
Generic Memory Configuration Generator

This script generates Verilog instantiations of the generic_memory module
with various port configurations for different memory types.

Usage:
    python memory_config_generator.py --help
    python memory_config_generator.py --preset single_port
    python memory_config_generator.py --custom --rd_ports 4 --wr_ports 2 --size 2048 --width 64
"""

import argparse
import math
import sys

class MemoryConfigGenerator:
    def __init__(self):
        self.presets = {
            'single_port': {
                'rd_ports': 1, 'wr_ports': 1, 'size': 1024, 'width': 32,
                'description': '单端口内存 (1R1W)'
            },
            'dual_port': {
                'rd_ports': 2, 'wr_ports': 2, 'size': 1024, 'width': 32,
                'description': '双端口内存 (2R2W)'
            },
            'quad_read': {
                'rd_ports': 4, 'wr_ports': 1, 'size': 2048, 'width': 64,
                'description': '四读单写内存 (4R1W)'
            },
            'register_file': {
                'rd_ports': 8, 'wr_ports': 4, 'size': 32, 'width': 32,
                'description': '寄存器文件 (8R4W)'
            },
            'cache_line': {
                'rd_ports': 2, 'wr_ports': 1, 'size': 64, 'width': 512,
                'description': '缓存行存储 (2R1W, 512-bit width)'
            },
            'fifo_buffer': {
                'rd_ports': 1, 'wr_ports': 1, 'size': 256, 'width': 64,
                'transparency': [1], 'description': 'FIFO缓冲区 (1R1W, 透明读)'
            }
        }
    
    def calculate_abits(self, size):
        """计算地址位宽"""
        return max(1, math.ceil(math.log2(size)))
    
    def generate_verilog_instance(self, config):
        """生成Verilog实例化代码"""
        rd_ports = config['rd_ports']
        wr_ports = config['wr_ports']
        size = config['size']
        width = config['width']
        abits = self.calculate_abits(size)
        
        # 生成参数
        params = []
        params.append(f"    .MEMID(\"{config.get('memid', 'mem_inst')}\")")
        params.append(f"    .SIZE({size})")
        params.append(f"    .ABITS({abits})")
        params.append(f"    .WIDTH({width})")
        params.append(f"    .RD_PORTS({rd_ports})")
        params.append(f"    .WR_PORTS({wr_ports})")
        
        # 可选参数
        if 'init' in config:
            params.append(f"    .INIT({config['init']})")
        if 'offset' in config:
            params.append(f"    .OFFSET({config['offset']})")
            
        # 读端口配置
        if 'transparency' in config:
            trans_val = self.generate_bit_vector(config['transparency'], rd_ports)
            params.append(f"    .RD_TRANSPARENCY({trans_val})")
        
        if 'rd_clk_enable' in config:
            clk_en_val = self.generate_bit_vector(config['rd_clk_enable'], rd_ports)
            params.append(f"    .RD_CLK_ENABLE({clk_en_val})")
            
        if 'rd_clk_polarity' in config:
            clk_pol_val = self.generate_bit_vector(config['rd_clk_polarity'], rd_ports)
            params.append(f"    .RD_CLK_POLARITY({clk_pol_val})")
        
        # 写端口配置
        if 'wr_clk_enable' in config:
            wr_clk_en_val = self.generate_bit_vector(config['wr_clk_enable'], wr_ports)
            params.append(f"    .WR_CLK_ENABLE({wr_clk_en_val})")
            
        if 'wr_clk_polarity' in config:
            wr_clk_pol_val = self.generate_bit_vector(config['wr_clk_polarity'], wr_ports)
            params.append(f"    .WR_CLK_POLARITY({wr_clk_pol_val})")
        
        # 高级选项
        if 'option_mode' in config:
            params.append(f"    .OPTION_MODE(\"{config['option_mode']}\")")
        if 'option_reset' in config:
            params.append(f"    .OPTION_RESET(\"{config['option_reset']}\")")
        if 'option_wr_mode' in config:
            params.append(f"    .OPTION_WR_MODE(\"{config['option_wr_mode']}\")")
        
        # 生成端口连接
        ports = []
        
        # 读端口
        if rd_ports == 1:
            ports.extend([
                "    .RD_CLK(rd_clk)",
                "    .RD_EN(rd_en)",
                "    .RD_ARST(rd_arst)",
                "    .RD_SRST(rd_srst)",
                f"    .RD_ADDR(rd_addr)",        # [{abits-1}:0]
                f"    .RD_DATA(rd_data)"         # [{width-1}:0]
            ])
        else:
            ports.extend([
                f"    .RD_CLK(rd_clk)",          # [{rd_ports-1}:0]
                f"    .RD_EN(rd_en)",            # [{rd_ports-1}:0]
                f"    .RD_ARST(rd_arst)",        # [{rd_ports-1}:0]
                f"    .RD_SRST(rd_srst)",        # [{rd_ports-1}:0]
                f"    .RD_ADDR(rd_addr)",        # [{rd_ports*abits-1}:0]
                f"    .RD_DATA(rd_data)"         # [{rd_ports*width-1}:0]
            ])
        
        # 写端口
        if wr_ports == 1:
            ports.extend([
                "    .WR_CLK(wr_clk)",
                "    .WR_EN(wr_en)",
                f"    .WR_BE(wr_be)",            # [{width-1}:0]
                f"    .WR_ADDR(wr_addr)",        # [{abits-1}:0]
                f"    .WR_DATA(wr_data)"         # [{width-1}:0]
            ])
        else:
            ports.extend([
                f"    .WR_CLK(wr_clk)",          # [{wr_ports-1}:0]
                f"    .WR_EN(wr_en)",            # [{wr_ports-1}:0]
                f"    .WR_BE(wr_be)",            # [{wr_ports*width-1}:0]
                f"    .WR_ADDR(wr_addr)",        # [{wr_ports*abits-1}:0]
                f"    .WR_DATA(wr_data)"         # [{wr_ports*width-1}:0]
            ])
        
        # 组装完整的实例化代码
        instance_name = config.get('instance_name', 'memory_inst')
        result = f"// {config.get('description', '通用内存实例')}\n"
        result += f"generic_memory #(\n"
        result += ",\n".join(params) + "\n"
        result += f") {instance_name} (\n"
        result += ",\n".join(ports) + "\n"
        result += ");\n"
        
        return result
    
    def generate_bit_vector(self, values, port_count):
        """生成位向量参数"""
        if isinstance(values, list):
            if len(values) != port_count:
                raise ValueError(f"值列表长度 {len(values)} 与端口数量 {port_count} 不匹配")
            # 转换为位向量字符串
            bit_str = ''.join(['1' if v else '0' for v in reversed(values)])
            return f"{port_count}'b{bit_str}"
        else:
            # 统一值
            return f"{port_count}'b" + str(values) * port_count
    
    def generate_signal_declarations(self, config):
        """生成信号声明"""
        rd_ports = config['rd_ports']
        wr_ports = config['wr_ports']
        size = config['size']
        width = config['width']
        abits = self.calculate_abits(size)
        
        signals = []
        signals.append("// 时钟和复位信号")
        
        # 读端口信号
        if rd_ports == 1:
            signals.extend([
                "input  wire rd_clk;",
                "input  wire rd_en;",
                "input  wire rd_arst;",
                "input  wire rd_srst;",
                f"input  wire [{abits-1}:0] rd_addr;",
                f"output wire [{width-1}:0] rd_data;"
            ])
        else:
            signals.extend([
                f"input  wire [{rd_ports-1}:0] rd_clk;",
                f"input  wire [{rd_ports-1}:0] rd_en;",
                f"input  wire [{rd_ports-1}:0] rd_arst;",
                f"input  wire [{rd_ports-1}:0] rd_srst;",
                f"input  wire [{rd_ports*abits-1}:0] rd_addr;",
                f"output wire [{rd_ports*width-1}:0] rd_data;"
            ])
        
        signals.append("")
        
        # 写端口信号
        if wr_ports == 1:
            signals.extend([
                "input  wire wr_clk;",
                "input  wire wr_en;",
                f"input  wire [{width-1}:0] wr_be;",
                f"input  wire [{abits-1}:0] wr_addr;",
                f"input  wire [{width-1}:0] wr_data;"
            ])
        else:
            signals.extend([
                f"input  wire [{wr_ports-1}:0] wr_clk;",
                f"input  wire [{wr_ports-1}:0] wr_en;",
                f"input  wire [{wr_ports*width-1}:0] wr_be;",
                f"input  wire [{wr_ports*abits-1}:0] wr_addr;",
                f"input  wire [{wr_ports*width-1}:0] wr_data;"
            ])
        
        return "\n".join(signals)
    
    def generate_full_module(self, config):
        """生成完整的模块包装器"""
        module_name = config.get('module_name', 'memory_wrapper')
        signals = self.generate_signal_declarations(config)
        instance = self.generate_verilog_instance(config)
        
        result = f"""// 自动生成的内存模块包装器
// 配置: {config.get('description', 'N/A')}
// 读端口: {config['rd_ports']}, 写端口: {config['wr_ports']}
// 大小: {config['size']} words x {config['width']} bits

module {module_name} (
{self.indent_text(signals, 4)}
);

{self.indent_text(instance, 0)}

endmodule
"""
        return result
    
    def indent_text(self, text, spaces):
        """缩进文本"""
        lines = text.split('\n')
        indent = ' ' * spaces
        return '\n'.join(indent + line if line.strip() else line for line in lines)
    
    def list_presets(self):
        """列出所有预设配置"""
        print("可用的预设配置:")
        print("-" * 50)
        for name, config in self.presets.items():
            print(f"{name:15} - {config['description']}")
            print(f"               读端口: {config['rd_ports']}, 写端口: {config['wr_ports']}")
            print(f"               大小: {config['size']} x {config['width']} bits")
            print()

def main():
    parser = argparse.ArgumentParser(description='生成通用内存配置')
    
    # 预设或自定义选择
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument('--preset', choices=['single_port', 'dual_port', 'quad_read', 
                                                'register_file', 'cache_line', 'fifo_buffer'],
                           help='使用预设配置')
    mode_group.add_argument('--custom', action='store_true', help='使用自定义配置')
    mode_group.add_argument('--list', action='store_true', help='列出所有预设配置')
    
    # 自定义配置参数
    parser.add_argument('--rd_ports', type=int, default=1, help='读端口数量')
    parser.add_argument('--wr_ports', type=int, default=1, help='写端口数量') 
    parser.add_argument('--size', type=int, default=1024, help='内存深度')
    parser.add_argument('--width', type=int, default=32, help='数据位宽')
    parser.add_argument('--memid', type=str, default='generic_mem', help='内存ID')
    parser.add_argument('--instance_name', type=str, default='memory_inst', help='实例名称')
    parser.add_argument('--module_name', type=str, help='模块名称（生成完整模块时）')
    
    # 输出选项
    parser.add_argument('--output', '-o', type=str, help='输出文件名')
    parser.add_argument('--full_module', action='store_true', help='生成完整模块而非仅实例化')
    parser.add_argument('--signals_only', action='store_true', help='仅生成信号声明')
    
    args = parser.parse_args()
    
    generator = MemoryConfigGenerator()
    
    if args.list:
        generator.list_presets()
        return
    
    # 确定配置
    if args.preset:
        config = generator.presets[args.preset].copy()
        config['instance_name'] = args.instance_name
        config['memid'] = args.memid
        if args.module_name:
            config['module_name'] = args.module_name
    else:
        config = {
            'rd_ports': args.rd_ports,
            'wr_ports': args.wr_ports,
            'size': args.size,
            'width': args.width,
            'memid': args.memid,
            'instance_name': args.instance_name,
            'description': f'自定义内存 ({args.rd_ports}R{args.wr_ports}W)'
        }
        if args.module_name:
            config['module_name'] = args.module_name
    
    # 生成输出
    try:
        if args.signals_only:
            output = generator.generate_signal_declarations(config)
        elif args.full_module:
            output = generator.generate_full_module(config)
        else:
            output = generator.generate_verilog_instance(config)
        
        # 输出到文件或标准输出
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output)
            print(f"已生成配置文件: {args.output}")
        else:
            print(output)
            
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()