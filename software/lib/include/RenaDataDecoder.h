
#ifndef __RENA_DATA_DECODER_H__
#define __RENA_DATA_DECODER_H__

#include <rogue/interfaces/stream/Master.h>
#include <rogue/interfaces/stream/Slave.h>
#include <rogue/interfaces/stream/Frame.h>

namespace ucsc_hn_lib {

   class RenaDataDecoder : public rogue::interfaces::stream::Slave, public rogue::interfaces::stream::Master {

         unsigned char crc8_table_[256];

         uint32_t rxFrameCount_;
         uint32_t rxSampleCount_;
         uint32_t rxByteCount_;
         uint32_t rxDropCount_;
         uint8_t  nodeId_;

         uint8_t polarity_[30][2][36];

      public:

         static std::shared_ptr<ucsc_hn_lib::RenaDataDecoder> create(uint8_t nodeId);

         static void setup_python();

         RenaDataDecoder (uint8_t nodeId);

         void setChannelPolarity(uint8_t fpga, uint8_t rena, uint8_t chan, bool state);

         bool getChannelPolarity(uint8_t fpga, uint8_t rena, uint8_t chan);

         void countReset();

         uint32_t getRxFrameCount();

         uint32_t getRxSampleCount();

         uint32_t getRxByteCount();

         uint32_t getRxDropCount();

         void acceptFrame ( std::shared_ptr<rogue::interfaces::stream::Frame> frame );
   };

   typedef std::shared_ptr<ucsc_hn_lib::RenaDataDecoder> RenaDataDecoderPtr;

}

#endif

