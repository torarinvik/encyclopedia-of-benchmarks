/* SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt. */
#include <cstddef>
#include <cstdint>
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t u=static_cast<uint64_t>(x);for(size_t j=0;j<8;j++)o[p+j]=static_cast<uint8_t>(u>>(8*j));}
extern "C" int64_t edn_lattice_synthesis(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<2||n>34)return -1;int64_t order=v[0],f=v[1];if(order<1||order>16||f< -65536||f>65535||n!=2+2*static_cast<size_t>(order))return -1;size_t q=static_cast<size_t>(order);int64_t b[16],k[16];for(size_t i=0;i<q;i++){b[i]=v[2+i];k[i]=v[2+q+i];if(b[i]<-1024||b[i]>1023||k[i]<-1024||k[i]>1023)return -1;}size_t bytes=8*(q+1);if(!out||cap<bytes)return -2;f-=b[q-1]*k[q-1];for(size_t z=q-1;z>0;z--){size_t i=z-1;f-=b[i]*k[i];b[i+1]=b[i]+((k[i]*(f>>16))>>16);}b[0]=f>>16;put64(out,0,f);for(size_t i=0;i<q;i++)put64(out,8*(i+1),b[i]);return static_cast<int64_t>(bytes);}
