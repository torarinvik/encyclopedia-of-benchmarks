/* SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt. */
#include <cstddef>
#include <cstdint>
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t u=static_cast<uint64_t>(x);for(size_t j=0;j<8;j++)o[p+j]=static_cast<uint8_t>(u>>(8*j));}
extern "C" int64_t edn_vec_mpy1(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<4||n>130)return -1;int64_t count=v[0];if(count<1||count>64||n!=2+2*static_cast<size_t>(count))return -1;size_t q=static_cast<size_t>(count);int64_t y[64],x[64],scale=v[n-1];for(size_t i=0;i<q;i++){y[i]=v[1+i];x[i]=v[1+q+i];if(y[i]<-1024||y[i]>1023||x[i]<-1024||x[i]>1023)return -1;}if(scale< -1024||scale>1023)return -1;size_t bytes=8*q;if(!out||cap<bytes)return -2;for(size_t i=0;i<q;i++)y[i]+=(scale*x[i])>>15;for(size_t i=0;i<q;i++)put64(out,8*i,y[i]);return static_cast<int64_t>(bytes);}
