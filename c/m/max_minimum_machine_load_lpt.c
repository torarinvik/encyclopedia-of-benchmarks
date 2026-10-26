#include <stddef.h>
#include <stdint.h>
#define N 16
#define L 18
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)(b&255U);b>>=8;}}
int64_t max_minimum_machine_load_lpt(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<3||len>L)return -1;int64_t nr=in[0],mr=in[1];if(nr<1||nr>N||mr<1||mr>4||len!=2+(size_t)nr)return -1;size_t n=(size_t)nr,m=(size_t)mr;int64_t p[N],order[N],assign[N],loads[4]={0};for(size_t i=0;i<n;i++){p[i]=in[2+i];if(p[i]<1||p[i]>100)return -1;order[i]=(int64_t)i;}size_t bytes=8*(1+n+m);if(!out||cap<bytes)return -2;
 for(size_t i=1;i<n;i++){int64_t key=order[i];size_t j=i;while(j>0&&(p[key]>p[order[j-1]]||(p[key]==p[order[j-1]]&&key<order[j-1]))){order[j]=order[j-1];--j;}order[j]=key;}
 for(size_t k=0;k<n;k++){size_t job=(size_t)order[k],machine=0;for(size_t j=1;j<m;j++)if(loads[j]<loads[machine])machine=j;assign[job]=(int64_t)machine;loads[machine]+=p[job];}int64_t low=loads[0];for(size_t j=1;j<m;j++)if(loads[j]<low)low=loads[j];put64(out,0,low);for(size_t i=0;i<n;i++)put64(out,8*(1+i),assign[i]);for(size_t j=0;j<m;j++)put64(out,8*(1+n+j),loads[j]);return (int64_t)bytes;
}
