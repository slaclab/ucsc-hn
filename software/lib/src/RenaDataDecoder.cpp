#include <RenaDataDecoder.h>
#include <rogue/interfaces/stream/Master.h>
#include <rogue/interfaces/stream/Slave.h>
#include <rogue/interfaces/stream/Frame.h>
#include <rogue/interfaces/stream/FrameIterator.h>
#include <rogue/interfaces/stream/FrameAccessor.h>
#include <rogue/interfaces/stream/FrameLock.h>
#include <rogue/GilRelease.h>
#include <boost/python.hpp>

namespace ris = rogue::interfaces::stream;
namespace bp = boost::python;

ucsc_hn_lib::RenaDataDecoderPtr ucsc_hn_lib::RenaDataDecoder::create(uint8_t nodeId) {
   ucsc_hn_lib::RenaDataDecoderPtr r = std::make_shared<ucsc_hn_lib::RenaDataDecoder>(nodeId);
   return(r);
}

void ucsc_hn_lib::RenaDataDecoder::setup_python() {
   bp::class_<ucsc_hn_lib::RenaDataDecoder, ucsc_hn_lib::RenaDataDecoderPtr, bp::bases<ris::Master,ris::Slave>, boost::noncopyable >("RenaDataDecoder",bp::init<uint8_t>())
      .def("setChannelPolarity", &ucsc_hn_lib::RenaDataDecoder::setChannelPolarity)
      .def("getChannelPolarity", &ucsc_hn_lib::RenaDataDecoder::getChannelPolarity)
      .def("countReset",         &ucsc_hn_lib::RenaDataDecoder::countReset)
      .def("getRxSampleCount",   &ucsc_hn_lib::RenaDataDecoder::getRxSampleCount)
      .def("getRxDropCount",     &ucsc_hn_lib::RenaDataDecoder::getRxDropCount)
      .def("getRxFrameCount",    &ucsc_hn_lib::RenaDataDecoder::getRxFrameCount)
      .def("getRxByteCount",     &ucsc_hn_lib::RenaDataDecoder::getRxByteCount)
   ;
}

ucsc_hn_lib::RenaDataDecoder::RenaDataDecoder (uint8_t nodeId) {
   uint32_t f,r,c,i,j;
   unsigned char crc;

   countReset();
   nodeId_ = nodeId;

   for (f=0; f < 31; f++)
      for (r=0; r < 2; r++)
         for (c=0; c < 36; c++)
            polarity_[f][r][c] = false;

   for (i=0; i<256; i++) {
      crc = i;
      for (j=0; j<8; j++) crc = (crc << 1) ^ ((crc & 0x80) ? 0x07 : 0);
      crc8_table_[i] = crc;
   }
}

void ucsc_hn_lib::RenaDataDecoder::countReset () {
   rxFrameCount_ = 0;
   rxSampleCount_ = 0;
   rxDropCount_ = 0;
   rxByteCount_ = 0;
}

void ucsc_hn_lib::RenaDataDecoder::setChannelPolarity(uint8_t fpga, uint8_t rena, uint8_t chan, uint8_t state) {
   if ( fpga > 30 || rena > 1 || chan > 35 ) return;
   polarity_[fpga][rena][chan] = state;
}

uint8_t ucsc_hn_lib::RenaDataDecoder::getChannelPolarity(uint8_t fpga, uint8_t rena, uint8_t chan) {
   if ( fpga > 30 || rena > 1 || chan > 35 ) return 0;
   return polarity_[fpga][rena][chan];
}

uint32_t ucsc_hn_lib::RenaDataDecoder::getRxFrameCount() {
   return rxFrameCount_;
}

uint32_t ucsc_hn_lib::RenaDataDecoder::getRxSampleCount() {
   return rxSampleCount_;
}

uint32_t ucsc_hn_lib::RenaDataDecoder::getRxDropCount() {
   return rxDropCount_;
}

uint32_t ucsc_hn_lib::RenaDataDecoder::getRxByteCount() {
   return rxByteCount_;
}

