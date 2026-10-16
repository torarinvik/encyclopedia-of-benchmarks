#include <cstddef>
#include <cstdint>

namespace {
constexpr int W=32,L=16,Q=16,NN=1+W*L,NO=1+Q*(1+W*(1+L));
struct Node{int child[26];bool terminal;};
void init(Node&n){for(int i=0;i<26;++i)n.child[i]=-1;n.terminal=false;}
void collect(const Node*nodes,int at,int*path,int depth,std::int64_t*out,std::size_t&used,std::size_t&count){if(nodes[at].terminal){out[used++]=depth;for(int i=0;i<depth;++i)out[used++]='a'+path[i];++count;}for(int c=0;c<26;++c)if(nodes[at].child[c]>=0){path[depth]=c;collect(nodes,nodes[at].child[c],path,depth+1,out,used,count);}}
void put(std::uint8_t*out,std::size_t i,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b)out[i*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t autocomplete_using_trie(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<2||in[0]<0||in[0]>W)return -1;Node nodes[NN];init(nodes[0]);std::size_t nc=1,pos=1;auto words=static_cast<std::size_t>(in[0]);
 for(std::size_t w=0;w<words;++w){if(pos>=len)return -1;auto lv=in[pos++];if(lv<1||lv>L||pos+static_cast<std::size_t>(lv)>len)return -1;int at=0;for(std::size_t j=0;j<static_cast<std::size_t>(lv);++j){auto ch=in[pos++];if(ch<'a'||ch>'z')return -1;int c=static_cast<int>(ch-'a');if(nodes[at].child[c]<0){if(nc>=NN)return -1;init(nodes[nc]);nodes[at].child[c]=static_cast<int>(nc++);}at=nodes[at].child[c];}nodes[at].terminal=true;}
 if(pos>=len)return -1;auto qv=in[pos++];if(qv<0||qv>Q)return -1;auto q=static_cast<std::size_t>(qv);std::size_t qp[Q],ql[Q];for(std::size_t i=0;i<q;++i){if(pos>=len)return -1;auto lv=in[pos++];if(lv<0||lv>L||pos+static_cast<std::size_t>(lv)>len)return -1;qp[i]=pos;ql[i]=static_cast<std::size_t>(lv);for(std::size_t j=0;j<ql[i];++j)if(in[pos+j]<'a'||in[pos+j]>'z')return -1;pos+=ql[i];}if(pos!=len)return -1;
 std::int64_t values[NO];std::size_t used=0;values[used++]=static_cast<std::int64_t>(q);for(std::size_t i=0;i<q;++i){int at=0,path[L],found=1;for(std::size_t j=0;j<ql[i];++j){int c=static_cast<int>(in[qp[i]+j]-'a');path[j]=c;if(nodes[at].child[c]<0){found=0;break;}at=nodes[at].child[c];}auto count_pos=used++;std::size_t count=0;if(found)collect(nodes,at,path,static_cast<int>(ql[i]),values,used,count);values[count_pos]=static_cast<std::int64_t>(count);}auto required=used*8;if(!out||cap<required)return -2;for(std::size_t i=0;i<used;++i)put(out,i,values[i]);return static_cast<std::int64_t>(required);
}
