// Clean-room bounded Heartwall score/selection; see package LICENSE.txt.
#include <cmath>
#include <cstddef>
#include <cstdint>
static void put64(uint8_t* o,int64_t x){uint64_t u=(uint64_t)x;for(int i=0;i<8;i++)o[i]=(uint8_t)(u>>(8*i));}
static float addf(float a,float b){return a+b;} static float subf(float a,float b){return a-b;} static float mulf(float a,float b){return a*b;} static float divf(float a,float b){return a/b;}
extern "C" int64_t rodinia_heartwall_template_match(const int64_t* v,size_t n,uint8_t* out,size_t cap){
 if(!v||n<5||n>85)return -1;int64_t ir0=v[0],ic0=v[1],tr0=v[2],tc0=v[3],mask=v[4];
 if(ir0<2||ir0>8||ic0<2||ic0>8||tr0<2||tr0>4||tc0<2||tc0>4||tr0>ir0||tc0>ic0||mask<0)return -1;
 size_t ir=ir0,ic=ic0,tr=tr0,tc=tc0,nr=ir-tr+1,nc=ic-tc+1,count=nr*nc;
 if((uint64_t(mask)>>count)!=0||n!=5+tr*tc+ir*ic)return -1;for(size_t i=5;i<n;i++)if(v[i]<0||v[i]>255)return -1;
 size_t nn=tr*tc,ibase=5+nn;float tsum=0,tsq=0;
 for(size_t c=0;c<tc;c++)for(size_t r=0;r<tr;r++){float x=float(v[5+c*tr+r]);tsum=addf(tsum,x);tsq=addf(tsq,mulf(x,x));}
 float nf=float(nn),tm=divf(tsum,nf),tv=subf(divf(tsq,nf),mulf(tm,tm));if(!(tv>0))return -1;
 float best=0;size_t besti=0,k=0;
 for(size_t c0=0;c0<nc;c0++)for(size_t r0=0;r0<nr;r0++,k++)if(((uint64_t(mask)>>k)&1u)!=0){float ps=0,pq=0,dot=0;
  for(size_t c=0;c<tc;c++)for(size_t r=0;r<tr;r++){float a=float(v[5+c*tr+r]),b=float(v[ibase+(c0+c)*ir+r0+r]);ps=addf(ps,b);pq=addf(pq,mulf(b,b));dot=addf(dot,mulf(a,b));}
  float centered=subf(pq,divf(mulf(ps,ps),nf));if(centered<0)centered=0;if(!(centered>0))return -1;
  float num=subf(dot,divf(mulf(ps,tsum),nf));float denomT=mulf(std::sqrt(float(nn-1)),std::sqrt(tv));float den=mulf(std::sqrt(centered),denomT);float score=divf(num,den),mag=std::fabs(score);if(!std::isfinite(mag))return -1;if(mag>best){best=mag;besti=k;}}
 if(!out||cap<8)return -2;put64(out,int64_t(besti));return 8;
}
