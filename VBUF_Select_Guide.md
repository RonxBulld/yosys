# 使用Yosys Select指令查找直接连接的VBUF实例

## 问题描述

已知有模块定义：
```verilog
(* blackbox=1 *)
module VBUF (O, I);
    output O;
    input  I;
endmodule
```

需要查找符合以下条件的VBUF器件实例：
- VBUF的输入端口I直接连接到另一个VBUF的输出端口O
- 中间不存在任何其他器件

## Select指令基础

Yosys的select指令用于选择设计中的对象。基本语法：
```tcl
select [选项] <选择表达式>
```

### 常用选择模式

1. **按类型选择**: `t:VBUF` - 选择所有VBUF类型的实例
2. **按端口选择**: `%x:+[O]` - 展开选择到输出端口O
3. **按端口选择**: `%x:+[I]` - 展开选择到输入端口I

## 查找直接连接VBUF实例的方法

### 方法1: 使用端口展开

```tcl
# 1. 选择所有VBUF实例
select t:VBUF

# 2. 展开到VBUF的输出端口
select %x:+[O]

# 3. 找到连接到这些输出的VBUF输入端口
select %x:+[I] t:VBUF

# 4. 显示结果
select -list
```

### 方法2: 使用连接分析

```tcl
# 1. 选择所有VBUF实例
select t:VBUF

# 2. 分析连接关系
select %x:+[O]
select %x:+[I] t:VBUF

# 3. 显示结果
select -list
```

## 实际示例

### 测试文件 (vbuf_test.v)
```verilog
(* blackbox=1 *)
module VBUF (O, I);
    output O;
    input  I;
endmodule

module top(input a, b, c, output o1, o2);
    wire w1, w2, w3, w4;
    
    // VBUF实例1 - 输入连接到模块输入
    VBUF vbuf1(.O(w1), .I(a));
    
    // VBUF实例2 - 输入直接连接到VBUF实例1的输出
    VBUF vbuf2(.O(w2), .I(w1));
    
    // VBUF实例3 - 输入直接连接到VBUF实例2的输出
    VBUF vbuf3(.O(w3), .I(w2));
    
    // VBUF实例4 - 输入连接到另一个信号
    VBUF vbuf4(.O(w4), .I(b));
    
    // VBUF实例5 - 输入直接连接到VBUF实例4的输出
    VBUF vbuf5(.O(o1), .I(w4));
    
    // 非VBUF实例
    assign o2 = w3 & c;
endmodule
```

### 直接连接的VBUF实例
在这个示例中，以下VBUF实例满足条件：
- `vbuf2` - 输入I连接到`vbuf1`的输出O (通过信号w1)
- `vbuf3` - 输入I连接到`vbuf2`的输出O (通过信号w2)
- `vbuf5` - 输入I连接到`vbuf4`的输出O (通过信号w4)

## 完整的Yosys脚本

```tcl
# 读取Verilog文件
read_verilog vbuf_test.v

# 显示所有VBUF实例
select t:VBUF
select -list

# 查找直接连接的VBUF实例
select -clear
select t:VBUF
select %x:+[O]
select %x:+[I] t:VBUF
select -list

# 显示连接信息
select -clear
select t:VBUF
show -format dot -prefix vbuf_connections
```

## 关键要点

1. **使用`t:VBUF`选择所有VBUF实例**
2. **使用`%x:+[O]`展开到输出端口**
3. **使用`%x:+[I] t:VBUF`找到连接到输出的VBUF输入端口**
4. **使用`select -list`显示选择结果**

## 注意事项

- 确保VBUF模块被正确标记为blackbox
- 端口名称必须与模块定义中的端口名称匹配
- 选择操作是基于当前设计状态的，确保设计已正确加载