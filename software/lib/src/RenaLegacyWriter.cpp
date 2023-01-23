#include <inttypes.h>
#include <RenaLegacyWriter.h>
#include <rogue/utilities/fileio/StreamWriter.h>
#include <rogue/interfaces/stream/Frame.h>
#include <rogue/interfaces/stream/FrameLock.h>
#include <rogue/interfaces/stream/FrameIterator.h>
#include <rogue/interfaces/stream/Buffer.h>
#include <rogue/GeneralError.h>
#include <stdint.h>
#include <rogue/GilRelease.h>

namespace ris = rogue::interfaces::stream;
namespace ruf = rogue::utilities::fileio;

#include <boost/python.hpp>
namespace bp = boost::python;


//! Class creation
ucsc_hn_lib::RenaLegacyWriterPtr ucsc_hn_lib::RenaLegacyWriter::create () {
   ucsc_hn_lib::RenaLegacyWriterPtr r = std::make_shared<ucsc_hn_lib::RenaLegacyWriter>();
   return(r);
}

void ucsc_hn_lib::RenaLegacyWriter::setup_python() {
   bp::class_<ucsc_hn_lib::RenaLegacyWriter, ucsc_hn_lib::RenaLegacyWriterPtr, bp::bases<ruf::StreamWriter>, boost::noncopyable >("RenaLegacyWriter",bp::init<>());
   bp::implicitly_convertible<ucsc_hn_lib::RenaLegacyWriterPtr, ruf::StreamWriterPtr>();
}

ucsc_hn_lib::RenaLegacyWriter::RenaLegacyWriter() : StreamWriter() { }

ucsc_hn_lib::RenaLegacyWriter::~RenaLegacyWriter() {
   this->close();
}

void ucsc_hn_lib::RenaLegacyWriter::writeFile ( uint8_t channel, std::shared_ptr<rogue::interfaces::stream::Frame> frame) {
   ris::Frame::BufferIterator it;

   uint32_t size;

   if ( frame->getPayload() == 0 ) return;

   rogue::GilRelease noGil;
   std::unique_lock<std::mutex> lock(mtx_);

   if ( fd_ >= 0 ) {

      // Written size has extra 4 bytes
      size = frame->getPayload();

      // Check file size
      checkSize(size);

      // Write buffers
      for (it=frame->beginBuffer(); it != frame->endBuffer(); ++it)
         intWrite((*it)->begin(),(*it)->getPayload());

      // Update counters
      frameCount_ ++;
      cond_.notify_all();
   }
}

