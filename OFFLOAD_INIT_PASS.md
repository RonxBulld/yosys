# offload_init Pass

## 概述

`offload_init` 是一个新的 Yosys Pass，用于将选中对象的 INIT 字段内容写入结构化文件中，并清空这些 INIT 字段。该 Pass 支持 `[selected]` 选择语义，只处理当前选中的对象。

## 功能

1. **提取 INIT 数据**：从选中的模块、线路（wire）和单元（cell）中提取 INIT 属性和参数
2. **结构化输出**：将提取的数据以 JSON 或 CSV 格式写入文件
3. **清理 INIT 字段**：处理完成后清空原始的 INIT 属性和参数
4. **选择语义支持**：支持 Yosys 的选择语义，只处理选中的对象

## 语法

```
offload_init [-file <filename>] [-format <json|csv>] [selection]
```

### 参数

- `-file <filename>`：指定输出文件名（默认：`init_data.json`）
- `-format <json|csv>`：指定输出格式，支持 JSON（默认）或 CSV

### 选择语义

Pass 支持标准的 Yosys 选择语义：
- 使用 `design->selected_modules()` 获取选中的模块
- 使用 `module->selected_wires()` 获取选中的线路
- 使用 `module->selected_cells()` 获取选中的单元
- 使用 `design->selected_whole_module(module)` 检查模块是否完全选中

## 处理的 INIT 类型

### 1. Wire 的 INIT 属性
```verilog
wire [3:0] signal /* synthesis init = "4'b1010" */;
```
- 位置：`wire->attributes[ID::init]`
- 类型：`cell_attr`

### 2. Cell 的 INIT 参数
```verilog
// 例如在 LUT 或 DFF 单元中
.INIT(16'h5555)
```
- 位置：`cell->parameters[ID::INIT]`
- 类型：`cell_param`

### 3. Cell 的 INIT 属性
- 位置：`cell->attributes[ID::init]`
- 类型：`cell_attr`

### 4. Module 的 INIT 属性
- 位置：`module->attributes[ID::init]`
- 类型：`module`

## 输出格式

### JSON 格式（默认）
```json
{
  "init_data": [
    {
      "module": "test_module",
      "object_type": "wire",
      "object_name": "signal",
      "init_value": "4'b1010"
    },
    {
      "module": "test_module", 
      "object_type": "cell_param",
      "object_name": "lut_inst",
      "init_value": "16'h5555"
    }
  ]
}
```

### CSV 格式
```csv
module,object_type,object_name,init_value
"test_module","wire","signal","4'b1010"
"test_module","cell_param","lut_inst","16'h5555"
```

## 使用示例

### 1. 处理所有对象
```yosys
# 读取设计
read_verilog design.v
hierarchy -top top_module

# 选择所有对象并处理 INIT
select *
offload_init -file all_inits.json

# 或者使用 CSV 格式
offload_init -file all_inits.csv -format csv
```

### 2. 只处理特定线路
```yosys
# 只选择线路
select w:*
offload_init -file wire_inits.json
```

### 3. 只处理特定模块
```yosys
# 选择特定模块
select top_module
offload_init -file module_inits.json
```

## 实现细节

### Pass 结构
```cpp
struct OffloadInitPass : public Pass {
    OffloadInitPass() : Pass("offload_init", "offload INIT attributes to a structured file and clear them") { }
    void help() override;
    void execute(std::vector<std::string> args, RTLIL::Design *design) override;
}
```

### 核心处理逻辑
1. **参数解析**：解析命令行参数（文件名、格式）
2. **对象遍历**：遍历所有选中的模块、线路和单元
3. **INIT 提取**：检查并提取各种类型的 INIT 数据
4. **数据存储**：将提取的数据存储到向量中
5. **文件输出**：根据指定格式写入文件
6. **属性清理**：清空原始的 INIT 属性和参数

### 选择语义处理
```cpp
// 遍历选中的模块
for (auto module : design->selected_modules()) {
    // 处理选中的线路
    for (auto wire : module->selected_wires()) {
        if (wire->attributes.count(ID::init)) {
            // 提取和清理
        }
    }
    
    // 处理选中的单元
    for (auto cell : module->selected_cells()) {
        // 检查参数和属性
    }
    
    // 处理模块级属性（如果整个模块被选中）
    if (design->selected_whole_module(module)) {
        // 处理模块属性
    }
}
```

## 编译和集成

### 文件位置
- 源文件：`passes/cmds/offload_init.cc`
- Makefile：在 `passes/cmds/Makefile.inc` 中添加 `OBJS += passes/cmds/offload_init.o`

### 编译
```bash
# 编译单个 Pass
make passes/cmds/offload_init.o

# 编译完整 Yosys
make ENABLE_READLINE=0 ENABLE_TCL=0
```

## 错误处理

- **文件写入失败**：使用 `log_error()` 报告无法创建输出文件
- **参数错误**：使用 `log_cmd_error()` 报告无效的格式参数
- **内存管理**：自动管理所有内存分配

## 日志输出

Pass 提供详细的日志输出：
- 处理每个模块的进度
- 每个发现的 INIT 属性的详细信息
- 输出文件的创建状态
- 处理的对象总数统计

## 与其他 Pass 的关系

该 Pass 类似于：
- `setattr`：操作属性
- `printattrs`：显示属性
- `opt_clean`：处理 INIT 属性的清理

但是 `offload_init` 专门用于将 INIT 数据导出到外部文件，适用于需要保存初始化信息以供后续工具使用的场景。