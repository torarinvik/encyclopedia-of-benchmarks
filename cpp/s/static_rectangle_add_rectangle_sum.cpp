#include <cstddef>
#include <cstdint>
#include <algorithm>

namespace {
constexpr std::size_t NMAX=32, QMAX=32, CMAX=128, STRIDE=129;
constexpr std::int64_t MOD=998244353;
std::size_t lower(const std::int64_t *a, std::size_t n, std::int64_t x) {
    std::size_t lo=0, hi=n;
    while(lo<hi){ auto mid=lo+(hi-lo)/2; if(a[mid]<x) lo=mid+1; else hi=mid; }
    return lo;
}
void put64(std::uint8_t *out,std::size_t at,std::int64_t x){
    auto bits=static_cast<std::uint64_t>(x);
    for(std::size_t b=0;b<8;++b) out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}

extern "C" std::int64_t static_rectangle_add_rectangle_sum(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if(!input || length<2 || length>291) return -1;
    auto n64=input[0], q64=input[1];
    if(n64<1 || n64>32 || q64<0 || q64>32) return -1;
    auto n=static_cast<std::size_t>(n64), q=static_cast<std::size_t>(q64);
    if(length!=2+5*n+4*q) return -1;
    std::int64_t ul[NMAX],ud[NMAX],ur[NMAX],uu[NMAX],uw[NMAX];
    std::int64_t ql[QMAX],qd[QMAX],qr[QMAX],qu[QMAX];
    std::int64_t xs[CMAX],ys[CMAX]; std::size_t nx=0,ny=0,off=2;
    for(std::size_t i=0;i<n;++i){
        ul[i]=input[off];ud[i]=input[off+1];ur[i]=input[off+2];uu[i]=input[off+3];uw[i]=input[off+4];off+=5;
        if(ul[i]<0||ul[i]>=ur[i]||ur[i]>1000000||ud[i]<0||ud[i]>=uu[i]||uu[i]>1000000||uw[i]<0||uw[i]>=MOD)return -1;
        xs[nx++]=ul[i];xs[nx++]=ur[i];ys[ny++]=ud[i];ys[ny++]=uu[i];
    }
    for(std::size_t i=0;i<q;++i){
        ql[i]=input[off];qd[i]=input[off+1];qr[i]=input[off+2];qu[i]=input[off+3];off+=4;
        if(ql[i]<0||ql[i]>=qr[i]||qr[i]>1000000||qd[i]<0||qd[i]>=qu[i]||qu[i]>1000000)return -1;
        xs[nx++]=ql[i];xs[nx++]=qr[i];ys[ny++]=qd[i];ys[ny++]=qu[i];
    }
    std::sort(xs,xs+nx);std::sort(ys,ys+ny);
    nx=static_cast<std::size_t>(std::unique(xs,xs+nx)-xs);
    ny=static_cast<std::size_t>(std::unique(ys,ys+ny)-ys);
    std::int64_t diff[CMAX*CMAX]{}; std::int64_t pref[STRIDE*STRIDE]{};
    for(std::size_t k=0;k<n;++k){
        auto x0=lower(xs,nx,ul[k]),x1=lower(xs,nx,ur[k]);auto y0=lower(ys,ny,ud[k]),y1=lower(ys,ny,uu[k]);
        diff[x0*CMAX+y0]+=uw[k];diff[x1*CMAX+y0]-=uw[k];diff[x0*CMAX+y1]-=uw[k];diff[x1*CMAX+y1]+=uw[k];
    }
    for(std::size_t i=0;i<nx;++i)for(std::size_t j=0;j<ny;++j){
        auto at=i*CMAX+j;auto v=diff[at];if(i)v+=diff[(i-1)*CMAX+j];if(j)v+=diff[i*CMAX+j-1];if(i&&j)v-=diff[(i-1)*CMAX+j-1];diff[at]=v;
    }
    for(std::size_t i=0;i+1<nx;++i)for(std::size_t j=0;j+1<ny;++j){
        auto v=diff[i*CMAX+j]%MOD;auto dx=(xs[i+1]-xs[i])%MOD,dy=(ys[j+1]-ys[j])%MOD;
        auto cell=v*(dx*dy%MOD)%MOD;auto at=(i+1)*STRIDE+j+1;
        auto sum=(cell+pref[i*STRIDE+j+1]+pref[(i+1)*STRIDE+j]-pref[i*STRIDE+j])%MOD;if(sum<0)sum+=MOD;pref[at]=sum;
    }
    std::int64_t answer[QMAX];
    for(std::size_t k=0;k<q;++k){auto x0=lower(xs,nx,ql[k]),x1=lower(xs,nx,qr[k]);auto y0=lower(ys,ny,qd[k]),y1=lower(ys,ny,qu[k]);auto v=pref[x1*STRIDE+y1]-pref[x0*STRIDE+y1]-pref[x1*STRIDE+y0]+pref[x0*STRIDE+y0];v%=MOD;if(v<0)v+=MOD;answer[k]=v;}
    auto bytes=8*q;if(!output||capacity<bytes)return -2;for(std::size_t k=0;k<q;++k)put64(output,8*k,answer[k]);return static_cast<std::int64_t>(bytes);
}
