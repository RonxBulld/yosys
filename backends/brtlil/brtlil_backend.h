#ifndef BRTLIL_BACKEND_H
#define BRTLIL_BACKEND_H

#include "kernel/yosys.h"
#include "rtlil.pb.h"
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>

YOSYS_NAMESPACE_BEGIN

namespace BRTLIL_BACKEND {

class BinaryRtlilWriter {
public:
	BinaryRtlilWriter();
	~BinaryRtlilWriter();
	
	// Main write function
	bool write_design(const RTLIL::Design *design, std::ostream &output, bool compress = false);
	
private:
	// Helper functions for converting RTLIL to protobuf
	void convert_design(const RTLIL::Design *rtlil_design, yosys::rtlil::Design *proto_design);
	void convert_module(const RTLIL::Module *rtlil_module, yosys::rtlil::Module *proto_module);
	void convert_wire(const RTLIL::Wire *rtlil_wire, yosys::rtlil::Wire *proto_wire);
	void convert_cell(const RTLIL::Cell *rtlil_cell, yosys::rtlil::Cell *proto_cell);
	void convert_memory(const RTLIL::Memory *rtlil_memory, yosys::rtlil::Memory *proto_memory);
	void convert_process(const RTLIL::Process *rtlil_process, yosys::rtlil::Process *proto_process);
	void convert_sigspec(const RTLIL::SigSpec &rtlil_sigspec, yosys::rtlil::SigSpec *proto_sigspec);
	void convert_const(const RTLIL::Const &rtlil_const, yosys::rtlil::Const *proto_const);
	void convert_case_rule(const RTLIL::CaseRule *rtlil_case, yosys::rtlil::CaseRule *proto_case);
	void convert_sync_rule(const RTLIL::SyncRule *rtlil_sync, yosys::rtlil::SyncRule *proto_sync);
	
	// Attribute conversion helpers
	void convert_attributes(const dict<RTLIL::IdString, RTLIL::Const> &rtlil_attrs,
	                       google::protobuf::Map<std::string, yosys::rtlil::Const> *proto_attrs);
	
	// Bit packing utilities
	std::string pack_bits(const RTLIL::Const &const_val);
	
	// Statistics and progress tracking
	size_t modules_processed;
	size_t cells_processed;
	size_t wires_processed;
};

class BinaryRtlilReader {
public:
	BinaryRtlilReader();
	~BinaryRtlilReader();
	
	// Main read function
	bool read_design(RTLIL::Design *design, std::istream &input);
	
private:
	// Helper functions for converting protobuf to RTLIL
	void convert_design(const yosys::rtlil::Design &proto_design, RTLIL::Design *rtlil_design);
	void convert_module(const yosys::rtlil::Module &proto_module, RTLIL::Module *rtlil_module);
	void convert_wire(const yosys::rtlil::Wire &proto_wire, RTLIL::Module *module);
	void convert_cell(const yosys::rtlil::Cell &proto_cell, RTLIL::Module *module);
	void convert_memory(const yosys::rtlil::Memory &proto_memory, RTLIL::Module *module);
	void convert_process(const yosys::rtlil::Process &proto_process, RTLIL::Module *module);
	RTLIL::SigSpec convert_sigspec(const yosys::rtlil::SigSpec &proto_sigspec, RTLIL::Module *module);
	RTLIL::Const convert_const(const yosys::rtlil::Const &proto_const);
	void convert_case_rule(const yosys::rtlil::CaseRule &proto_case, RTLIL::CaseRule *rtlil_case, RTLIL::Module *module);
	void convert_sync_rule(const yosys::rtlil::SyncRule &proto_sync, RTLIL::SyncRule *rtlil_sync, RTLIL::Module *module);
	
	// Attribute conversion helpers
	void convert_attributes(const google::protobuf::Map<std::string, yosys::rtlil::Const> &proto_attrs,
	                       dict<RTLIL::IdString, RTLIL::Const> &rtlil_attrs);
	
	// Bit unpacking utilities
	RTLIL::Const unpack_bits(const std::string &packed_bits, int width, int flags);
	
	// Error handling
	std::string last_error;
	
	// Statistics
	size_t modules_loaded;
	size_t cells_loaded;
	size_t wires_loaded;
};

// Utility functions
bool is_binary_rtlil_file(const std::string &filename);
std::string get_format_info(std::istream &input);

// Performance metrics
struct BinaryRtlilStats {
	size_t original_size;
	size_t compressed_size;
	double write_time;
	double read_time;
	size_t num_modules;
	size_t num_cells;
	size_t num_wires;
	
	void print_stats() const;
};

} // namespace BRTLIL_BACKEND

YOSYS_NAMESPACE_END

#endif // BRTLIL_BACKEND_H