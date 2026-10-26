#include <stddef.h>
#include <stdint.h>
#define MAX_N 12
#define MAX_INPUT 25
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255U);b>>=8;}}
int64_t smith_weighted_completion_time(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<3||len>MAX_INPUT)return -1;int64_t n64=in[0];if(n64<1||n64>MAX_N||len!=(size_t)(1+2*n64))return -1;size_t n=(size_t)n64;
 int64_t p[MAX_N],w[MAX_N],order[MAX_N];for(size_t i=0;i<n;++i){p[i]=in[1+2*i];w[i]=in[2+2*i];if(p[i]<1||p[i]>10000||w[i]<1||w[i]>10000)return -1;order[i]=(int64_t)i;}
 size_t bytes=8*(n+1);if(!out||cap<bytes)return -2;
 for(size_t i=1;i<n;++i){int64_t key=order[i];size_t j=i;while(j>0){size_t prev=(size_t)order[j-1];int before=w[key]*p[prev]>w[prev]*p[key]||(w[key]*p[prev]==w[prev]*p[key]&&key<(int64_t)prev);if(!before)break;order[j]=order[j-1];--j;}order[j]=key;}
 int64_t time=0,total=0;for(size_t i=0;i<n;++i){size_t job=(size_t)order[i];time+=p[job];total+=w[job]*time;}put64(out,0,total);for(size_t i=0;i<n;++i)put64(out,8*(i+1),order[i]);return (int64_t)bytes;
}
