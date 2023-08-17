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
      .def("setBurstSize",       &ucsc_hn_lib::RenaDataEmulator::setBurstSize)
      .def("getBurstSize",       &ucsc_hn_lib::RenaDataEmulator::getBurstSize)
      .def("getCount",           &ucsc_hn_lib::RenaDataEmulator::getCount)
   ;
}

ucsc_hn_lib::RenaDataEmulator::RenaDataEmulator (std::string file) {
   period_ = 1000;
   burstSize_ = 50; // 16
   sourceCnt_ = 2000;
   enable_ = false;
   runEnable_ = false;
   index_ = 0;
   frameCount_ = 0;
   file_ = file;
}

void ucsc_hn_lib::RenaDataEmulator::loadData() {
   uint32_t bytes;
   uint32_t x;
   uint32_t count;
   uint32_t tmp32;
   uint16_t tmp16;
   uint8_t  tmp8;
   uint32_t rtotal;
   uint32_t rem;

   int fd;
   uint8_t c;
   ris::FrameIterator dst;

   printf("Loading data from %s\n",file_.c_str());

   if ( (fd = ::open(file_.c_str(),0)) == -1 ) {
        throw(rogue::GeneralError::create("RenaDataEmulator", "Failed to open data file: %s", file_.c_str()));
   }

   rtotal = 0;
   for (x=0; x < sourceCnt_; x++ ) {
      bytes = 0;
      count = 0;
      frames_[x] = reqFrame(2000, true);
      frames_[x]->setPayload(2000);
      dst = frames_[x]->begin();

      // Add header
      tmp8 = 0x21;
      toFrame(dst, 1, &tmp8);
      tmp8 = x;
      toFrame(dst, 1, &tmp8);
      tmp8 = 0;
      toFrame(dst, 1, &tmp8);
      toFrame(dst, 1, &tmp8);
      tmp32 =0;
      toFrame(dst, 4, &tmp32);
      bytes += 8;

      while (bytes < 1500) {
         count = 0;

         // Search for c8 marker
         do {
            read(fd, &c, 1);
            rtotal++;
         } while ( c != 0xc8 );

         toFrame(dst, 1, &c);
         count++;
         bytes++;

         // Skip 2 bytes
         read(fd, &tmp16, 2);
         rtotal += 2;

         // Continue until we see 0xFF
         do {
            read(fd, &c, 1);
            toFrame(dst, 1, &c);
            count += 1;
            bytes += 1;
            rtotal++;
         } while (c != 0xFF);

         // Now we need to pad out the the width of 64 bits
         rem = count;
         tmp8 = 0;
         while ( rem % 8 != 0 ) {
            toFrame(dst, 1, &tmp8);
            bytes++;
            rem++;
         }

         // Add tail
         tmp32 = count;
         toFrame(dst, 4, &tmp32);
         tmp8 = 0;
         toFrame(dst, 1, &tmp8); // tdest
         toFrame(dst, 1, &tmp8); // tuser first
         toFrame(dst, 1, &tmp8); // tuser lastt
         tmp8 = 0x2;
         toFrame(dst, 1, &tmp8); // width
         bytes += 8;
      }
      frames_[x]->setPayload(bytes);
   }
   printf("Loaded %i bytes into %i frames\n",rtotal,x);
   close(fd);
}

void ucsc_hn_lib::RenaDataEmulator::setDataEnable(bool state) {
   enable_ = state;
}

bool ucsc_hn_lib::RenaDataEmulator::getDataEnable() {
   return enable_;
}


void ucsc_hn_lib::RenaDataEmulator::setBurstSize(uint32_t size) {
   if ( size < 200 ) burstSize_ = size;
}

uint32_t ucsc_hn_lib::RenaDataEmulator::getBurstSize() {
   return burstSize_;
}

void ucsc_hn_lib::RenaDataEmulator::start() {
   loadData();
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

uint32_t ucsc_hn_lib::RenaDataEmulator::getCount() {
   return frameCount_;
}

void ucsc_hn_lib::RenaDataEmulator::runThread() {
   uint32_t x;

   while ( runEnable_ ) {
      if ( enable_ ) {
         for (x=0; x < burstSize_; x++) {
            sendFrame(frames_[index_++]);
            if ( index_ == sourceCnt_ ) index_ = 0;
            frameCount_;
         }
      }
      usleep(period_);
   }
}

void ucsc_hn_lib::RenaDataEmulator::countReset() {
   frameCount_ = 0;
}

