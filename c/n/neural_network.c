#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
static void putd(uint8_t*o,size_t p,double x){uint64_t b;memcpy(&b,&x,8);for(int k=0;k<8;k++)o[p+k]=(uint8_t)(b>>(8*k));}
static double sig(double x){return 1.0/(1.0+exp(-x));}
int64_t neural_network(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<7)return -1;int ni=(int)v[0],nh=(int)v[1],no=(int)v[2];if(ni<1||ni>3||nh<1||nh>3||no<1||no>3||n!=3+(size_t)ni+(size_t)ni*nh+(size_t)nh*no)return -1;for(size_t i=3;i<n;i++)if(v[i]<-1000||v[i]>1000)return -1;if(!out||cap<(size_t)no*8)return -2;size_t x=3,w1=x+ni,w2=w1+(size_t)ni*nh;double h[3];for(int j=0;j<nh;j++){double z=0;for(int i=0;i<ni;i++)z+=(double)v[x+i]/1000.0*((double)v[w1+(size_t)i*nh+j]/1000.0);h[j]=sig(z);}for(int j=0;j<no;j++){double z=0;for(int i=0;i<nh;i++)z+=h[i]*((double)v[w2+(size_t)i*no+j]/1000.0);putd(out,(size_t)j*8,sig(z));}return no*8;}
