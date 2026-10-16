#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" double p2_quantile_estimator(const std::int64_t* v,std::size_t n) noexcept {
 if(!v||n<2||n>65||v[0]<1||v[0]>64||n!=static_cast<std::size_t>(v[0])+1)return -1e300;
 const auto count=static_cast<std::size_t>(v[0]);std::array<double,5> q{},p{},d{};const std::array<double,5> inc{0,.25,.5,.75,1};std::size_t seen=0;
 for(std::size_t z=0;z<count;++z){if(v[z+1]<INT32_MIN||v[z+1]>INT32_MAX)return -1e300;double x=static_cast<double>(v[z+1]);if(seen<5){q[seen++]=x;if(seen==5){std::sort(q.begin(),q.end());for(int i=0;i<5;++i)p[i]=d[i]=i+1;}continue;}int k;if(x<q[0]){q[0]=x;k=0;}else{k=3;for(int i=1;i<4;++i)if(x<q[i]){k=i-1;break;}if(x>q[4])q[4]=x;}for(int i=k+1;i<5;++i)p[i]++;for(int i=0;i<5;++i)d[i]+=inc[i];for(int i=1;i<4;++i){double drift=d[i]-p[i];bool sr=drift>=1&&p[i+1]-p[i]>1,sl=drift<=-1&&p[i-1]-p[i]<-1;if(!sr&&!sl)continue;int dir=sr?1:-1;double l=p[i]-p[i-1],r=p[i+1]-p[i];double cand=q[i]+dir/(l+r)*((l+dir)*(q[i+1]-q[i])/r+(r-dir)*(q[i]-q[i-1])/l);if(q[i-1]<cand&&cand<q[i+1])q[i]=cand;else{int nb=i+dir;q[i]+=dir*(q[nb]-q[i])/(p[nb]-p[i]);}p[i]+=dir;}}
 if(seen<5){std::sort(q.begin(),q.begin()+static_cast<std::ptrdiff_t>(count));double rank=.5*(count-1);auto lo=static_cast<std::size_t>(rank),hi=std::min(lo+1,count-1);return q[lo]+(rank-lo)*(q[hi]-q[lo]);}return q[2];
}
