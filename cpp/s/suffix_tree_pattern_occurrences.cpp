#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t N=24,M=12,INPUT=39,NODES=51;
struct Node{std::size_t start=0,length=0,suffix=0,child_count=0,children[NODES]{};};
std::int64_t code_at(const std::int64_t*in,std::size_t n,std::size_t p){return p==n?-1:in[1+p];}
void put64(std::uint8_t*out,std::size_t p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t j=0;j<8;j++){out[p+j]=static_cast<std::uint8_t>(b&255U);b>>=8;}}
bool suffix_less(const std::int64_t*in,std::size_t n,std::size_t a,std::size_t b){std::size_t p=0;while(a+p<=n&&b+p<=n){auto x=code_at(in,n,a+p),y=code_at(in,n,b+p);if(x!=y)return x<y;++p;}return a<b;}
}
extern "C" std::int64_t suffix_tree_pattern_occurrences(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<3||len>INPUT)return -1;auto nr=in[0];if(nr<0||nr>N)return -1;auto n=static_cast<std::size_t>(nr);if(len<2+n)return -1;auto mr=in[1+n];if(mr<1||mr>M||len!=2+n+static_cast<std::size_t>(mr))return -1;auto m=static_cast<std::size_t>(mr);
 for(std::size_t i=0;i<n;i++)if(in[1+i]<0||in[1+i]>127)return -1;for(std::size_t i=0;i<m;i++)if(in[2+n+i]<0||in[2+n+i]>127)return -1;
 Node nodes[NODES]{};std::size_t count_nodes=1;
 for(std::size_t start=0;start<=n;start++){auto suffix_len=n+1-start;std::size_t off=0,node=0;while(off<suffix_len){auto first=code_at(in,n,start+off);std::size_t slot=0;while(slot<nodes[node].child_count&&code_at(in,n,nodes[nodes[node].children[slot]].start)!=first)++slot;if(slot==nodes[node].child_count){if(count_nodes>=NODES)return -1;auto leaf=count_nodes++;nodes[leaf].start=start+off;nodes[leaf].length=suffix_len-off;nodes[leaf].suffix=start;nodes[node].children[nodes[node].child_count++]=leaf;break;}auto child=nodes[node].children[slot];std::size_t common=0;while(common<nodes[child].length&&off+common<suffix_len&&code_at(in,n,start+off+common)==code_at(in,n,nodes[child].start+common))++common;if(common==nodes[child].length){off+=common;node=child;continue;}if(count_nodes>=NODES)return -1;auto split=count_nodes++;nodes[split].start=nodes[child].start;nodes[split].length=common;nodes[split].children[0]=child;nodes[split].child_count=1;nodes[child].start+=common;nodes[child].length-=common;nodes[node].children[slot]=split;off+=common;node=split;}}
 std::size_t node=0,off=0;bool matched=false;while(off<m){auto wanted=in[2+n+off];std::size_t slot=0;while(slot<nodes[node].child_count&&code_at(in,n,nodes[nodes[node].children[slot]].start)!=wanted)++slot;if(slot==nodes[node].child_count)break;auto child=nodes[node].children[slot];std::size_t common=0;while(common<nodes[child].length&&off+common<m&&code_at(in,n,nodes[child].start+common)==in[2+n+off+common])++common;if(off+common==m){node=child;matched=true;break;}if(common!=nodes[child].length)break;off+=common;node=child;}
 std::size_t starts[N]{};std::size_t count=0;if(matched){std::size_t stack[NODES],top=0;stack[top++]=node;while(top){auto x=stack[--top];if(nodes[x].child_count==0&&nodes[x].length>0)starts[count++]=nodes[x].suffix;for(std::size_t j=0;j<nodes[x].child_count;j++)stack[top++]=nodes[x].children[j];}}
 for(std::size_t i=1;i<count;i++){auto x=starts[i];auto j=i;while(j>0&&suffix_less(in,n,x,starts[j-1])){starts[j]=starts[j-1];--j;}starts[j]=x;}
 auto bytes=8*(1+count);if(!out||cap<bytes)return -2;put64(out,0,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;i++)put64(out,8+8*i,static_cast<std::int64_t>(starts[i]));return static_cast<std::int64_t>(bytes);
}
