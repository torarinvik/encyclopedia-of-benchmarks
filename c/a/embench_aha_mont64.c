#include <stddef.h>
#include <stdint.h>
#define MASK32 UINT64_C(0xffffffff)
static void mul_wide(uint64_t a,uint64_t b,uint64_t *hi,uint64_t *lo){uint64_t a0=a&MASK32,a1=a>>32,b0=b&MASK32,b1=b>>32;uint64_t p00=a0*b0,p01=a0*b1,p10=a1*b0,p11=a1*b1;uint64_t l=p00,old=l;l+=p01<<32;uint64_t h=p11+(p01>>32)+(l<old);old=l;l+=p10<<32;h+=(p10>>32)+(l<old);*lo=l;*hi=h;}
static uint64_t montmul(uint64_t a,uint64_t b,uint64_t m,uint64_t nprime){uint64_t thi,tlo,tmmhi,tmmlo;mul_wide(a,b,&thi,&tlo);uint64_t tm=tlo*nprime;mul_wide(tm,m,&tmmhi,&tmmlo);uint64_t ulo=tlo+tmmlo,uhi=thi+tmmhi;if(ulo<tlo)uhi++;uint64_t ov=(uhi<thi)||((uhi==thi)&&(ulo<tlo));if(ov||uhi>=m)return uhi-m;return uhi;}
static uint64_t mont_nprime(uint64_t m){uint64_t inv=1;for(unsigned i=0;i<6;i++)inv*=2-m*inv;return 0-inv;}
int64_t embench_aha_mont64(const int64_t *v,size_t n){if(!v||n!=3||v[0]<0||v[1]<0||v[2]<3||(v[2]&1)==0)return -1;uint64_t a=(uint64_t)v[0],b=(uint64_t)v[1],m=(uint64_t)v[2];if(a>=m||b>=m)return -1;uint64_t np=mont_nprime(m);return (int64_t)montmul(a,b,m,np);}
