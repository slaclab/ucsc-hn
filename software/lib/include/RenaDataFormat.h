
#ifndef __RENA_DATA_FORMAT_H__
#define __RENA_DATA_FORMAT_H__
#include <stdint.h>
#include <memory>
#include <cstring>

namespace ucsc_hn_lib {

   class RenaDataFormat {

         // CRC Table
         uint8_t crc8_table_[256];

         // Static configuration
         uint8_t nodeId_;

         // Dynamic per frame
         uint8_t  renaId_;
         uint8_t  fpgaId_;
         uint64_t timeStamp_;
         uint8_t  count_;

         // Up to 36 channels of data per frame
         uint8_t channel_[36];
         uint8_t polarity_[36];
         uint16_t phData_[36];
         uint16_t uData_[36];
         uint16_t vData_[36];

         // Frame String
         char strData_[10000];

         // Polarity Map
         uint8_t polarityMap_[31][2][36];

         // Counters
         uint64_t rxByteCount_;
         uint32_t rxFrameCount_;
         uint32_t rxDropCount_;
         uint32_t rxSampleCount_;
         uint64_t fileSize_;
         uint64_t fileRead_;

         // File tracking
         int fin_;
         uint8_t finBuff_[8192];
         uint8_t *finPtr_;
         uint32_t finLength_;

         // Pending rx
         uint8_t rxBuffer_[8192];
         uint8_t rxCount_;
         uint8_t calcCrc_;

      public:

         static std::shared_ptr<ucsc_hn_lib::RenaDataFormat> create();

         RenaDataFormat ();

         static void setup_python();

         void countReset();
         uint64_t getByteCount();
         uint32_t getFrameCount();
         uint32_t getDropCount();
         uint32_t getSampleCount();
         uint64_t getFileSize();
         uint64_t getFileRead();

         uint8_t  getNodeId();
         uint8_t  getRenaId();
         uint8_t  getFpgaId();
         uint64_t getTimeStamp();
         uint8_t  getCount();

         uint8_t getChannel(uint8_t x);
         uint8_t getPolarity(uint8_t x);
         uint16_t getPhData(uint8_t x);
         uint16_t getUData(uint8_t x);
         uint16_t getVData(uint8_t x);

         char * getStrData();

         void openFile(std::string inFile);
         void closeFile();
         bool readFile();

         bool processChunk(uint8_t *&data, uint32_t &length);
         bool frameRx(uint8_t *data, uint32_t length);
         void convertFile ( std::string inFile, std::string outFile);
   };

   typedef std::shared_ptr<ucsc_hn_lib::RenaDataFormat> RenaDataFormatPtr;

}

#endif

