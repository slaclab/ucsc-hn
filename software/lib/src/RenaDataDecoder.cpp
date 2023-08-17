#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <RenaDataDecoder.h>
#include <rogue/interfaces/stream/Master.h>
#include <rogue/interfaces/stream/Slave.h>
#include <rogue/interfaces/stream/Frame.h>
#include <rogue/interfaces/stream/FrameIterator.h>
#include <rogue/interfaces/stream/FrameAccessor.h>
#include <rogue/interfaces/stream/FrameLock.h>
#include <rogue/GilRelease.h>
#include <rogue/protocols/batcher/CoreV1.h>
#include <rogue/protocols/batcher/Data.h>
#include <boost/python.hpp>

namespace ris = rogue::interfaces::stream;
namespace bp = boost::python;
namespace rpb = rogue::protocols::batcher;

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
      .def("getRxCount",         &ucsc_hn_lib::RenaDataDecoder::getRxCount)
      .def("getRxTotal",         &ucsc_hn_lib::RenaDataDecoder::getRxTotal)
      .def("getDecodeEnable",    &ucsc_hn_lib::RenaDataDecoder::getDecodeEnable)
      .def("setDecodeEnable",    &ucsc_hn_lib::RenaDataDecoder::setDecodeEnable)
   ;
}

ucsc_hn_lib::RenaDataDecoder::RenaDataDecoder (uint8_t nodeId) {
   uint32_t f,r,c,i,j;
   unsigned char crc;

   countReset();
   nodeId_ = nodeId;
   decodeEn_ = 1;

   for (f=0; f < 31; f++)
      for (r=0; r < 2; r++)
         for (c=0; c < 36; c++)
            polarity_[f][r][c] = false;

   for (i=0; i<256; i++) {
      crc = i;
      for (j=0; j<8; j++) crc = (crc << 1) ^ ((crc & 0x80) ? 0x07 : 0);
      crc8_table_[i] = crc;
   }

   dlog_ = rogue::Logging::create("RenaDataDecoder");

   // Fixed size buffer pool
   setFixedSize(4096);
   setPoolSize(2500);
}

