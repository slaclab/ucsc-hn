
#ifndef __RENA_DATA_EMULATOR_H__
#define __RENA_DATA_EMULATOR_H__

#include <rogue/interfaces/stream/Master.h>
#include <rogue/interfaces/stream/Frame.h>
#include <thread>

namespace ucsc_hn_lib {

   class RenaDataEmulator : public rogue::interfaces::stream::Master {

         rogue::interfaces::stream::FramePtr frames_[2000];

         uint32_t period_;
         uint32_t index_;
         bool     enable_;
         bool     runEnable_;
         uint32_t frameCount_;
         uint32_t burstSize_;
         uint32_t sourceCnt_;
         std::string file_;

         std::thread* txThread_;

      public:

         static std::shared_ptr<ucsc_hn_lib::RenaDataEmulator> create(std::string file);

         static void setup_python();

         RenaDataEmulator (std::string file);

         void setDataEnable(bool state);
         bool getDataEnable();

         void setBurstSize(uint32_t size);
         uint32_t getBurstSize();

         void loadData();

         void countReset();

         void start();

         void stop();

         uint32_t getCount();

         void runThread();
   };

   typedef std::shared_ptr<ucsc_hn_lib::RenaDataEmulator> RenaDataEmulatorPtr;

}

#endif

