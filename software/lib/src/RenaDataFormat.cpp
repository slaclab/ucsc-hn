#define __STDC_FORMAT_MACROS
#include <RenaDataFormat.h>

ucsc_hn_lib::RenaDataFormatPtr ucsc_hn_lib::RenaDataFormat::create(uint8_t nodeId) {
   ucsc_hn_lib::RenaDataFormatPtr r = std::make_shared<ucsc_hn_lib::RenaDataFormat>(nodeId);
   return(r);
}

ucsc_hn_lib::RenaDataFormat::RenaDataFormat (uint8_t nodeId) {
   uint32_t f,r,c,i,j;
   unsigned char crc;

   countReset();
   nodeId_ = nodeId;
   count_ = 0;
   rxCount_ = 0;

   for (i=0; i<256; i++) {
      crc = i;
      for (j=0; j<8; j++) crc = (crc << 1) ^ ((crc & 0x80) ? 0x07 : 0);
      crc8_table_[i] = crc;
   }

   // Generate polarity map
   for (f=0; f < 31; f++) {
      for (r=0; r < 2; r++) {
         for (c=0; c < 36; c++) {
            polarityMap_[f][r][c] = true;

            // Anode board
            if ( f % 2 == 0 ) {

               // Channels 25 - 28 are negative
               if ( c >= 25 && c <= 28 ) polarityMap_[f][r][c] = false;
            }

            // Cathode board
            else {

               // Rena 0, Channels 4 - 7 are negative
               if ( r == 0 && c >= 4 && c <= 7 ) polarityMap_[f][r][c] = false;

               // Rena 1, Channels 7 - 10 are negative
               if ( r == 1 && c >= 7 && c <= 10 ) polarityMap_[f][r][c] = false;
            }
         }
      }
   }
}

void ucsc_hn_lib::RenaDataFormat::countReset () {
   rxByteCount_ = 0;
   rxFrameCount_ = 0;
   rxDropCount_ = 0;
   rxSampleCount_ = 0;
}

uint32_t ucsc_hn_lib::RenaDataFormat::getByteCount() {
   return rxByteCount_;
}

uint32_t ucsc_hn_lib::RenaDataFormat::getFrameCount() {
   return rxFrameCount_;
}

uint32_t ucsc_hn_lib::RenaDataFormat::getDropCount() {
   return rxDropCount_;
}

uint32_t ucsc_hn_lib::RenaDataFormat::getSampleCount() {
   return rxSampleCount_;
}

uint8_t  ucsc_hn_lib::RenaDataFormat::getNodeId() {
   return nodeId_;
}

uint8_t  ucsc_hn_lib::RenaDataFormat::getRenaId() {
   return renaId_;
}

uint8_t  ucsc_hn_lib::RenaDataFormat::getFpgaId() {
   return fpgaId_;
}

uint64_t ucsc_hn_lib::RenaDataFormat::getTimeStamp() {
   return timeStamp_;
}

uint8_t  ucsc_hn_lib::RenaDataFormat::getCount() {
   return count_;
}

uint8_t ucsc_hn_lib::RenaDataFormat::getChannel(uint8_t x) {
   if ( x < count_ ) return channel_[x];
   else return 0;
}

uint8_t ucsc_hn_lib::RenaDataFormat::getPolarity(uint8_t x) {
   if ( x < count_ ) return polarity_[x];
   else return 0;
}

uint8_t ucsc_hn_lib::RenaDataFormat::getPhData(uint8_t x) {
   if ( x < count_ ) return phData_[x];
   else return 0;
}

uint8_t ucsc_hn_lib::RenaDataFormat::getUData(uint8_t x) {
   if ( x < count_ ) return uData_[x];
   else return 0;
}

uint8_t ucsc_hn_lib::RenaDataFormat::getVData(uint8_t x) {
   if ( x < count_ ) return vData_[x];
   else return 0;
}

char * ucsc_hn_lib::RenaDataFormat::getStrData() {
   return strData_;
}

