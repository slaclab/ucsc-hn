
#include <boost/python.hpp>
#include <RenaDataDecoder.h>
#include <RenaDataWriter.h>

BOOST_PYTHON_MODULE(ucsc_hn_lib) {
   PyEval_InitThreads();
   try {
      ucsc_hn_lib::RenaDataDecoder::setup_python();
      ucsc_hn_lib::RenaDataWriter::setup_python();
   } catch (...) {
      printf("Failed to load module. import rogue first\n");
   }
   printf("Loaded ucsc_hn_lib\n");
};
