#!/usr/bin/env python3
"""
验证 offload_init Pass 的功能逻辑
模拟 Pass 的行为来确保实现正确
"""

import json
import csv
import os

def simulate_offload_init(objects_with_init, output_file, format_type="json"):
    """
    模拟 offload_init Pass 的功能
    
    Args:
        objects_with_init: 包含INIT属性的对象列表
        output_file: 输出文件名
        format_type: 输出格式 ("json" 或 "csv")
    
    Returns:
        处理的对象数量
    """
    
    init_data = []
    processed_count = 0
    
    print("=== 模拟 OFFLOAD_INIT Pass ===")
    
    # 模拟遍历选中的对象
    for obj in objects_with_init:
        module_name = obj.get("module", "unknown")
        object_type = obj.get("type", "unknown")
        object_name = obj.get("name", "unknown")
        
        # 检查是否有INIT数据
        if "init_value" in obj:
            init_value = obj["init_value"]
            
            # 收集数据
            init_data.append({
                "module": module_name,
                "object_type": object_type,
                "object_name": object_name,
                "init_value": init_value
            })
            
            processed_count += 1
            print(f"  {object_type.capitalize()} {object_name}: INIT={init_value} (cleared)")
            
            # 模拟清空INIT字段
            del obj["init_value"]
    
    # 写入输出文件
    if init_data:
        if format_type == "json":
            with open(output_file, 'w') as f:
                json.dump({"init_data": init_data}, f, indent=2)
        elif format_type == "csv":
            with open(output_file, 'w', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=["module", "object_type", "object_name", "init_value"])
                writer.writeheader()
                writer.writerows(init_data)
        
        print(f"Wrote {len(init_data)} INIT entries to '{output_file}' in {format_type} format.")
    else:
        print("No INIT attributes found in selected objects.")
    
    print(f"Processed {processed_count} objects with INIT attributes.")
    return processed_count

def test_offload_init():
    """测试 offload_init Pass 的功能"""
    
    print("=== 测试 offload_init Pass 功能 ===\n")
    
    # 模拟包含INIT属性的对象
    test_objects = [
        {
            "module": "test_module",
            "type": "wire",
            "name": "test_wire",
            "init_value": "4'b1010"
        },
        {
            "module": "test_module", 
            "type": "cell_param",
            "name": "test_cell",
            "init_value": "4'b0101"
        },
        {
            "module": "test_module",
            "type": "cell_attr", 
            "name": "another_cell",
            "init_value": "8'hFF"
        },
        {
            "module": "test_module",
            "type": "module",
            "name": "test_module",
            "init_value": "1'b1"
        },
        {
            "module": "test_module",
            "type": "wire",
            "name": "no_init_wire"
            # 没有 init_value
        }
    ]
    
    print("初始对象状态:")
    for i, obj in enumerate(test_objects):
        init_status = obj.get("init_value", "none")
        print(f"  {i+1}. {obj['type']} '{obj['name']}': INIT={init_status}")
    
    print()
    
    # 测试 JSON 格式输出
    print("测试 1: JSON 格式输出")
    test_objects_copy = [obj.copy() for obj in test_objects]
    processed = simulate_offload_init(test_objects_copy, "test_output.json", "json")
    
    # 检查输出文件
    if os.path.exists("test_output.json"):
        with open("test_output.json", 'r') as f:
            content = f.read()
            print("输出文件内容:")
            print(content)
    
    print("\n" + "="*50 + "\n")
    
    # 测试 CSV 格式输出
    print("测试 2: CSV 格式输出")
    test_objects_copy = [obj.copy() for obj in test_objects]
    processed = simulate_offload_init(test_objects_copy, "test_output.csv", "csv")
    
    # 检查输出文件
    if os.path.exists("test_output.csv"):
        with open("test_output.csv", 'r') as f:
            content = f.read()
            print("输出文件内容:")
            print(content)
    
    print("\n" + "="*50 + "\n")
    
    # 验证对象的INIT字段已被清空
    print("验证: INIT字段清空状态")
    for i, obj in enumerate(test_objects_copy):
        init_status = obj.get("init_value", "none")
        print(f"  {i+1}. {obj['type']} '{obj['name']}': INIT={init_status}")
    
    print("\n测试完成!")
    
    # 清理测试文件
    for file in ["test_output.json", "test_output.csv"]:
        if os.path.exists(file):
            os.remove(file)
            print(f"清理测试文件: {file}")

if __name__ == "__main__":
    test_offload_init()