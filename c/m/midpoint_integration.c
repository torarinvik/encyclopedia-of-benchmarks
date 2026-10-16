#include <stddef.h>
#include <stdint.h>
#include <math.h>
static void store(int64_t x,uint8_t*out){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;b++)out[b]=(uint8_t)(u>>(8*b));}
int64_t midpoint_integration(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=4)return -1;int64_t f=v[0],steps=v[1],aa=v[2],bb=v[3];if(f<0||f>2||steps<1||steps>256||aa< -1000000||aa>1000000||bb<aa||bb>1000000)return -1;if(!out||cap<8)return -2;double a=(double)aa/1000000.0,b=(double)bb/1000000.0,h=(b-a)/(double)steps,sum=0.0;for(int64_t i=0;i<steps;i++){double x=a+(double)i*h+h/2.0;double y=f==0?1.0:(f==1?x:x*x);sum+=y;}int64_t result=(int64_t)floor(h*sum*1000000000.0+0.5);store(result,out);return 8;}
