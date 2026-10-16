#include <stddef.h>
#include <stdint.h>
#define MAX_TEXT 128
int64_t minimum_window_substring(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<3||n>258||v[0]<0||v[0]>MAX_TEXT)return -1;
 size_t a=(size_t)v[0];if(n<a+2)return -1;int64_t m0=v[a+1];if(m0<1||m0>MAX_TEXT)return -1;size_t m=(size_t)m0;if(n!=a+m+2)return -1;
 int need[128]={0};for(size_t i=0;i<a;i++){if(v[i+1]<0||v[i+1]>127)return -1;}for(size_t i=0;i<m;i++){int64_t c=v[a+2+i];if(c<0||c>127)return -1;need[c]++;}
 size_t left=0,best= a+1,bstart=0;int missing=(int)m;
 for(size_t right=0;right<a;right++){int c=(int)v[right+1];if(need[c]>0)missing--;need[c]--;while(missing==0){size_t len=right-left+1;if(len<best){best=len;bstart=left;}int x=(int)v[left+1];need[x]++;left++;if(need[x]>0)missing++;}}
 if(best==a+1)return 0;if(best>cap||(!out&&best))return -2;for(size_t i=0;i<best;i++)out[i]=(uint8_t)v[bstart+1+i];return (int64_t)best;
}
