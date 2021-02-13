
#ifndef __RENA_LEGACY_WRITER_H__
#define __RENA_LEGACY_WRITER_H__
#include <rogue/utilities/fileio/StreamWriter.h>
#include <rogue/interfaces/stream/Frame.h>
#include <stdint.h>

namespace ucsc_hn_lib {

   class RenaLegacyWriter : public rogue::utilities::fileio::StreamWriter {

      protected:

         virtual void writeFile ( uint8_t channel, std::shared_ptr<rogue::interfaces::stream::Frame> frame);

      public:

         static std::shared_ptr<ucsc_hn_lib::RenaLegacyWriter> create ();

         static void setup_python();

         RenaLegacyWriter();

         ~RenaLegacyWriter();

   };

   typedef std::shared_ptr<ucsc_hn_lib::RenaLegacyWriter> RenaLegacyWriterPtr;
}

#endif

