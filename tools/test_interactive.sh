#!/bin/bash

echo "Testing launcher interactive mode..."
echo ""

# Create a test input file for automated testing
cat > test_input.txt << EOF
help
history
test command 1
test command 2
history
exit
EOF

echo "Running launcher with test input..."
./launcher -i < test_input.txt

echo ""
echo "Test completed. Check .launcher_history for saved history."

# Clean up
rm -f test_input.txt