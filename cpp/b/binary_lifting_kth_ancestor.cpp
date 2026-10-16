#include <array>
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_n=256,max_q=1024,levels=9; void put(std::uint8_t*out,std::size_t slot,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t i=0;i<8;++i)out[slot*8+i]=static_cast<std::uint8_t>(b>>(8*i));} }
extern "C" std::int64_t binary_lifting_kth_ancestor(const std::int64_t*in,std::size_t length,std::uint8_t*out,std::size_t capacity){
 if(!in||length<4||in[0]<1||in[0]>static_cast<std::int64_t>(max_n))return -1;const auto n=static_cast<std::size_t>(in[0]);if(in[1]<0||in[1]>=static_cast<std::int64_t>(n)||in[2]!=static_cast<std::int64_t>(n-1)||in[3]<0||in[3]>static_cast<std::int64_t>(max_q))return -1;const auto m=static_cast<std::size_t>(in[2]),q=static_cast<std::size_t>(in[3]),qo=4+2*m; if(length!=qo+2*q)return -1;const auto root=static_cast<std::size_t>(in[1]);
 std::array<std::array<bool,max_n>,max_n> adj{};for(std::size_t e=0;e<m;++e){auto a=in[4+2*e],b=in[5+2*e];if(a<0||b<0||a>=static_cast<std::int64_t>(n)||b>=static_cast<std::int64_t>(n)||a==b)return -1;adj[static_cast<std::size_t>(a)][static_cast<std::size_t>(b)]=true;adj[static_cast<std::size_t>(b)][static_cast<std::size_t>(a)]=true;}
 for(std::size_t i=0;i<q;++i){auto v=in[qo+2*i],k=in[qo+2*i+1];if(v<0||v>=static_cast<std::int64_t>(n)||k<0)return -1;}
 std::array<std::array<std::size_t,max_n>,levels> up{};std::array<std::int64_t,max_n> parent{};parent.fill(-1);std::array<std::size_t,max_n> stack{};std::size_t top=0,reached=0;parent[root]=static_cast<std::int64_t>(root);up[0][root]=root;stack[top++]=root;
 while(top){const auto u=stack[--top];++reached;for(std::size_t v=0;v<n;++v)if(adj[u][v]){if(static_cast<std::int64_t>(v)==parent[u])continue;if(parent[v]!=-1)return -1;parent[v]=static_cast<std::int64_t>(u);up[0][v]=u;stack[top++]=v;}}if(reached!=n)return -1;
 for(std::size_t l=1;l<levels;++l)for(std::size_t v=0;v<n;++v)up[l][v]=up[l-1][up[l-1][v]];
 const std::size_t bytes=(1+q)*8;if(!out||capacity<bytes)return -2;put(out,0,static_cast<std::int64_t>(q));for(std::size_t i=0;i<q;++i){auto v=static_cast<std::size_t>(in[qo+2*i]);const auto k=static_cast<std::uint64_t>(in[qo+2*i+1]);if(k>=n)v=root;else for(std::size_t bit=0;bit<levels;++bit)if(k&(std::uint64_t{1}<<bit))v=up[bit][v];put(out,1+i,static_cast<std::int64_t>(v));}return static_cast<std::int64_t>(bytes);
}
