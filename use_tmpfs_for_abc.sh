#!/bin/bash
# 使用tmpfs加速Yosys ABC综合的示例脚本

# 检查是否在Linux系统
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "警告：此脚本主要针对Linux系统设计"
fi

# 方法1：使用系统的/dev/shm（推荐）
echo "=== 方法1：使用/dev/shm ==="
if [ -d "/dev/shm" ]; then
    echo "检测到/dev/shm，这是一个内存文件系统"
    echo "设置TMPDIR环境变量..."
    export TMPDIR=/dev/shm
    echo "TMPDIR已设置为: $TMPDIR"
    
    # 显示可用空间
    df -h /dev/shm
else
    echo "/dev/shm不存在"
fi

# 方法2：创建专用的tmpfs挂载点（需要root权限）
echo -e "\n=== 方法2：创建专用tmpfs（需要sudo） ==="
RAMDISK_PATH="/tmp/yosys-ramdisk"
RAMDISK_SIZE="2G"  # 根据需要调整大小

create_ramdisk() {
    if [ ! -d "$RAMDISK_PATH" ]; then
        echo "创建挂载点目录..."
        sudo mkdir -p "$RAMDISK_PATH"
    fi
    
    # 检查是否已挂载
    if ! mount | grep -q "$RAMDISK_PATH"; then
        echo "挂载tmpfs到$RAMDISK_PATH（大小：$RAMDISK_SIZE）..."
        sudo mount -t tmpfs -o size=$RAMDISK_SIZE tmpfs "$RAMDISK_PATH"
        echo "tmpfs已挂载"
    else
        echo "tmpfs已经挂载在$RAMDISK_PATH"
    fi
    
    # 设置权限
    sudo chmod 777 "$RAMDISK_PATH"
    
    # 显示挂载信息
    df -h "$RAMDISK_PATH"
}

# 方法3：性能测试脚本
echo -e "\n=== 性能测试脚本 ==="
cat > /tmp/benchmark_abc.ys << 'EOF'
# Yosys性能测试脚本
# 读取你的设计文件
# read_verilog your_design.v

# 为了演示，创建一个测试设计
read_verilog -sv << EOV
module test_design #(parameter WIDTH = 32) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [WIDTH-1:0] result
);
    reg [WIDTH-1:0] temp1, temp2, temp3;
    
    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
            temp1 <= 0;
            temp2 <= 0;
            temp3 <= 0;
        end else begin
            temp1 <= a + b;
            temp2 <= a - b;
            temp3 <= temp1 * temp2;
            result <= temp3 + (a ^ b);
        end
    end
endmodule
EOV

# 综合流程
hierarchy -check -top test_design
proc
opt
fsm
opt
memory
opt
techmap
opt

# 使用ABC进行技术映射
abc -liberty mycells.lib

# 显示统计信息
stat
EOF

echo "性能测试脚本已创建: /tmp/benchmark_abc.ys"

# 运行测试的函数
run_benchmark() {
    local tmpdir=$1
    local desc=$2
    
    echo -e "\n--- 测试：$desc ---"
    echo "TMPDIR=$tmpdir"
    
    # 记录开始时间
    start_time=$(date +%s.%N)
    
    # 运行Yosys
    TMPDIR=$tmpdir yosys -q /tmp/benchmark_abc.ys
    
    # 记录结束时间
    end_time=$(date +%s.%N)
    
    # 计算耗时
    duration=$(echo "$end_time - $start_time" | bc)
    echo "耗时：$duration 秒"
}

# 提供使用示例
echo -e "\n=== 使用示例 ==="
echo "1. 使用/dev/shm运行Yosys："
echo "   export TMPDIR=/dev/shm"
echo "   yosys your_script.ys"
echo ""
echo "2. 创建并使用专用ramdisk："
echo "   $0 --create-ramdisk"
echo "   export TMPDIR=$RAMDISK_PATH"
echo "   yosys your_script.ys"
echo ""
echo "3. 运行性能对比测试："
echo "   $0 --benchmark"

# 处理命令行参数
if [ "$1" == "--create-ramdisk" ]; then
    create_ramdisk
elif [ "$1" == "--benchmark" ]; then
    echo "运行性能对比测试..."
    
    # 测试1：使用默认/tmp
    run_benchmark "/tmp" "默认/tmp目录"
    
    # 测试2：使用/dev/shm
    if [ -d "/dev/shm" ]; then
        run_benchmark "/dev/shm" "/dev/shm内存文件系统"
    fi
    
    # 测试3：使用专用ramdisk（如果已创建）
    if mount | grep -q "$RAMDISK_PATH"; then
        run_benchmark "$RAMDISK_PATH" "专用tmpfs ramdisk"
    fi
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "用法："
    echo "  $0                    显示使用说明"
    echo "  $0 --create-ramdisk   创建专用的tmpfs挂载点"
    echo "  $0 --benchmark        运行性能对比测试"
    echo "  $0 --help            显示此帮助信息"
fi

# 清理函数（可选）
cleanup_ramdisk() {
    if mount | grep -q "$RAMDISK_PATH"; then
        echo "卸载tmpfs..."
        sudo umount "$RAMDISK_PATH"
        sudo rmdir "$RAMDISK_PATH"
    fi
}

# 如果需要清理，取消下面的注释
# trap cleanup_ramdisk EXIT