// Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t N=8,FIELDS=234;void put(std::uint8_t*o,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){o[at+i]=static_cast<std::uint8_t>(b);b>>=8;}} }
extern "C" std::int64_t ldfs_ordering_certificate(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<3||n>10||v[0]<1||v[0]>8)return -1;auto count=static_cast<std::size_t>(v[0]);if(n!=count+2||v[1]<0||v[1]>=static_cast<std::int64_t>(count))return -1;const auto all=(std::uint64_t{1}<<count)-1;std::uint64_t adj[N]{};
 for(std::size_t i=0;i<count;++i){if(v[2+i]<0||static_cast<std::uint64_t>(v[2+i])>all||(static_cast<std::uint64_t>(v[2+i])&(std::uint64_t{1}<<i)))return -1;adj[i]=static_cast<std::uint64_t>(v[2+i]);}for(std::size_t i=0;i<count;++i)for(std::size_t j=0;j<count;++j)if(((adj[i]>>j)&1u)!=((adj[j]>>i)&1u))return -1;
 std::uint64_t reached=std::uint64_t{1}<<v[1];for(std::size_t pass=0;pass<count;++pass){auto old=reached;for(std::size_t i=0;i<count;++i)if((reached>>i)&1u)reached|=adj[i];if(old==reached)break;}if(reached!=all)return -1;
 std::size_t order[N]{},used=1;order[0]=static_cast<std::size_t>(v[1]);std::uint64_t visited=std::uint64_t{1}<<v[1];auto better=[&](std::size_t x,std::size_t y){for(std::size_t k=used;k>0;--k){auto u=order[k-1];bool xb=(adj[x]>>u)&1u,yb=(adj[y]>>u)&1u;if(xb!=yb)return xb;}return x<y;};
 while(used<count){std::size_t chosen=count;for(std::size_t x=0;x<count;++x)if(!((visited>>x)&1u)&&(chosen==count||better(x,chosen)))chosen=x;order[used++]=chosen;visited|=std::uint64_t{1}<<chosen;}
 std::int64_t fields[FIELDS]{};fields[0]=count;for(std::size_t i=0;i<count;++i)fields[1+i]=order[i];std::size_t certs=0,at=count+2;
 for(std::size_t i=0;i<count;++i)for(std::size_t j=i+1;j<count;++j)for(std::size_t k=j+1;k<count;++k){auto a=order[i],b=order[j],c=order[k];if(((adj[a]>>c)&1u)&&!((adj[a]>>b)&1u)){std::int64_t d=-1;for(std::size_t t=i+1;t<j;++t){auto x=order[t];if(((adj[x]>>b)&1u)&&!((adj[x]>>c)&1u)){d=x;break;}}fields[at++]=a;fields[at++]=b;fields[at++]=c;fields[at++]=d;++certs;}}
 fields[count+1]=certs;auto bytes=8*at;if(!out||cap<bytes)return -2;for(std::size_t i=0;i<at;++i)put(out,8*i,fields[i]);return static_cast<std::int64_t>(bytes);
}
