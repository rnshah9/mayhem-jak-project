#pragma once

/*!
 * @file DgoWriter.h
 * Create a DGO from existing files.
 */

#include <vector>
#include <string>

struct DgoDescription {
  std::string dgo_name;
  struct DgoEntry {
    std::string file_name;
    std::string name_in_dgo;
  };
  std::vector<DgoEntry> entries;
};

void build_dgo(const DgoDescription& description);
