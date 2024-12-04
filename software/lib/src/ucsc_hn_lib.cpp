#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <boost/python.hpp>
#include <RenaDataDecoder.h>
#include <RenaDataWriter.h>
#include <RenaLegacyWriter.h>
#include <RenaDataEmulator.h>
#include <RenaDataFormat.h>

BOOST_PYTHON_MODULE(ucsc_hn_lib) {
   //PyEval_InitThreads();
   try {
      ucsc_hn_lib::RenaDataDecoder::setup_python();
      ucsc_hn_lib::RenaDataWriter::setup_python();
      ucsc_hn_lib::RenaLegacyWriter::setup_python();
      ucsc_hn_lib::RenaDataEmulator::setup_python();
      ucsc_hn_lib::RenaDataFormat::setup_python();
   } catch (...) {
      printf("Failed to load module. import rogue first\n");
   }
   printf("Loaded ucsc_hn_lib\n");
};