void ucsc_hn_lib::RenaDataDecoder::acceptFrame ( ris::FramePtr frame ) {
   ris::FramePtr nFrame;
   ris::FrameIterator src;
   ris::FrameIterator dst;
   ris::FrameIterator tmp;

   bool readMode;
   bool readPHA;
   bool readUV;

   uint64_t timeStamp;
   uint64_t fastTriggerList;
   uint64_t slowTriggerList;
   uint32_t x;
   uint32_t i;
   uint32_t buffIdx;
   uint32_t fastCount;
   uint32_t slowCount;
   uint64_t bit;

   uint8_t renaId;
   uint8_t fpgaId;
   uint8_t polarity;

   uint16_t phaData;
   uint16_t uData;
   uint16_t vData;

   uint8_t gotCrc;
   uint8_t expCrc;
   uint8_t zero;
   uint8_t one;

   rogue::GilRelease noGil;
   ris::FrameLockPtr lock = frame->lock();

   // Empty frame
   if ( frame->getPayload() < 1 ) return;

   //printf("Got frame size: %i\n",frame->getPayload());

   // Ensure frame is in a sing buffer
   ensureSingleBuffer(frame,true);

   // Frame iterator and accessor
   src = frame->begin();
   ris::FrameAccessor<uint8_t> srcData(src,frame->getPayload());

   // Forward non data types
   // 0xC8 = AND Mode
   if ( srcData[0] == 0xC8 ) {
      readMode = false;

      // Check min length
      if ( frame->getPayload() < 14 ) return;
   }

   // 0xC9 = OR  Mode
   else if ( srcData[0] == 0xC9 ) {
      readMode = true;

      // Check min length
      if ( frame->getPayload() < 20 ) return;
   }

   // Other data, forward on with updated dest
   else {
      frame->setChannel(1);
      lock->unlock();
      sendFrame(frame);
      return;
   }

   // Make a copy of the frame in the raw format, add source and dest node IDs
   nFrame = reqFrame(frame->getPayload()+4,true);
   nFrame->setPayload(frame->getPayload()+4);
   nFrame->setChannel(3);
   tmp = frame->begin();
   dst = nFrame->begin();

   // Add a one to the start of the record
   one = 1;
   toFrame(dst,1,&one);

   // Copy one bytes
   copyFrame(tmp,1,dst);

   // Set src byte
   toFrame(dst,1,&nodeId_);

   // Set dest byte
   zero = 0;
   toFrame(dst,1,&zero);

   // Copy the rest of the frame
   copyFrame(tmp,frame->getPayload()-1,dst);

   // Add a zero
   zero = 0;
   toFrame(dst,1,&zero);

   // Send the frame copy
   sendFrame(nFrame);
   nFrame.reset();

   // Make sure length long enough for CRC check
   if ( frame->getPayload() < 3 ) {
      rxDropCount_++;
      return;
   }

   // Received CRC
   gotCrc = srcData[frame->getPayload()-3] << 4 | srcData[frame->getPayload()-2];

   // Computed CRC
   expCrc = 0;
   for (x=0; x < frame->getPayload()-3; x++) expCrc = crc8_table_[expCrc ^ srcData[x]];

   // Check CRC
   if ( expCrc != gotCrc ) {
      rxDropCount_++;
      return;
   }

   // First byte is rena id and board address
   renaId = srcData[1] & 0x1;
   fpgaId = (srcData[1] >> 1) & 0x3F;

   // Bytes 2 - 7 are the timesamp, 42 bits total
   timeStamp = 0;
   for (x=2; x < 8; x++) {
      timeStamp = timeStamp << 7;
      timeStamp |= srcData[x];
   }

   // Bytes 8 - 13 are the fast trigger list for channels 35-0
   fastTriggerList = 0;
   for (x=8; x < 14; x++) {
      fastTriggerList = fastTriggerList << 6;
      fastTriggerList |= srcData[x];
   }

   buffIdx = 14;

   // Bytes 14 - 19 are the slow trigger list for channels 35-0
   slowTriggerList = 0;

   // OR Mode
   if (readMode) {
      for (x=14; x < 20; x++) {
         slowTriggerList = slowTriggerList << 6;
         slowTriggerList |= srcData[x];
      }

      buffIdx = 20;
   }

   // Count the number of fast triggers
   fastCount = 0;
   i = 1;
   for (x=0; x < 36; x++) {
      if ((i & fastTriggerList) != 0 ) fastCount++;
      i = i << 1;
   }

   // Count the number of slow triggers
   slowCount = 0;

   // OR Mode
   if ( readMode ) {
      i = 1;
      for (x=0; x < 36; x++) {
         if ((i & slowTriggerList) != 0 ) slowCount++;
         i = i << 1;
      }

      // Check or mode length
      if ( frame->getPayload() != (23 + (fastCount * 4) + (slowCount *2))) {
         rxDropCount_++;
         return;
      }
   }

   // Check and mode length
   else {
      if ( frame->getPayload() != (17 + (fastCount * 6))) {
         rxDropCount_++;
         return;
      }
   }
   rxFrameCount_++;
   rxByteCount_ += frame->getPayload();

   // Extract data PHA, U and V ADC values for each channel
   bit = 1;
   for ( x=0; x < 36; x++ ) {
      readPHA = false;
      readUV  = false;

      // OR Mode
      if ( readMode ) {
          if ((bit & slowTriggerList) != 0) readPHA = true;
          if ((bit & fastTriggerList) != 0) readUV  = true;
      }

      // AND Mode
      else {
         if ((bit & fastTriggerList) != 0) {
            readPHA = true;
            readUV  = true;
         }
      }

      // Something is being read for this channel
      if ( readPHA or readUV ) {
         rxSampleCount_++;

         // PHA is two bytes
         if ( readPHA ) phaData = srcData[buffIdx++] << 6 | srcData[buffIdx++];
         else phaData = 0;

         // U & V Data
         if (readUV) {
            uData = srcData[buffIdx++] << 6 | srcData[buffIdx++];
            vData = srcData[buffIdx++] << 6 | srcData[buffIdx++];
         }
         else {
            uData = 0;
            vData = 0;
         }

         // Create outbound frame
         nFrame = reqFrame(23,true);
         nFrame->setPayload(23);
         nFrame->setChannel(2);
         dst = nFrame->begin();

         // Lookup polarity
         polarity = getChannelPolarity(fpgaId,renaId,x);

         // Start frame data
         toFrame(dst,1,&x); // Channel ID
         toFrame(dst,1,&fpgaId);
         toFrame(dst,1,&renaId);
         toFrame(dst,1,&nodeId_);
         toFrame(dst,1,&polarity);
         toFrame(dst,8,&timeStamp);
         toFrame(dst,4,&rxFrameCount_);
         toFrame(dst,2,&phaData);
         toFrame(dst,2,&uData);
         toFrame(dst,2,&vData);

         sendFrame(nFrame);
         nFrame.reset();
      }

      bit = bit << 1;
   }
}

