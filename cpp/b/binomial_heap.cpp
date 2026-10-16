#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
namespace { constexpr int M=128,R=9,E=-1; struct Node{std::int64_t v;int child,sibling,degree;};struct Heap{std::array<Node,M> nodes{};std::array<int,R> roots{};int used=0,size=0;};
int link(Heap&h,int a,int b){int p,c;if(h.nodes[a].v<h.nodes[b].v){p=a;c=b;}else{p=b;c=a;}h.nodes[c].sibling=h.nodes[p].child;h.nodes[p].child=c;++h.nodes[p].degree;return p;}
void add(Heap&h,int r){int d=h.nodes[r].degree;while(h.roots[d]!=E){r=link(h,r,h.roots[d]);h.roots[d++]=E;}h.roots[d]=r;}
void insert(Heap&h,std::int64_t v){int r=h.used++;h.nodes[r]={v,E,E,0};++h.size;add(h,r);}
int minroot(const Heap&h){int b=E;for(int r:h.roots)if(r!=E&&(b==E||h.nodes[r].v<h.nodes[b].v))b=r;return b;}
std::int64_t extract(Heap&h){int b=minroot(h),d=h.nodes[b].degree;auto v=h.nodes[b].v;h.roots[d]=E;int c=h.nodes[b].child;while(c!=E){int next=h.nodes[c].sibling;h.nodes[c].sibling=E;add(h,c);c=next;}--h.size;return v;}
void put(std::uint8_t*out,std::size_t i,std::int64_t v){auto x=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;b++)out[i*8+b]=static_cast<std::uint8_t>(x>>(b*8));}}
extern "C" std::int64_t binomial_heap(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{if(!in||len<1||in[0]<0||in[0]>M||len!=1+2*static_cast<std::size_t>(in[0]))return -1;auto n=static_cast<std::size_t>(in[0]);std::size_t q=0;int size=0;for(std::size_t i=0;i<n;i++){auto op=in[1+2*i],v=in[2+2*i];if(op==0){if(v<std::numeric_limits<std::int32_t>::min()||v>std::numeric_limits<std::int32_t>::max())return -1;++size;}else if(op>=1&&op<=3){if(v!=0||((op==1||op==2)&&size==0))return -1;if(op==2)--size;++q;}else return -1;}auto need=q*8;if(cap<need||(need&&!out))return -2;Heap h;h.roots.fill(E);std::size_t w=0;for(std::size_t i=0;i<n;i++){auto op=in[1+2*i],v=in[2+2*i];std::int64_t r;if(op==0){insert(h,v);continue;}if(op==1)r=h.nodes[minroot(h)].v;else if(op==2)r=extract(h);else r=h.size==0?1:0;put(out,w++,r);}return static_cast<std::int64_t>(w);}
