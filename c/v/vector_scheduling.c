/* Clean-room explicit-choice profile of randomized vector scheduling. */
#include <stddef.h>
#include <stdint.h>
enum{MAX_N=16,MAX_M=8,MAX_D=4,MAX_INPUT=83,MAX_FIELDS=35};
static void put(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)(b&255u);b>>=8;}}
int64_t vector_scheduling(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<3||length>MAX_INPUT)return -1;int64_t n64=input[0],m64=input[1],d64=input[2];if(n64<1||n64>16||m64<1||m64>8||d64<1||d64>4||length!=3+(size_t)n64+(size_t)(n64*d64))return -1;size_t n=(size_t)n64,m=(size_t)m64,d=(size_t)d64;
 for(size_t j=0;j<n;++j)if(input[3+j]<0||input[3+j]>=m64)return -1;for(size_t i=0;i<n*d;++i)if(input[3+n+i]<0||input[3+n+i]>1000)return -1;
 int64_t loads[MAX_M][MAX_D]={{0}};for(size_t j=0;j<n;++j){size_t machine=(size_t)input[3+j];for(size_t q=0;q<d;++q)loads[machine][q]+=input[3+n+j*d+q];}
 int64_t makespan=0;for(size_t i=0;i<m;++i)for(size_t q=0;q<d;++q)if(loads[i][q]>makespan)makespan=loads[i][q];int64_t staged[MAX_FIELDS]={0};size_t count=0;staged[count++]=m64;staged[count++]=d64;staged[count++]=makespan;for(size_t i=0;i<m;++i)for(size_t q=0;q<d;++q)staged[count++]=loads[i][q];if(!output||capacity<8*count)return -2;for(size_t i=0;i<count;++i)put(output,8*i,staged[i]);return (int64_t)(8*count);
}
