
#ifndef __RENA_DATA_DECODER_H__
#define __RENA_DATA_DECODER_H__

#include <rogue/interfaces/stream/Master.h>
#include <rogue/interfaces/stream/Slave.h>
#include <rogue/interfaces/stream/Frame.h>
#include <rogue/protocols/batcher/Data.h>
#include <rogue/Logging.h>

namespace ucsc_hn_lib {

   class RenaDataDecoder : public rogue::interfaces::stream::Slave, public rogue::interfaces::stream::Master {

         unsigned char crc8_table_[256];

         uint32_t rxFrameCount_;
         uint32_t rxSampleCount_;
         uint32_t rxByteCount_;
         uint32_t rxDropCount_;
         uint8_t  nodeId_;
         uint32_t copyCount_;

         uint8_t polarity_[31][2][36];
         uint32_t rxCount_[31];
         uint32_t rxTotal_[31];
         uint32_t decodeEn_;
         std::shared_ptr<rogue::Logging> dlog_;

      public:

         static std::shared_ptr<ucsc_hn_lib::RenaDataDecoder> create(uint8_t nodeId);

         static void setup_python();

         RenaDataDecoder (uint8_t nodeId);

         void setChannelPolarity(uint8_t fpga, uint8_t rena, uint8_t chan, uint8_t state);

         void setDecodeEnable(uint32_t enable);

         uint32_t getDecodeEnable();

         uint8_t getChannelPolarity(uint8_t fpga, uint8_t rena, uint8_t chan);

         void countReset();

         uint32_t getRxFrameCount();

         uint32_t getCopyCount();

         uint32_t getRxSampleCount();

         uint32_t getRxByteCount();

         uint32_t getRxDropCount();

         uint32_t getRxCount(uint8_t fpga);
         uint32_t getRxTotal(uint8_t fpga);

         void sendDiag ( std::shared_ptr<rogue::protocols::batcher::Data> data);

         void acceptFrame ( std::shared_ptr<rogue::interfaces::stream::Frame> frame );
   };

   typedef std::shared_ptr<ucsc_hn_lib::RenaDataDecoder> RenaDataDecoderPtr;

}

#endif