// Take an arbitrary chunk of data and extra rena frames. Returns true if data
// was found. Update pointer position and size on each processed value
bool ucsc_hn_lib::RenaDataFormat::processChunk(uint8_t &*data, uint32_t &size) {
   bool ret = false;
   uint8_t gotCrc;

   // Process chunk data
   while ( size > 0 ) {
      rxBuffer_[rxCount_] = *data;
      ++data;
      --size;

      // Look for first markers
      if ( rxCount_ == 0 ) {
         if ( *data == 0xC8 || *data == 0xC9 ) rxCount_ = 1;
         calcCrc_ = 0;
      }

      // In Frame, look for end marker
      else {
         ++rxCount_;

         // Found end marker, process frame
         if ( *data == 0xFF ) {
            if ( rxCount > 6 ) {
               gotCrc = data[rxCount_-3] << 4 | data[rxCount_-2];
               if ( expCrc == gotCrc ) ret = frameRx(rxBuffer_, rxCount_);
            }

            if ( ! ret ) rxDropCount_++;
            rxCount_ = 0;
            break;
         }

         // Don't compute the first 3 and last 3 values
         else if ( rxCount_ > 6 ) calcCrc_ = crc8_table_[calcCrc_ ^ data[rxCount_-4]];
      }
   }
   return ret;
}

// Process a frame of given size where the first charactor is 0xC8 or 0xc9 and the last
// charactor is 0xFF. Assume CRC is already been checked.
bool ucsc_hn_lib::RenaDataFormat::frameRx(uint8_t *data, uint32_t size) {
   uint32_t x;
   uint32_t buffIdx;
   uint8_t gotCrc;
   uint8_t expCrc;

   bool readMode;
   bool readPHA;
   bool readUV;

   uint64_t fastTriggerList;
   uint64_t slowTriggerList;
   uint32_t i;
   uint32_t fastCount;
   uint32_t slowCount;
   uint64_t bit;
   uint8_t ch;

   rxByteCount_ += size;
   count_ = 0;
   strData_[0] = 0;

   // 0xC8 = AND Mode
   if ( data[0] == 0xC8 ) {
      readMode = false;

      // Check min size
      if ( size < 14 ) return false;
   }

   // 0xC9 = OR  Mode
   else if ( data[0] == 0xC9 ) {
      readMode = true;

      // Check min size
      if ( size < 20 ) return false;
   }

   // Something is wrong
   else return false;

   // Get renaId and FPGA Id
   renaId_ = data[1] & 0x1;
   fpgaId_ = (data[1] >> 1) & 0x3F;

   // Bytes 2 - 7 are the timesamp, 42 bits total
   timeStamp_ = 0;
   for (x=2; x < 8; x++) {
      timeStamp_ = timeStamp_ << 7;
      timeStamp_ |= data[x];
   }

   // Bytes 8 - 13 are the fast trigger list for channels 35-0
   fastTriggerList = 0;
   for (x=8; x < 14; x++) {
      fastTriggerList = fastTriggerList << 6;
      fastTriggerList |= data[x];
   }

   buffIdx = 14;

   // Bytes 14 - 19 are the slow trigger list for channels 35-0
   slowTriggerList = 0;

   // OR Mode
   if (readMode) {
      for (x=14; x < 20; x++) {
         slowTriggerList = slowTriggerList << 6;
         slowTriggerList |= data[x];
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
      if ( size != (23 + (fastCount * 4) + (slowCount *2))) return false;
   }

   // Check and mode length
   else if ( size != (17 + (fastCount * 6))) return false;

   // Valid frame received
   ++rxFrameCount_++;

   // Extract data PHA, U and V ADC values for each channel
   bit = 1;
   for ( ch=0; ch < 36; ch++ ) {
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
         if ( readPHA ) phaData_[count_] = data[buffIdx++] << 6 | data[buffIdx++];
         else phaData_[count_] = 0;

         // U & V Data
         if (readUV) {
            uData_[count_] = data[buffIdx++] << 6 | data[buffIdx++];
            vData_[count_] = data[buffIdx++] << 6 | data[buffIdx++];
         }
         else {
            uData_[count_] = 0;
            vData_[count_] = 0;
         }

         // Lookup polarity
         polarity_[count_] = polarityMap_[fpgaId_][renaId_][ch];
         channel_[count_] = ch;

         // Generate string data
         sprintf(&(strData_[strlen(strData)]), "%u %u %u %u %u %u %u %u %lu\n",
               noteId_, fpgaId_, renaId_, channel_[count_], polarity_[count_],
               phData_[count_], uData_[count_], vData_[count_], timestamp_);

         ++count_;
      }
      bit = bit << 1;
   }
   return true;
}

