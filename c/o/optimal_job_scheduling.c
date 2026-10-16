#include <stddef.h>
#include <stdint.h>
#define MAX_PROCESSES 16
#define MAX_MACHINES 8
static void append_uint(uint8_t*b,size_t*n,uint32_t x){uint8_t d[10];size_t k=0;do{d[k++]=(uint8_t)('0'+x%10);x/=10;}while(x);while(k)b[(*n)++]=d[--k];}
int64_t optimal_job_scheduling(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<4||n>194||v[0]<1||v[0]>MAX_PROCESSES||v[1]<1||v[1]>MAX_MACHINES)return -1;size_t p=(size_t)v[0],m=(size_t)v[1];if(n!=2+p*m+m*m)return -1;
 int64_t run[MAX_PROCESSES][MAX_MACHINES],transfer[MAX_MACHINES][MAX_MACHINES];size_t at=2;
 for(size_t i=0;i<p;i++)for(size_t j=0;j<m;j++){int64_t x=v[at++];if(x<0||x>1000)return -1;run[i][j]=x;}
 for(size_t i=0;i<m;i++)for(size_t j=0;j<m;j++){int64_t x=v[at++];if(x<0||x>1000)return -1;transfer[i][j]=x;}
 uint32_t cost[MAX_PROCESSES][MAX_MACHINES];for(size_t j=0;j<m;j++)cost[0][j]=(uint32_t)run[0][j];
 for(size_t i=1;i<p;i++)for(size_t j=0;j<m;j++){uint32_t best=UINT32_MAX;for(size_t k=0;k<m;k++){uint32_t x=cost[i-1][k]+(uint32_t)transfer[k][j]+(uint32_t)run[i][j];if(x<best)best=x;}cost[i][j]=best;}
 uint8_t b[2048];size_t used=0;for(size_t i=0;i<p;i++){for(size_t j=0;j<m;j++){if(j)b[used++]=',';append_uint(b,&used,cost[i][j]);}if(i+1<p)b[used++]='\n';}
 if(used>cap||(used&&!out))return -2;for(size_t i=0;i<used;i++)out[i]=b[i];return (int64_t)used;
}
