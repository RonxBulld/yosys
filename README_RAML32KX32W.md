# RAML32KX32W 内存器件库使用指南

## 概述
本库提供了将 Yosys 中的 `$memwr_v2` 实例映射到 RAML32KX32W 内存器件的完整解决方案。RAML32KX32W 是一个 32K×32 位的内存器件，具有上升沿敏感的读端口。

## 文件说明

### 1. 器件库文件
- **raml32kx32w_lib.txt**: memlib 格式的器件库描述文件
  - 定义了 RAML32KX32W 的参数：15 位地址，32 位数据宽度
  - 配置为 block 类型内存，支持初始化和同步复位
  - 仅包含同步读端口（上升沿敏感）

### 2. 技术映射文件
- **raml32kx32w_map.v**: Verilog 技术映射文件
  - 将中间表示 `$__RAML32KX32W_` 映射到实际硬件原语 `RAML32KX32W`
  - 处理信号连接和参数传递

### 3. 综合脚本
- **complete_synth.ys**: 完整的综合脚本
  - 包含完整的内存映射流程
  - 支持详细日志输出用于调试
- **synth_raml32kx32w.ys**: 简化版综合脚本

### 4. 示例文件
- **example_design.v**: 示例设计，展示内存使用模式

## 使用步骤

### 1. 准备你的设计文件
确保你的 Verilog 设计包含适合映射到 RAML32KX32W 的内存结构：
- 32K 字（或更小）
- 32 位数据宽度（或更小）
- 主要是读操作的内存

### 2. 运行综合
```bash
# 使用完整脚本（推荐）
yosys complete_synth.ys

# 或使用简化脚本
yosys synth_raml32kx32w.ys
```

### 3. 检查结果
检查生成的 `mapped_design.v` 文件，确认内存是否正确映射到 RAML32KX32W 实例。

## RAML32KX32W 器件接口

映射后的 RAML32KX32W 器件具有以下接口：

```verilog
RAML32KX32W #(
    .INIT(init_value),          // 初始化值
    .INIT_VALUE(init_value),    // 读端口初始值  
    .RESET_VALUE(reset_value)   // 复位值
) instance_name (
    .CLK(clk),                  // 时钟信号（上升沿敏感）
    .EN(enable),                // 读使能信号
    .ADDR(address[14:0]),       // 15位地址信号
    .DOUT(data_out[31:0]),      // 32位数据输出
    .SRST(sync_reset)           // 同步复位信号
);
```

## 配置选项

### 器件库配置
在 `raml32kx32w_lib.txt` 中可以调整：
- `cost`: 选择启发式的成本值
- `init`: 初始化支持类型（any/zero/none/no_undef）
- 端口配置：时钟极性、使能信号等

### 技术映射配置
在 `raml32kx32w_map.v` 中可以调整：
- 参数映射
- 信号连接方式
- 实际硬件原语的接口

## 故障排除

### 1. 内存未被映射
- 检查内存大小是否超过 32K×32 限制
- 确认内存访问模式是否兼容
- 使用 `-verbose` 标志获取详细映射信息

### 2. 映射错误
- 检查 `raml32kx32w_map.v` 中的信号宽度
- 确认硬件原语 `RAML32KX32W` 的接口定义正确

### 3. 调试技巧
```bash
# 获取详细的内存映射信息
yosys -c "read_verilog design.v; memory_collect; memory_libmap -lib raml32kx32w_lib.txt -verbose"

# 查看内存结构
yosys -c "read_verilog design.v; memory_collect; memory -verbose"
```

## 扩展说明

### 支持多端口
如需支持写端口，可以在 `raml32kx32w_lib.txt` 中添加：
```
port sw "W" {
    clock posedge;
}
```

### 支持不同数据宽度
可以使用 `widths` 属性支持多种数据宽度：
```
widths 8 16 32 per_port;
```

### 字节写使能
如需支持字节写使能，添加：
```
byte 8;  # 8位字节
```

## 注意事项

1. 确保实际的 RAML32KX32W 硬件原语已在你的设计库中正确定义
2. 根据实际硬件特性调整器件库参数
3. 测试映射结果以确保功能正确性
4. 考虑时序约束和功耗要求