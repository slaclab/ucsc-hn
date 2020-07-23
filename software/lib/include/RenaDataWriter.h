
#ifndef __RENA_DATA_WRITER_H__
#define __RENA_DATA_WRITER_H__
#include <rogue/utilities/fileio/StreamWriter.h>
#include <rogue/interfaces/stream/Frame.h>
#include <stdint.h>

namespace ucsc_hn_lib {

   class RenaDataWriter : public rogue::utilities::fileio::StreamWriter {

      protected:

         virtual void writeFile ( uint8_t channel, std::shared_ptr<rogue::interfaces::stream::Frame> frame);

      public:

         static std::shared_ptr<ucsc_hn_lib::RenaDataWriter> create ();

         static void setup_python();

         RenaDataWriter();

         ~RenaDataWriter();

   };

   typedef std::shared_ptr<ucsc_hn_lib::RenaDataWriter> RenaDataWriterPtr;
}

#endif

