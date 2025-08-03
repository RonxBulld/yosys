#!/bin/bash

echo "Testing VBUF select commands with Yosys"
echo "======================================="

# Create a simple test script
cat > test_select.ys << 'EOF'
# Read the test file
read_verilog vbuf_example.v
hierarchy -check -top test_vbuf

echo "\n=== All VBUF instances in the design ==="
select -list t:VBUF

echo "\n=== VBUF instances with input I connected to another VBUF's output O ==="
select -list t:VBUF %ci:+[I] t:VBUF %d

echo "\n=== Detailed view: showing the connections ==="
# Show which VBUF drives which
select -clear
select -set all_vbufs t:VBUF
select -clear

# For each VBUF, check if its input is driven by another VBUF
foreach cell $all_vbufs {
    select $cell
    select %ci:+[I] t:VBUF
    set driver [selection_to_tcl_list]
    if {[llength $driver] > 0} {
        puts "$driver -> $cell"
    }
}
EOF

# Run Yosys with the test script
if command -v yosys >/dev/null 2>&1; then
    yosys -q test_select.ys
else
    echo "Yosys is not installed. The select command would be:"
    echo "select -list t:VBUF %ci:+[I] t:VBUF %d"
fi