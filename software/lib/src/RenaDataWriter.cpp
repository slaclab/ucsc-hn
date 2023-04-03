#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <RenaDataWriter.h>
#include <rogue/utilities/fileio/StreamWriter.h>
#include <rogue/interfaces/stream/Frame.h>
#include <rogue/interfaces/stream/FrameLock.h>
#include <rogue/interfaces/stream/FrameIterator.h>
#include <rogue/GeneralError.h>
#include <stdint.h>
#include <rogue/GilRelease.h>

namespace ris = rogue::interfaces::stream;
namespace ruf = rogue::utilities::fileio;

#include <boost/python.hpp>
namespace bp = boost::python;


//! Class creation
ucsc_hn_lib::RenaDataWriterPtr ucsc_hn_lib::RenaDataWriter::create () {
   ucsc_hn_lib::RenaDataWriterPtr r = std::make_shared<ucsc_hn_lib::RenaDataWriter>();
   return(r);
}

void ucsc_hn_lib::RenaDataWriter::setup_python() {
   bp::class_<ucsc_hn_lib::RenaDataWriter, ucsc_hn_lib::RenaDataWriterPtr, bp::bases<ruf::StreamWriter>, boost::noncopyable >("RenaDataWriter",bp::init<>());
   bp::implicitly_convertible<ucsc_hn_lib::RenaDataWriterPtr, ruf::StreamWriterPtr>();
}

ucsc_hn_lib::RenaDataWriter::RenaDataWriter() : StreamWriter() { }

ucsc_hn_lib::RenaDataWriter::~RenaDataWriter() {
   this->close();
}

void ucsc_hn_lib::RenaDataWriter::writeFile ( uint8_t channel, std::shared_ptr<rogue::interfaces::stream::Frame> frame) {
   ris::FrameIterator src;

   uint32_t value;
   uint32_t size;
   uint8_t  ch;
   uint8_t  fpgaId;
   uint8_t  renaId;
   uint8_t  nodeId;
   uint8_t  polarity;
   uint64_t timeStamp;
   uint32_t frameId;
   uint16_t phaData;
   uint16_t uData;
   uint16_t vData;
   uint32_t chanCount;

   char buffer[200];

   if ( frame->getPayload() == 0 ) return;

   rogue::GilRelease noGil;
   std::unique_lock<std::mutex> lock(mtx_);

   // Bad frame size
   if ( (frame->getPayload() - 15) % 8 != 0 ) return;

   chanCount = (frame->getPayload() - 15) / 8;

   if ( fd_ >= 0 ) {

      src = frame->begin();

      fromFrame(src,1,&fpgaId);
      fromFrame(src,1,&renaId);
      fromFrame(src,1,&nodeId);
      fromFrame(src,8,&timeStamp);
      fromFrame(src,4,&frameId);

      while ( chanCount > 0 ) {

         fromFrame(src,1,&ch);
         fromFrame(src,1,&polarity);
         fromFrame(src,2,&phaData);
         fromFrame(src,2,&uData);
         fromFrame(src,2,&vData);

         sprintf(buffer, "%i %i %i %i %i %i %i %i %li\n",nodeId,fpgaId,renaId,ch,polarity,phaData,uData,vData,timeStamp);

         checkSize(strlen(buffer));
         intWrite(buffer,strlen(buffer));
         --chanCount;
      }

      frameCount_ ++;
      cond_.notify_all();
   }
}

