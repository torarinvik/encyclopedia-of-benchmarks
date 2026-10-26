// Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
#include <cmath>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t Channels=20, MaxN=64, MaxSequence=32;
constexpr int amino_codes[Channels]={65,82,78,68,67,81,69,71,72,73,76,75,77,70,80,83,84,87,89,86};
constexpr double polarity[Channels]={8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9};
constexpr double volume[Channels]={31,124,56,54,55,85,83,3,96,111,111,119,105,132,32.5,32,61,170,136,84};
int channel(int code){for(int q=0;q<20;++q)if(amino_codes[q]==code)return q;return -1;}
void fft(double* re,double* im,std::size_t off,std::size_t n,bool inverse){
    std::size_t j=0;
    for(std::size_t i=1;i<n;++i){std::size_t bit=n>>1;while(j&bit){j^=bit;bit>>=1;}j^=bit;if(i<j){double t=re[off+i];re[off+i]=re[off+j];re[off+j]=t;t=im[off+i];im[off+i]=im[off+j];im[off+j]=t;}}
    for(std::size_t span=2;span<=n;span*=2){double a=(inverse?1.0:-1.0)*6.2831853071795864769/double(span),cr=std::cos(a),ci=std::sin(a);for(std::size_t start=0;start<n;start+=span){double wr=1,wi=0;for(std::size_t k=0;k<span/2;++k){std::size_t u=off+start+k,v=u+span/2;double pr=wr*re[v]-wi*im[v],pi=wr*im[v]+wi*re[v],ur=re[u],ui=im[u];re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi;double nw=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw;}}}
    if(!inverse)for(std::size_t i=0;i<n;++i){re[off+i]/=double(n);im[off+i]/=double(n);}
}
}
extern "C" std::int64_t mafft_falign_fft_lag_correlation(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(!input||length<4||length>66)return -1;
    for(std::size_t q=0;q<length;++q)if(!std::isfinite(input[q])||std::trunc(input[q])!=input[q])return -1;
    if(input[0]<1||input[0]>MaxSequence||input[1]<1||input[1]>MaxSequence)return -1;
    auto n1=std::size_t(input[0]),n2=std::size_t(input[1]);if(length!=2+n1+n2)return -1;
    for(std::size_t q=2;q<length;++q)if(input[q]<65.0||input[q]>90.0||channel(int(input[q]))<0)return -1;
    std::size_t n=1;while(n<=std::max(n1,n2))n*=2;if(!output||capacity<n)return -2;
    double r1[MaxN]{},i1[MaxN]{},r2[MaxN]{},i2[MaxN]{},re[MaxN]{},im[MaxN]{};
    double mp=0,mv=0;for(std::size_t ch=0;ch<Channels;++ch){mp+=polarity[ch];mv+=volume[ch];}mp/=Channels;mv/=Channels;
    double vp=0,vv=0;for(std::size_t ch=0;ch<Channels;++ch){double dp=polarity[ch]-mp,dv=volume[ch]-mv;vp+=dp*dp;vv+=dv*dv;}
    const double sp=std::sqrt(vp/Channels),sv=std::sqrt(vv/Channels);
    for(std::size_t p=0;p<n1;++p){auto ch=std::size_t(channel(int(input[2+p])));r1[p]=(polarity[ch]-mp)/sp;i1[p]=(volume[ch]-mv)/sv;}
    for(std::size_t p=0;p<n2;++p){auto ch=std::size_t(channel(int(input[2+n1+p])));r2[p]=(polarity[ch]-mp)/sp;i2[p]=(volume[ch]-mv)/sv;}
    fft(r1,i1,0,n,false);fft(r2,i2,0,n,false);
    for(std::size_t k=0;k<n;++k){re[k]=r1[k]*r2[k]+i1[k]*i2[k];im[k]=-r1[k]*i2[k]+i1[k]*r2[k];}
    fft(re,im,0,n,true);for(std::size_t q=0;q<n;++q)output[q]=re[(n/2+n-q)%n];return std::int64_t(n);
}
