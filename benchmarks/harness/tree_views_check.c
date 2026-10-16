#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<symbol>"
#endif
#define MAXN 1023
extern int64_t BENCHMARK_FUNCTION(const int64_t*,size_t,int64_t,int64_t,int64_t*,size_t);
int main(void){uint64_t cases;if(scanf("%" SCNu64,&cases)!=1||cases==0)return 2;for(uint64_t k=0;k<cases;k++){uint64_t n,m,cap;int64_t root,view,status;if(scanf("%" SCNu64 " %" SCNd64 " %" SCNd64 " %" SCNd64 " %" SCNu64 " %" SCNu64,&n,&root,&view,&status,&m,&cap)!=6||n>MAXN||m>n||cap>n)return 2;int64_t *a=calloc(3*(n?n:1),sizeof(int64_t)),*e=calloc(n?n:1,sizeof(int64_t)),*o=calloc(n?n:1,sizeof(int64_t));if(!a||!e||!o)return 2;for(size_t i=0;i<3*n;i++)if(scanf("%" SCNd64,&a[i])!=1)return 2;for(size_t i=0;i<m;i++)if(scanf("%" SCNd64,&e[i])!=1)return 2;int64_t r=BENCHMARK_FUNCTION(a,n,root,view,o,cap);if(r!=status||(status>=0&&(r!=(int64_t)m||(m&&memcmp(e,o,m*sizeof(int64_t)))))){fprintf(stderr,"case %" PRIu64 " mismatch\n",k);return 3;}free(a);free(e);free(o);}char extra;if(scanf(" %c",&extra)==1)return 2;printf("{\"cases_checked\":%" PRIu64 "}\n",cases);return 0;}
