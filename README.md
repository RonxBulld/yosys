yosys – Yosys Open SYnthesis Suite
===================================

This is a framework for RTL synthesis tools. It currently has
extensive Verilog-2005 support and provides a basic set of
synthesis algorithms for various application domains.

Yosys can be adapted to perform any synthesis job by combining
the existing passes (algorithms) using synthesis scripts and
adding additional passes as needed by extending the yosys C++
code base.

Yosys is free software licensed under the ISC license (a GPL
compatible license that is similar in terms to the MIT license
or the 2-clause BSD license).

Third-party software distributed alongside this software
is licensed under compatible licenses.
Please refer to `abc` and `libs` subdirectories for their license terms.


Web Site and Other Resources
============================

More information and documentation can be found on the Yosys web site:
- https://yosyshq.net/yosys/

Documentation from this repository is automatically built and available on Read
the Docs:
- https://yosyshq.readthedocs.io/projects/yosys

Users interested in formal verification might want to use the formal
verification front-end for Yosys, SBY:
- https://yosyshq.readthedocs.io/projects/sby/
- https://github.com/YosysHQ/sby


Installation
============

Yosys is part of the [Tabby CAD Suite](https://www.yosyshq.com/tabby-cad-datasheet) and the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build)! The easiest way to use yosys is to install the binary software suite, which contains all required dependencies and related tools.

* [Contact YosysHQ](https://www.yosyshq.com/contact) for a [Tabby CAD Suite](https://www.yosyshq.com/tabby-cad-datasheet) Evaluation License and download link
* OR go to https://github.com/YosysHQ/oss-cad-suite-build/releases to download the free OSS CAD Suite
* Follow the [Install Instructions on GitHub](https://github.com/YosysHQ/oss-cad-suite-build#installation)

Make sure to get a Tabby CAD Suite Evaluation License if you need features such as industry-grade SystemVerilog and VHDL parsers!

For more information about the difference between Tabby CAD Suite and the OSS CAD Suite, please visit https://www.yosyshq.com/tabby-cad-datasheet

Many Linux distributions also provide Yosys binaries, some more up to date than others. Check with your package manager!


Building from Source
====================

For more details, and instructions for other platforms, check [building from
source](https://yosyshq.readthedocs.io/projects/yosys/en/latest/getting_started/installation.html#building-from-source)
on Read the Docs.

When cloning Yosys, some required libraries are included as git submodules. Make
sure to call e.g.

	$ git clone --recurse-submodules https://github.com/YosysHQ/yosys.git

or

	$ git clone https://github.com/YosysHQ/yosys.git
	$ cd yosys
	$ git submodule update --init --recursive

You need a C++ compiler with C++17 support (up-to-date CLANG or GCC is
recommended) and some standard tools such as GNU Flex, GNU Bison, and GNU Make.
TCL, readline and libffi are optional (see ``ENABLE_*`` settings in Makefile).
Xdot (graphviz) is used by the ``show`` command in yosys to display schematics.

For example on Ubuntu Linux 16.04 LTS the following commands will install all
prerequisites for building yosys:

	$ sudo apt-get install build-essential clang lld bison flex \
		libreadline-dev gawk tcl-dev libffi-dev git \
		graphviz xdot pkg-config python3 libboost-system-dev \
		libboost-python-dev libboost-filesystem-dev zlib1g-dev

The environment variable `CXX` can be used to control the C++ compiler used, or
run one of the following to override it:

	$ make config-clang
	$ make config-gcc

The Makefile has many variables influencing the build process. These can be
adjusted by modifying the Makefile.conf file which is created at the `make
config-...` step (see above), or they can be set by passing an option to the
make command directly:

  $ make CXX=$CXX

For other compilers and build configurations it might be necessary to make some
changes to the config section of the Makefile. It's also an alternative way to
set the make variables mentioned above.

	$ vi Makefile            # ..or..
	$ vi Makefile.conf

To build Yosys simply type 'make' in this directory.

	$ make
	$ sudo make install

Tests are located in the tests subdirectory and can be executed using the test
target. Note that you need gawk as well as a recent version of iverilog (i.e.
build from git). Then, execute tests via:

	$ make test

To use a separate (out-of-tree) build directory, provide a path to the Makefile.

	$ mkdir build; cd build
	$ make -f ../Makefile

Out-of-tree builds require a clean source tree.


Getting Started
===============

Yosys can be used with the interactive command shell, with
synthesis scripts or with command line arguments. Let's perform
a simple synthesis job using the interactive command shell:

	$ ./yosys
	yosys>

the command ``help`` can be used to print a list of all available
commands and ``help <command>`` to print details on the specified command:

	yosys> help help

reading and elaborating the design using the Verilog frontend:

	yosys> read -sv tests/simple/fiedler-cooley.v
	yosys> hierarchy -top up3down5

writing the design to the console in the RTLIL format used by Yosys
internally:

	yosys> write_rtlil

convert processes (``always`` blocks) to netlist elements and perform
some simple optimizations:

	yosys> proc; opt

display design netlist using ``xdot``:

	yosys> show

the same thing using ``gv`` as postscript viewer:

	yosys> show -format ps -viewer gv

translating netlist to gate logic and perform some simple optimizations:

	yosys> techmap; opt

write design netlist to a new Verilog file:

	yosys> write_verilog synth.v

or using a simple synthesis script:

	$ cat synth.ys
	read -sv tests/simple/fiedler-cooley.v
	hierarchy -top up3down5
	proc; opt; techmap; opt
	write_verilog synth.v

	$ ./yosys synth.ys

If ABC is enabled in the Yosys build configuration and a cell library is given
in the liberty file ``mycells.lib``, the following synthesis script will
synthesize for the given cell library:

	# read design
	read -sv tests/simple/fiedler-cooley.v
	hierarchy -top up3down5

	# the high-level stuff
	proc; fsm; opt; memory; opt

	# mapping to internal cell library
	techmap; opt

	# mapping flip-flops to mycells.lib
	dfflibmap -liberty mycells.lib

	# mapping logic to mycells.lib
	abc -liberty mycells.lib

	# cleanup
	clean

If you do not have a liberty file but want to test this synthesis script,
you can use the file ``examples/cmos/cmos_cells.lib`` from the yosys sources
as simple example.

Liberty file downloads for and information about free and open ASIC standard
cell libraries can be found here:

- http://www.vlsitechnology.org/html/libraries.html
- http://www.vlsitechnology.org/synopsys/vsclib013.lib

The command ``synth`` provides a good default synthesis script (see
``help synth``):

	read -sv tests/simple/fiedler-cooley.v
	synth -top up3down5

	# mapping to target cells
	dfflibmap -liberty mycells.lib
	abc -liberty mycells.lib
	clean

The command ``prep`` provides a good default word-level synthesis script, as
used in SMT-based formal verification.


Additional information
======================

The ``read_verilog`` command, used by default when calling ``read`` with Verilog
source input, does not perform syntax checking.  You should instead lint your
source with another tool such as
[Verilator](https://www.veripool.org/verilator/) first, e.g. by calling
``verilator --lint-only``.


Building the documentation
==========================

Note that there is no need to build the manual if you just want to read it.
Simply visit https://yosys.readthedocs.io/en/latest/ instead.

In addition to those packages listed above for building Yosys from source, the
following are used for building the website: 

	$ sudo apt install pdf2svg faketime

Or for MacOS, using homebrew:

  $ brew install pdf2svg libfaketime

PDFLaTeX, included with most LaTeX distributions, is also needed during the
build process for the website.  Or, run the following:

	$ sudo apt install texlive-latex-base texlive-latex-extra latexmk

Or for MacOS, using homebrew:

  $ brew install basictex
  $ sudo tlmgr update --self   
  $ sudo tlmgr install collection-latexextra latexmk tex-gyre

The Python package, Sphinx, is needed along with those listed in
`docs/source/requirements.txt`:

	$ pip install -U sphinx -r docs/source/requirements.txt

From the root of the repository, run `make docs`.  This will build/rebuild yosys
as necessary before generating the website documentation from the yosys help
commands.  To build for pdf instead of html, call 
`make docs DOC_TARGET=latexpdf`.

# 通用内存模板 (Generic Memory Template)

这个项目提供了一个具有可变端口数量的通用内存描述文件，可以将任何内存综合到这个目标，然后进行二次处理。

## 文件结构

- `generic_memory_template.v` - 核心的通用内存模块
- `memory_config_generator.py` - 配置生成器脚本  
- `usage_examples.v` - 使用示例
- `README.md` - 说明文档

## 核心特性

### 1. 可变端口数量
- 支持任意数量的读端口 (RD_PORTS)
- 支持任意数量的写端口 (WR_PORTS)
- 每个端口可以独立配置

### 2. 灵活的配置选项
- 内存大小 (SIZE) 和数据位宽 (WIDTH) 可配置
- 支持不同的时钟极性和使能模式
- 支持透明读取和冲突处理
- 支持同步/异步复位

### 3. 兼容性
- 与Yosys综合工具兼容
- 遵循标准Verilog语法
- 支持各种FPGA和ASIC目标

## 参数说明

### 基本内存参数
```verilog
parameter MEMID = "generic_mem"  // 内存标识符
parameter SIZE = 1024            // 内存深度（字数）
parameter OFFSET = 0             // 地址偏移
parameter ABITS = 10             // 地址位宽
parameter WIDTH = 32             // 数据位宽
parameter INIT = 0               // 初始化值
```

### 端口配置参数
```verilog
parameter RD_PORTS = 2           // 读端口数量
parameter WR_PORTS = 2           // 写端口数量
```

### 读端口配置
```verilog
parameter RD_CLK_ENABLE = {RD_PORTS{1'b1}}      // 每个读端口的时钟使能
parameter RD_CLK_POLARITY = {RD_PORTS{1'b1}}    // 每个读端口的时钟极性
parameter RD_TRANSPARENCY = {RD_PORTS{1'b0}}    // 每个读端口的透明模式
parameter RD_COLLISION_X = {RD_PORTS{1'b0}}     // 每个读端口的冲突行为
```

### 写端口配置
```verilog
parameter WR_CLK_ENABLE = {WR_PORTS{1'b1}}      // 每个写端口的时钟使能
parameter WR_CLK_POLARITY = {WR_PORTS{1'b1}}    // 每个写端口的时钟极性
```

## 使用方法

### 1. 直接实例化

```verilog
generic_memory #(
    .SIZE(1024),
    .WIDTH(32),
    .RD_PORTS(2),
    .WR_PORTS(1)
) my_memory (
    .RD_CLK({clk, clk}),
    .RD_EN({rd_en1, rd_en0}),
    .RD_ADDR({addr1, addr0}),
    .RD_DATA({data1, data0}),
    
    .WR_CLK(clk),
    .WR_EN(wr_en),
    .WR_BE(wr_be),
    .WR_ADDR(wr_addr),
    .WR_DATA(wr_data)
);
```

### 2. 使用配置生成器

```bash
# 列出所有预设配置
python memory_config_generator.py --list

# 使用预设配置生成双端口内存
python memory_config_generator.py --preset dual_port

# 自定义配置：4读2写，2048x64bit
python memory_config_generator.py --custom --rd_ports 4 --wr_ports 2 --size 2048 --width 64

# 生成完整模块到文件
python memory_config_generator.py --preset register_file --full_module --output reg_file.v
```

## 预设配置

| 名称 | 描述 | 读端口 | 写端口 | 大小 | 位宽 |
|------|------|--------|--------|------|------|
| single_port | 单端口内存 | 1 | 1 | 1024 | 32 |
| dual_port | 双端口内存 | 2 | 2 | 1024 | 32 |
| quad_read | 四读单写内存 | 4 | 1 | 2048 | 64 |
| register_file | 寄存器文件 | 8 | 4 | 32 | 32 |
| cache_line | 缓存行存储 | 2 | 1 | 64 | 512 |
| fifo_buffer | FIFO缓冲区 | 1 | 1 | 256 | 64 |

## 高级特性

### 1. 透明读取
设置 `RD_TRANSPARENCY` 参数可以启用透明读取模式，在读写同一地址时直接返回写入的数据。

### 2. 冲突处理
设置 `RD_COLLISION_X` 参数可以在读写冲突时输出未知值 (X)。

### 3. 不同时钟域
读端口和写端口可以使用不同的时钟，支持跨时钟域操作。

### 4. 字节使能
支持细粒度的字节使能控制，可以部分写入数据字。

## 应用场景

### 1. 处理器设计
- 寄存器文件：多读多写端口
- 缓存存储：快速多端口访问
- 指令/数据存储器

### 2. 数据通路设计  
- FIFO缓冲区：透明读取模式
- 查找表：只读多端口访问
- 临时存储：灵活端口配置

### 3. SoC集成
- 共享存储器：多主机访问
- DMA缓冲区：异步读写
- 外设接口缓存

## 综合注意事项

### 1. 资源使用
- 端口数量直接影响资源消耗
- 考虑目标FPGA的块RAM限制
- 优化端口配置以减少逻辑资源

### 2. 时序优化
- 多端口可能增加时序压力
- 考虑添加流水线级
- 平衡端口数量和频率要求

### 3. 二次处理
这个模板作为综合目标，可以进一步优化：
- 映射到特定的块RAM资源
- 优化端口多路复用
- 添加错误检测和纠正

## 调试支持

编译时定义 `DEBUG_MEMORY` 宏可以启用调试输出：

```verilog
`define DEBUG_MEMORY
```

这将在仿真时显示所有读写操作的详细信息。

## 示例项目

查看 `usage_examples.v` 文件了解完整的使用示例，包括：
- 单端口内存
- 双端口内存  
- 多端口寄存器文件
- 缓存行存储
- FIFO缓冲区
- 异步时钟域内存
- ROM实现

## 扩展和自定义

这个模板可以根据具体需求进行扩展：
1. 添加ECC支持
2. 实现特定的写入模式
3. 优化特定FPGA架构
4. 添加性能计数器
5. 集成测试和验证逻辑

## 许可证

本项目与Yosys Open SYnthesis Suite兼容，采用相同的开源许可证。
