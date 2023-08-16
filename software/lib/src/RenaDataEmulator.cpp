#define __STDC_FORMAT_MACRO
#include <inttypes.h>
#include <RenaDataEmulator.h>
#include <rogue/interfaces/stream/Master.h>
#include <rogue/interfaces/stream/Frame.h>
#include <rogue/interfaces/stream/FrameIterator.h>
#include <boost/python.hpp>
#include <rogue/GeneralError.h>
#include <stdio.h>
#include <fcntl.h>

namespace ris = rogue::interfaces::stream;
namespace bp = boost::python;

ucsc_hn_lib::RenaDataEmulatorPtr ucsc_hn_lib::RenaDataEmulator::create(std::string file) {
   ucsc_hn_lib::RenaDataEmulatorPtr r = std::make_shared<ucsc_hn_lib::RenaDataEmulator>(file);
   return(r);
}

void ucsc_hn_lib::RenaDataEmulator::setup_python() {
   bp::class_<ucsc_hn_lib::RenaDataEmulator, ucsc_hn_lib::RenaDataEmulatorPtr, bp::bases<ris::Master>, boost::noncopyable >("RenaDataEmulator",bp::init<std::string>())
      .def("_start",             &ucsc_hn_lib::RenaDataEmulator::start)
      .def("_stop",              &ucsc_hn_lib::RenaDataEmulator::stop)
      .def("setDataEnable",      &ucsc_hn_lib::RenaDataEmulator::setDataEnable)
      .def("getDataEnable",      &ucsc_hn_lib::RenaDataEmulator::getDataEnable)
   ;
}

ucsc_hn_lib::RenaDataEmulator::RenaDataEmulator (std::string file) {
   uint32_t bytes;
   uint32_t x;
   uint32_t count;
   uint64_t tmp64;
   uint32_t tmp32;
   uint16_t tmp16;
   uint8_t  tmp8;

   period_ = 1000;
   enable_ = false;
   runEnable_ = false;
   index_ = 0;
   frameCount_ = 0;

   int fd;
   char c;
   ris::FrameIterator dst;

   if ( (fd = ::open(file.c_str(),0)) == -1 ) {
        throw(rogue::GeneralError::create("RenaDataEmulator", "Failed to open data file: %s", file.c_str()));
   }

   for (x=0; x < 2000; x++ ) {
      bytes = 0;
      count = 0;
      frames_[x] = reqFrame(2000, true);
      frames_[x]->setPayload(2000);
      dst = frames_[x]->begin();

      // Add header
      tmp64 = 1;
      tmp64 += (0x2 << 4);
      tmp64 += (x << 8) & 0xFF00;
      toFrame(dst, 8, &tmp64);
      bytes += 8;

      while (bytes < 1500) {
         count = 0;

         // Search for c8 marker
         do {
            read(fd, &c, 1);
         } while ( c != 0xc8 );

         toFrame(dst, 1, &c);
         count += 1;
         bytes += 8;

         // Skip 2 bytes
         read(fd, &tmp16, 2);

         // Continue until we see 0xFF
         do {
            read(fd, &c, 1);
            toFrame(dst, 1, &c);
            count += 1;
            bytes += 1;
         } while (c != 0xFF);

         // Add tail
         tmp64 = count;
         tmp64 += (0x2 << 7);
         toFrame(dst, 8, &tmp64);
         bytes += 8;
      }
      frames_[x]->setPayload(bytes);
      frameCount_++;
   }
   close(fd);
}

void ucsc_hn_lib::RenaDataEmulator::setDataEnable(bool state) {
   enable_ = state;
}

bool ucsc_hn_lib::RenaDataEmulator::getDataEnable() {
   return enable_;
}

void ucsc_hn_lib::RenaDataEmulator::start() {
   if ( txThread_ == NULL ) {
      runEnable_ = true;
      txThread_ = new std::thread(&RenaDataEmulator::runThread, this);
   }
}

void ucsc_hn_lib::RenaDataEmulator::stop() {
   if ( txThread_ != NULL ) {
      runEnable_ = false;
      txThread_->join();
      delete txThread_;
      txThread_ = NULL;
   }
}

void ucsc_hn_lib::RenaDataEmulator::runThread() {

   while ( runEnable_ ) {

      if ( enable_ ) usleep(10);
      else{

         sendFrame(frames_[index_++]);
         usleep(period_);
      }
   }
}

