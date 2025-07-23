# Binary RTLIL Backend Makefile

OBJS += backends/brtlil/brtlil_backend.o
OBJS += backends/brtlil/rtlil.pb.o

# Protocol Buffer setup
PROTOC ?= protoc
PROTOBUF_CFLAGS := $(shell pkg-config --cflags protobuf 2>/dev/null)
PROTOBUF_LDFLAGS := $(shell pkg-config --libs protobuf 2>/dev/null)

# Add protobuf flags to global flags
CXXFLAGS += $(PROTOBUF_CFLAGS)
LDFLAGS += $(PROTOBUF_LDFLAGS)

# Generate Protocol Buffer C++ files
backends/brtlil/rtlil.pb.cc backends/brtlil/rtlil.pb.h: backends/brtlil/rtlil.proto
	$(PROTOC) --cpp_out=backends/brtlil/ --proto_path=backends/brtlil/ backends/brtlil/rtlil.proto

# Protocol Buffer object file
backends/brtlil/rtlil.pb.o: backends/brtlil/rtlil.pb.cc backends/brtlil/rtlil.pb.h
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) -o $@ $<

# Main backend object file  
backends/brtlil/brtlil_backend.o: backends/brtlil/brtlil_backend.cc backends/brtlil/brtlil_backend.h backends/brtlil/rtlil.pb.h
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) -o $@ $<

# Clean target
clean-brtlil:
	rm -f backends/brtlil/*.o
	rm -f backends/brtlil/rtlil.pb.cc
	rm -f backends/brtlil/rtlil.pb.h

.PHONY: clean-brtlil

# Add to main clean target
clean: clean-brtlil

# Installation target for headers (optional)
install-brtlil-headers: backends/brtlil/brtlil_backend.h backends/brtlil/rtlil.pb.h
	$(INSTALL_DATA) backends/brtlil/brtlil_backend.h $(DESTDIR)$(DATDIR)/include/backends/brtlil/
	$(INSTALL_DATA) backends/brtlil/rtlil.pb.h $(DESTDIR)$(DATDIR)/include/backends/brtlil/

# Check for protobuf availability
check-protobuf:
	@echo "Checking for Protocol Buffers..."
	@if ! command -v $(PROTOC) >/dev/null 2>&1; then \
		echo "Error: protoc (Protocol Buffer compiler) not found."; \
		echo "Please install Protocol Buffers development package."; \
		echo "On Ubuntu/Debian: apt-get install libprotobuf-dev protobuf-compiler"; \
		echo "On CentOS/RHEL: yum install protobuf-devel protobuf-compiler"; \
		echo "On macOS: brew install protobuf"; \
		exit 1; \
	fi
	@if ! pkg-config --exists protobuf; then \
		echo "Error: protobuf pkg-config not found."; \
		echo "Please ensure Protocol Buffers development libraries are installed."; \
		exit 1; \
	fi
	@echo "Protocol Buffers found: $(shell $(PROTOC) --version)"

.PHONY: check-protobuf

# Add protobuf check to main build prerequisites
all: check-protobuf

# Optional: Benchmark binary RTLIL performance
benchmark-brtlil: yosys
	@echo "Running binary RTLIL benchmarks..."
	@./test_scripts/benchmark_brtlil.sh

.PHONY: benchmark-brtlil