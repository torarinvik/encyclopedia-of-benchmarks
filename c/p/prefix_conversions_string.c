#include <stddef.h>
#include <stdint.h>
#define MAX_VALUE INT64_C(1000000000000)
static size_t append_i64(uint8_t *out,size_t at,int64_t x){if(x<0){out[at++]='-';x=-x;}if(x==0){out[at++]='0';return at;}uint8_t rev[24];size_t n=0;while(x){rev[n++]=(uint8_t)('0'+x%10);x/=10;}while(n)out[at++]=rev[--n];return at;}
static int64_t raw(uint8_t*out,int64_t value){return (int64_t)append_i64(out,0,value);}
static int64_t scaled(uint8_t*out,int64_t value,int64_t scale,const char*name,size_t name_len){if(value%scale)return -1;size_t at=append_i64(out,0,value/scale);out[at++]='.';out[at++]='0';out[at++]=' ';for(size_t i=0;i<name_len;i++)out[at++]=(uint8_t)name[i];return (int64_t)at;}
int64_t prefix_conversions_string(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=2||(v[0]!=0&&v[0]!=1)||v[1]<-MAX_VALUE||v[1]>MAX_VALUE)return -1;if(!out||cap<8192)return -2;int64_t x=v[1];if(x<=0)return raw(out,x);if(v[0]==0){if(x>1000000000)return scaled(out,x,1000000000,"giga",4);if(x>1000000)return scaled(out,x,1000000,"mega",4);if(x>1000)return scaled(out,x,1000,"kilo",4);if(x>100)return scaled(out,x,100,"hecto",5);if(x>10)return scaled(out,x,10,"deca",4);}else{if(x>1073741824)return scaled(out,x,1073741824,"giga",4);if(x>1048576)return scaled(out,x,1048576,"mega",4);if(x>1024)return scaled(out,x,1024,"kilo",4);}return raw(out,x);}
