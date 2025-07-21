/*
 *  yosys -- Yosys Open SYnthesis Suite
 *
 *  Copyright (C) 2024  YosysHQ GmbH <hello@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/log.h"
#include <fstream>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct OffloadInitPass : public Pass {
	OffloadInitPass() : Pass("offload_init", "offload INIT attributes to a structured file and clear them") { }
	
	void help() override
	{
		//   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
		log("\n");
		log("    offload_init [-file <filename>] [-format <json|csv>] [selection]\n");
		log("\n");
		log("For all selected objects, write the INIT attribute content to a structured\n");
		log("file and then clear the INIT attribute. This pass supports [selected] semantics\n");
		log("to process only the currently selected objects.\n");
		log("\n");
		log("    -file <filename>\n");
		log("        write INIT data to the specified file (default: init_data.json)\n");
		log("\n");
		log("    -format <json|csv>\n");
		log("        output format: json (default) or csv\n");
		log("\n");
		log("The output file contains the module name, object type, object name, and\n");
		log("INIT value for each object that had an INIT attribute.\n");
		log("\n");
	}
	
	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		std::string filename = "init_data.json";
		std::string format = "json";
		
		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++)
		{
			std::string arg = args[argidx];
			if (arg == "-file" && argidx+1 < args.size()) {
				filename = args[++argidx];
				continue;
			}
			if (arg == "-format" && argidx+1 < args.size()) {
				format = args[++argidx];
				if (format != "json" && format != "csv") {
					log_cmd_error("Unknown format '%s'. Supported formats: json, csv\n", format.c_str());
				}
				continue;
			}
			break;
		}
		extra_args(args, argidx, design);
		
		log_header(design, "Executing OFFLOAD_INIT pass (offload INIT attributes to file).\n");
		
		std::vector<std::tuple<std::string, std::string, std::string, std::string>> init_data;
		int processed_count = 0;
		
		// Process all selected modules
		for (auto module : design->selected_modules())
		{
			log("Processing module %s..\n", log_id(module));
			
			// Process selected wires in the module
			for (auto wire : module->selected_wires()) {
				if (wire->attributes.count(ID::init)) {
					RTLIL::Const init_val = wire->attributes.at(ID::init);
					std::string init_str = init_val.as_string();
					
					init_data.push_back(std::make_tuple(
						log_id(module),
						"wire", 
						log_id(wire), 
						init_str
					));
					
					// Clear the INIT attribute
					wire->attributes.erase(ID::init);
					processed_count++;
					
					log("  Wire %s: INIT=%s (cleared)\n", log_id(wire), init_str.c_str());
				}
			}
			
			// Process selected cells in the module
			for (auto cell : module->selected_cells()) {
				// Check for INIT parameter in cells
				if (cell->parameters.count(ID::INIT)) {
					RTLIL::Const init_val = cell->parameters.at(ID::INIT);
					std::string init_str = init_val.as_string();
					
					init_data.push_back(std::make_tuple(
						log_id(module),
						"cell_param", 
						log_id(cell), 
						init_str
					));
					
					// Clear the INIT parameter
					cell->parameters.erase(ID::INIT);
					processed_count++;
					
					log("  Cell %s: INIT param=%s (cleared)\n", log_id(cell), init_str.c_str());
				}
				
				// Check for INIT attribute in cells
				if (cell->attributes.count(ID::init)) {
					RTLIL::Const init_val = cell->attributes.at(ID::init);
					std::string init_str = init_val.as_string();
					
					init_data.push_back(std::make_tuple(
						log_id(module),
						"cell_attr", 
						log_id(cell), 
						init_str
					));
					
					// Clear the INIT attribute
					cell->attributes.erase(ID::init);
					processed_count++;
					
					log("  Cell %s: INIT attr=%s (cleared)\n", log_id(cell), init_str.c_str());
				}
			}
			
			// Process module-level INIT attributes if the whole module is selected
			if (design->selected_whole_module(module) && module->attributes.count(ID::init)) {
				RTLIL::Const init_val = module->attributes.at(ID::init);
				std::string init_str = init_val.as_string();
				
				init_data.push_back(std::make_tuple(
					log_id(module),
					"module", 
					log_id(module), 
					init_str
				));
				
				// Clear the INIT attribute
				module->attributes.erase(ID::init);
				processed_count++;
				
				log("  Module %s: INIT attr=%s (cleared)\n", log_id(module), init_str.c_str());
			}
		}
		
		// Write the collected data to the output file
		if (!init_data.empty()) {
			std::ofstream outfile(filename);
			if (!outfile.is_open()) {
				log_error("Cannot open file '%s' for writing: %s\n", filename.c_str(), strerror(errno));
			}
			
			if (format == "json") {
				outfile << "{\n";
				outfile << "  \"init_data\": [\n";
				
				for (size_t i = 0; i < init_data.size(); i++) {
					auto& [module_name, object_type, object_name, init_value] = init_data[i];
					outfile << "    {\n";
					outfile << "      \"module\": \"" << module_name << "\",\n";
					outfile << "      \"object_type\": \"" << object_type << "\",\n";
					outfile << "      \"object_name\": \"" << object_name << "\",\n";
					outfile << "      \"init_value\": \"" << init_value << "\"\n";
					outfile << "    }";
					if (i < init_data.size() - 1) outfile << ",";
					outfile << "\n";
				}
				
				outfile << "  ]\n";
				outfile << "}\n";
			} else if (format == "csv") {
				outfile << "module,object_type,object_name,init_value\n";
				for (auto& [module_name, object_type, object_name, init_value] : init_data) {
					outfile << "\"" << module_name << "\",\"" << object_type << "\",\"" 
							<< object_name << "\",\"" << init_value << "\"\n";
				}
			}
			
			outfile.close();
			log("Wrote %d INIT entries to '%s' in %s format.\n", 
				(int)init_data.size(), filename.c_str(), format.c_str());
		} else {
			log("No INIT attributes found in selected objects.\n");
		}
		
		log("Processed %d objects with INIT attributes.\n", processed_count);
	}
} OffloadInitPass;

PRIVATE_NAMESPACE_END