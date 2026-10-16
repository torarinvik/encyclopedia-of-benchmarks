#include <cstddef>
#include <cstdint>
extern "C" std::int64_t euler(const std::int64_t *v,std::size_t n) noexcept {
 if(!v||n<4||n>516||v[0]<1||v[0]>32||v[1]<0||v[1]>=v[0]||v[2]<0||v[2]>=v[0]||v[3]<0||v[3]>256||n!=4+2*static_cast<std::size_t>(v[3]))return -2;
 auto count=static_cast<std::size_t>(v[0]);auto s=static_cast<std::size_t>(v[1]);auto t=static_cast<std::size_t>(v[2]);auto m=static_cast<std::size_t>(v[3]);std::uint64_t adj[32]={};int degree[32]={};
 for(std::size_t i=0;i<m;i++){auto x=v[4+2*i],y=v[5+2*i];if(x<0||y<0||x>=v[0]||y>=v[0]||x==y)return -2;auto bx=std::uint64_t(1)<<x,by=std::uint64_t(1)<<y;if(adj[x]&by)return -2;adj[x]|=by;adj[y]|=bx;++degree[x];++degree[y];}
 int odd=0;for(std::size_t i=0;i<count;i++){int want=s==t?0:(i==s||i==t);if((degree[i]&1)!=want)return 0;if(degree[i]&1)++odd;}return odd==(s==t?0:2);
}
