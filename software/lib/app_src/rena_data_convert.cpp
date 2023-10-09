#include "RenaDataFormat.h"
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <ctime>

int main(int argc, char** argv) {
   struct stat st;
   int fin;
   int fout;
   uint8_t inBuff[1000];
   uint8_t *inPtr;
   uint32_t inLength;
   uint32_t fileSize;
   uint32_t readSize;
   char *outStr;
   std::time_t lastTme;
   std::time_t currTme;
   uint32_t readBytes;
   uint32_t readFrames;
   uint32_t dropCount;
   uint32_t sampCount;
   uint32_t pct;
   uint32_t vPct;

   ucsc_hn_lib::RenaDataFormatPtr df = ucsc_hn_lib::RenaDataFormat::create();

   if ( argc != 3 ) {
      printf("Usage: %s input_file output_file\n", argv[0]);
      return -1;
   }

   if ( ( fin = open(argv[1],O_RDONLY) ) < 0 ) {
      printf("Failed to open input file %s\n", argv[1]);
      return -1;
   }

   // Get file size
   stat(argv[1], &st);
   fileSize = st.st_size;
   readSize = 0;

   printf("Converting %s of size %u to %s. Updates will report every 10 seconds\n", argv[1], fileSize, argv[2]);
   time(&lastTme);

   if ( ( fout = open(argv[2], O_RDWR | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)) < 0) {
      printf("Failed to open output file. File may already exist! %s\n", argv[2]);
      return -1;
   }

   inPtr = inBuff;

   while ( (inLength = read(fin, inPtr, 1000)) > 0 ) {
      readSize += inLength;
      while ( inLength > 0 ) {
         if ( df->processChunk(inPtr, inLength) ) {
            outStr = df->getStrData();
            write(fout,outStr,strlen(outStr));
         }
      }

      time(&currTme);

      if ( currTme - lastTme > 10 ) {
         lastTme = currTme;

         readBytes = df->getByteCount();
         readFrames = df->getFrameCount();
         dropCount = df->getDropCount();
         sampCount = df->getSampleCount();

         pct = int((float(readSize) / float(fileSize)) * 100.0);
         vPct = int((float(readBytes) / float(readSize)) * 100.0);

         printf("Read %u of %u bytes, %u pct. Valid = %u, %u pct, Frames = %u, drops = %u, samples = %u\n", readSize, fileSize, pct, readBytes, vPct, readFrames, dropCount, sampCount);
      }
      inPtr = inBuff;
   }
   return 0;
}