void ucsc_hn_lib::RenaDataDecoder::countReset () {
   uint32_t f,r,c,i,j;

   rxFrameCount_ = 0;
   rxSampleCount_ = 0;
   rxDropCount_ = 0;
   rxByteCount_ = 0;

   for (f=0; f < 31; f++) rxCount_[f] = 0;
   for (f=0; f < 31; f++) rxTotal_[f] = 0;

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

uint32_t ucsc_hn_lib::RenaDataDecoder::getRxCount(uint8_t fpga) {
   if ( fpga > 30 ) return 0;
   return rxCount_[fpga];
}

uint32_t ucsc_hn_lib::RenaDataDecoder::getRxTotal(uint8_t fpga) {
   if ( fpga > 30 ) return 0;
   return rxTotal_[fpga];
}

void ucsc_hn_lib::RenaDataDecoder::setDecodeEnable(uint32_t enable) {
   decodeEn_ = enable;
}

uint32_t ucsc_hn_lib::RenaDataDecoder::getDecodeEnable() {
   return decodeEn_;
}

void ucsc_hn_lib::RenaDataDecoder::sendDiag ( rpb::DataPtr data ) {
   ris::FrameIterator src;
   ris::FrameIterator dst;
   ris::FramePtr nFrame;

   nFrame = reqFrame(data->size(), true);
   nFrame->setPayload(data->size());

   dst = nFrame->begin();
   src = data->begin();
   ris::copyFrame(src, data->size(), dst);

   // Set flags
   nFrame->setFirstUser(data->fUser());
   nFrame->setLastUser(data->lUser());
   nFrame->setChannel(1);

   sendFrame(nFrame);
}


void ucsc_hn_lib::RenaDataDecoder::acceptFrame ( ris::FramePtr frame ) {
   ris::FramePtr rFrame;
   ris::FramePtr dFrame;
   ris::FrameIterator src;
   ris::FrameIterator tmp;
   ris::FrameIterator rPtr;
   ris::FrameIterator dPtr;
   ris::FrameIterator cPtr;
   rpb::CoreV1 core;
   rpb::DataPtr data;

   uint32_t rSize;
   uint32_t dSize;

   bool readMode;
   bool readPHA;
   bool readUV;
   uint32_t doDecode;

   uint64_t timeStamp;
   uint64_t fastTriggerList;
   uint64_t slowTriggerList;
   uint32_t fc;
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
   uint8_t chanCount;

   doDecode = decodeEn_;

   rogue::GilRelease noGil;
   ris::FrameLockPtr lock = frame->lock();

   // Ensure frame is in a sing buffer
   if ( ! ensureSingleBuffer(frame,false) ) {
      dlog_->error("Received data not in a single buffer");
      return;
   }

   // Generate two new outgoing frames
   rFrame = acceptReq(4000,true);
   rFrame->setPayload(4000);
   rFrame->setChannel(2);
   rPtr = rFrame->begin();
   rSize = 0;

   if ( doDecode ) {
      dFrame = acceptReq(4000,true);
      dFrame->setPayload(4000);
      dFrame->setChannel(3);
      dPtr = dFrame->begin();
      dSize = 0;
   }
   core.processFrame(frame);

   for (fc = 0; fc < core.count(); fc++) {
       data = core.record(fc);

       // Frame iterator and accessor
       src = data->begin();
       ris::FrameAccessor<uint8_t> srcData(src,data->size());

       // Forward non data types
       // 0xC8 = AND Mode
       if ( srcData[0] == 0xC8 ) {
          readMode = false;

          // Check min length
          if ( frame->getPayload() < 14 ) continue;
       }

       // 0xC9 = OR  Mode
       else if ( srcData[0] == 0xC9 ) {
          readMode = true;

          // Check min length
          if ( frame->getPayload() < 20 ) continue;
       }

       // Forward split message
       else {
          sendDiag (data);
          continue;
       }

       // Update counters
       renaId = srcData[1] & 0x1;
       fpgaId = (srcData[1] >> 1) & 0x3F;

       if ( fpgaId < 31 ) {
          rxCount_[fpgaId]++;
          rxTotal_[fpgaId] += frame->getPayload();
       }

       ////////////////////////////////////////////////////////////////////////////
       // Make a copy of the frame in the raw format, add source and dest node IDs
       tmp = data->begin();

       // Add a one to the start of the record
       one = 1;
       toFrame(rPtr,1,&one);

       // Copy one byte
       copyFrame(tmp,1,rPtr);

       // Set src byte
       toFrame(rPtr,1,&nodeId_);

       // Set dest byte
       zero = 0;
       toFrame(rPtr,1,&zero);

       // Copy the rest of the frame
       copyFrame(tmp,data->size()-1,rPtr);

       // Add a zero
       zero = 0;
       toFrame(rPtr,1,&zero);

       // Update size
       rSize += data->size() + 4;

       ////////////////////////////////////////////////////////////////////////////
       if ( doDecode == 0 ) continue;

       // Make sure length long enough for CRC check
       if ( data->size() < 3 ) {
          rxDropCount_++;
          continue;
       }

       // Received CRC
       gotCrc = srcData[data->size()-3] << 4 | srcData[data->size()-2];

       // Computed CRC
       expCrc = 0;
       for (x=0; x < data->size()-3; x++) expCrc = crc8_table_[expCrc ^ srcData[x]];

       // Check CRC
       if ( expCrc != gotCrc ) {
          rxDropCount_++;
          continue;
       }

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
          if ( data->size() != (23 + (fastCount * 4) + (slowCount *2))) {
             rxDropCount_++;
             continue;
          }
       }

       // Check and mode length
       else {
          if ( data->size() != (17 + (fastCount * 6))) {
             rxDropCount_++;
             continue;
          }
       }
       rxFrameCount_++;
       rxByteCount_ += data->size();

       // Update outbound frame
       toFrame(dPtr,1,&fpgaId);
       toFrame(dPtr,1,&renaId);
       toFrame(dPtr,1,&nodeId_);
       toFrame(dPtr,8,&timeStamp);
       toFrame(dPtr,4,&rxFrameCount_);

       // Count gets updated later
       chanCount = 0;
       cPtr = dPtr;
       toFrame(dPtr,1,&chanCount);
       dSize += 16;

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

             // Lookup polarity
             polarity = getChannelPolarity(fpgaId,renaId,x);

             // Start frame data
             toFrame(dPtr,1,&x); // Channel ID
             toFrame(dPtr,1,&polarity);
             toFrame(dPtr,2,&phaData);
             toFrame(dPtr,2,&uData);
             toFrame(dPtr,2,&vData);
             dSize += 8;
             chanCount++;
          }

          bit = bit << 1;
       }

       // Update counter
       toFrame(cPtr,1,&chanCount);
    }

    rFrame->setPayload(rSize);
    sendFrame(rFrame);

    if ( doDecode ) {
       dFrame->setPayload(dSize);
       sendFrame(dFrame);
    }
}

