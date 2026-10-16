#include <stddef.h>
#include <stdint.h>
#include <string.h>
static void put_double(uint8_t*out,double x){uint64_t bits;memcpy(&bits,&x,8);for(int k=0;k<8;k++)out[k]=(uint8_t)(bits>>(8*k));}
int64_t orbital_transfer_work(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=4)return -1;if(v[0]<-1000000000||v[0]>1000000000||v[1]<-1000000||v[1]>1000000||v[2]<1||v[2]>1000000000||v[3]<1||v[3]>1000000000)return -1;if(!out||cap<8)return -2;double work=(6.67430e-11*(double)v[0]*(double)v[1]/2.0)*(1.0/(double)v[2]-1.0/(double)v[3]);put_double(out,work);return 8;}
