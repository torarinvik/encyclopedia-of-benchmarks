/* Clean-room bounded Heartwall score/selection; see package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_IN 85
static float fadd(float a,float b){return a+b;}
static float fsub(float a,float b){return a-b;}
static float fmul(float a,float b){return a*b;}
static float fdiv(float a,float b){return a/b;}
static void put64(uint8_t *o,int64_t x){uint64_t u=(uint64_t)x;for(int i=0;i<8;i++)o[i]=(uint8_t)(u>>(8*i));}

int64_t rodinia_heartwall_template_match(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<5||n>MAX_IN)return -1;
 int64_t ir0=v[0],ic0=v[1],tr0=v[2],tc0=v[3],mask=v[4];
 if(ir0<2||ir0>8||ic0<2||ic0>8||tr0<2||tr0>4||tc0<2||tc0>4||tr0>ir0||tc0>ic0||mask<0)return -1;
 size_t ir=(size_t)ir0,ic=(size_t)ic0,tr=(size_t)tr0,tc=(size_t)tc0;
 size_t nr=ir-tr+1,nc=ic-tc+1,count=nr*nc;
 if(((uint64_t)mask>>count)!=0||n!=5+tr*tc+ir*ic)return -1;
 for(size_t i=5;i<n;i++)if(v[i]<0||v[i]>255)return -1;
 size_t nn=tr*tc,ibase=5+nn;
 float tsum=0,tsq=0;
 for(size_t c=0;c<tc;c++)for(size_t r=0;r<tr;r++){float x=(float)v[5+c*tr+r];tsum=fadd(tsum,x);tsq=fadd(tsq,fmul(x,x));}
 float nf=(float)nn,tmean=fdiv(tsum,nf),tvar=fsub(fdiv(tsq,nf),fmul(tmean,tmean));
 if(!(tvar>0))return -1;
 float tscale=fmul(sqrtf((float)(nn-1)),sqrtf(tvar));
 float best=0;size_t besti=0,k=0;
 for(size_t c0=0;c0<nc;c0++)for(size_t r0=0;r0<nr;r0++,k++)if((((uint64_t)mask>>k)&1u)!=0){
  float ps=0,pq=0,dot=0;
  for(size_t c=0;c<tc;c++)for(size_t r=0;r<tr;r++){float a=(float)v[5+c*tr+r],b=(float)v[ibase+(c0+c)*ir+r0+r];ps=fadd(ps,b);pq=fadd(pq,fmul(b,b));dot=fadd(dot,fmul(a,b));}
  float centered=fsub(pq,fdiv(fmul(ps,ps),nf));if(centered<0)centered=0;if(!(centered>0))return -1;
  float numerator=fsub(dot,fdiv(fmul(ps,tsum),nf));
  float denomT=fmul(sqrtf((float)(nn-1)),sqrtf(tvar));
  float denom=fmul(sqrtf(centered),denomT);
  float score=fdiv(numerator,denom),mag=fabsf(score);if(!isfinite(mag))return -1;if(mag>best){best=mag;besti=k;}
 }
 if(!out||cap<8)return -2;put64(out,(int64_t)besti);return 8;
}
