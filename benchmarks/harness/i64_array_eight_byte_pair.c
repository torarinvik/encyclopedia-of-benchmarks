/* Interleaved comparison of two implementations returning eight little-endian output bytes.
 * Usage: pair library-a library-b symbol rounds batches repetitions expected-output-word [inputs...]
 * Build with -O3 and -ldl on Linux. Libraries retain their own code and ABI.
 */
#define _POSIX_C_SOURCE 200809L
#include <dlfcn.h>
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

typedef int64_t (*array_fn)(const int64_t *, size_t, uint8_t *, size_t);
static int parse_i64(const char *s, int64_t *out) {
 char *end; errno=0; intmax_t n=strtoimax(s,&end,10);
 if(!*s || *end || errno || n<INT64_MIN || n>INT64_MAX) return 0;
 *out=(int64_t)n; return 1;
}
static int count(const char *s, uint64_t limit, uint64_t *out) {
 int64_t n; if(!parse_i64(s,&n)||n<1||(uint64_t)n>limit)return 0;
 *out=(uint64_t)n;return 1;
}
static uint64_t now(void) {
 struct timespec t;if(clock_gettime(CLOCK_MONOTONIC,&t)){perror("clock_gettime");exit(2);}
 return (uint64_t)t.tv_sec*UINT64_C(1000000000)+(uint64_t)t.tv_nsec;
}
int main(int argc,char **argv) {
 uint64_t rounds,batches,repetitions;int64_t expected;
 if(argc<9||!count(argv[4],10000,&rounds)||!count(argv[5],100000,&batches)||
    !count(argv[6],1000000000,&repetitions)||!parse_i64(argv[7],&expected)) {
  fprintf(stderr,"usage: pair library-a library-b symbol rounds batches repetitions expected-output-word input...\n");return 2;
 }
 size_t length=(size_t)argc-8;
 int64_t *input=calloc(length,sizeof(*input));if(!input)return 2;
 for(size_t i=0;i<length;++i)if(!parse_i64(argv[8+i],&input[i])){free(input);return 2;}
 int64_t *snapshot=malloc(length*sizeof(*input));if(!snapshot){free(input);return 2;}
 memcpy(snapshot,input,length*sizeof(*input));
 uint8_t output[2][32], reference[32];
 memset(output,0xa5,sizeof(output));memset(reference,0xa5,sizeof(reference));
 for(unsigned i=0;i<8;++i)reference[8+i]=(uint8_t)((uint64_t)expected>>(8*i));
 void *handles[2]={NULL,NULL};array_fn functions[2];
 for(unsigned v=0;v<2;++v) {
  handles[v]=dlopen(argv[1+v],RTLD_NOW|RTLD_LOCAL);
  if(!handles[v]){fprintf(stderr,"dlopen: %s\n",dlerror());return 2;}
  dlerror();functions[v]=(array_fn)dlsym(handles[v],argv[3]);const char *error=dlerror();
  if(error||!functions[v]){fprintf(stderr,"dlsym: %s\n",error?error:"null symbol");return 2;}
  if(functions[v](input,length,output[v]+8,8)!=8 || memcmp(output[v],reference,32) || memcmp(input,snapshot,length*sizeof(*input))){fprintf(stderr,"incorrect result from variant %u\n",v);return 1;}
 }
 uint64_t checksum=0;
 for(uint64_t round=0;round<rounds;++round) {
  uint64_t elapsed[2]={0,0};
  /* Warm both variants equally, outside the measured interval. */
  for(uint64_t i=0;i<repetitions;++i)for(unsigned v=0;v<2;++v)
   checksum+=(uint64_t)functions[v](input,length,output[v]+8,8);
  for(uint64_t batch=0;batch<batches;++batch)for(unsigned turn=0;turn<2;++turn) {
   unsigned v=(unsigned)((round+batch+turn)&1);uint64_t start=now();
   for(uint64_t i=0;i<repetitions;++i)checksum+=(uint64_t)functions[v](input,length,output[v]+8,8);
   elapsed[v]+=now()-start;
   if(memcmp(output[v],reference,32)||memcmp(input,snapshot,length*sizeof(*input))){fprintf(stderr,"variant %u changed input or produced incorrect output/canaries\n",v);return 1;}
  }
  printf("{\"round\":%"PRIu64",\"a_ns\":%.9f,\"b_ns\":%.9f}\n",round,
   elapsed[0]/((double)batches*repetitions),elapsed[1]/((double)batches*repetitions));
 }
 fprintf(stderr,"checksum=%"PRIu64"\n",checksum);
 dlclose(handles[1]);dlclose(handles[0]);free(snapshot);free(input);return ferror(stdout)?2:0;
}
