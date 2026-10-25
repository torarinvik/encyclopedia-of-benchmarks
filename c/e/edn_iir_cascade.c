/* SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t u=(uint64_t)x;for(size_t j=0;j<8;j++)o[p+j]=(uint8_t)(u>>(8*j));}
int64_t edn_iir_cascade(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n<2||n>50)return -1;int64_t count=v[0],x=v[1];if(count<1||count>8||x< -1024||x>1023||n!=2+6*(size_t)count)return -1;size_t q=(size_t)count;int64_t c[32],s[16];for(size_t i=0;i<4*q;i++){c[i]=v[2+i];if(c[i]< -1024||c[i]>1023)return -1;}for(size_t i=0;i<2*q;i++){s[i]=v[2+4*q+i];if(s[i]< -1024||s[i]>1023)return -1;}size_t bytes=8*(1+2*q);if(!out||cap<bytes)return -2;for(size_t i=0;i<q;i++){int64_t t=x+((c[4*i+2]*s[2*i]+c[4*i+3]*s[2*i+1])>>15);x=t+((c[4*i]*s[2*i]+c[4*i+1]*s[2*i+1])>>15);s[2*i+1]=s[2*i];s[2*i]=t;}put64(out,0,x);for(size_t i=0;i<2*q;i++)put64(out,8*(i+1),s[i]);return (int64_t)bytes;}
