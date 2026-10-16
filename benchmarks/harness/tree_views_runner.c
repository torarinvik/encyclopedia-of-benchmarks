#define _POSIX_C_SOURCE 200809L
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<symbol>"
#endif
#define MAXN 1023
extern int64_t BENCHMARK_FUNCTION(const int64_t*,size_t,int64_t,int64_t,int64_t*,size_t);
static uint64_t ns(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (uint64_t)t.tv_sec*1000000000+t.tv_nsec;}
int main(int argc,char**argv){uint64_t samples=argc>1?strtoull(argv[1],0,10):1,warm=argc>2?strtoull(argv[2],0,10):0,reps=argc>3?strtoull(argv[3],0,10):1,cases;if(!samples||!reps||scanf("%" SCNu64,&cases)!=1)return 2;for(uint64_t k=0;k<cases;k++){uint64_t n,m;int64_t root,view;if(scanf("%" SCNu64 " %" SCNd64 " %" SCNd64 " %" SCNu64,&n,&root,&view,&m)!=4||n>MAXN||m>n)return 2;int64_t*a=calloc(3*(n?n:1),8),*e=calloc(n?n:1,8),*o=calloc(n?n:1,8);uint64_t*times=calloc(samples,8);if(!a||!e||!o||!times)return 2;for(size_t i=0;i<3*n;i++)if(scanf("%" SCNd64,&a[i])!=1)return 2;for(size_t i=0;i<m;i++)if(scanf("%" SCNd64,&e[i])!=1)return 2;if(BENCHMARK_FUNCTION(a,n,root,view,o,n)!=(int64_t)m||(m&&memcmp(e,o,m*8)))return 3;for(uint64_t j=0;j<warm;j++)BENCHMARK_FUNCTION(a,n,root,view,o,n);for(uint64_t s=0;s<samples;s++){uint64_t start=ns();for(uint64_t j=0;j<reps;j++)BENCHMARK_FUNCTION(a,n,root,view,o,n);times[s]=(ns()-start)/reps;}printf("{\"case\":%" PRIu64 ",\"result\":%" PRIu64 ",\"samples_ns\":[",k,m);for(uint64_t s=0;s<samples;s++)printf("%s%" PRIu64,s?",":"",times[s]);puts("]}");free(a);free(e);free(o);free(times);}return 0;}
