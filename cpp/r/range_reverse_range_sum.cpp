#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t NMAX = 64, QMAX = 32, INPUT_MAX = 163;
struct Node { int left=-1, right=-1, size=1; std::int64_t value=0, sum=0; std::uint64_t priority=0; bool reversed=false; };
struct Operation { int kind=0, left=0, right=0; };
std::uint64_t priority_for(std::size_t index) { std::int64_t state=1; for(std::size_t i=0;i<=index;++i) state=(state*48271)%2147483647; return static_cast<std::uint64_t>(state); }
int size(const std::array<Node,NMAX>& t,int x){return x<0?0:t[static_cast<std::size_t>(x)].size;}
std::int64_t sum(const std::array<Node,NMAX>& t,int x){return x<0?0:t[static_cast<std::size_t>(x)].sum;}
bool higher(const std::array<Node,NMAX>& t,int a,int b){const auto& x=t[static_cast<std::size_t>(a)];const auto& y=t[static_cast<std::size_t>(b)];return x.priority!=y.priority?x.priority>y.priority:a>b;}
void pull(std::array<Node,NMAX>& t,int x){auto& n=t[static_cast<std::size_t>(x)];n.size=1+size(t,n.left)+size(t,n.right);n.sum=n.value+sum(t,n.left)+sum(t,n.right);}
void reverse_node(std::array<Node,NMAX>& t,int x){if(x<0)return;auto& n=t[static_cast<std::size_t>(x)];std::swap(n.left,n.right);n.reversed=!n.reversed;}
void push(std::array<Node,NMAX>& t,int x){auto& n=t[static_cast<std::size_t>(x)];if(!n.reversed)return;reverse_node(t,n.left);reverse_node(t,n.right);n.reversed=false;}
void split(std::array<Node,NMAX>& t,int root,int count,int& a,int& b){if(root<0){a=b=-1;return;}push(t,root);auto& n=t[static_cast<std::size_t>(root)];if(size(t,n.left)>=count){int x,y;split(t,n.left,count,x,y);n.left=y;pull(t,root);a=x;b=root;}else{int x,y;split(t,n.right,count-size(t,n.left)-1,x,y);n.right=x;pull(t,root);a=root;b=y;}}
int merge(std::array<Node,NMAX>& t,int a,int b){if(a<0)return b;if(b<0)return a;if(higher(t,a,b)){push(t,a);auto& n=t[static_cast<std::size_t>(a)];n.right=merge(t,n.right,b);pull(t,a);return a;}push(t,b);auto& n=t[static_cast<std::size_t>(b)];n.left=merge(t,a,n.left);pull(t,b);return b;}
void put64(std::uint8_t* out,std::size_t pos,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t j=0;j<8;++j)out[pos+j]=static_cast<std::uint8_t>(bits>>(8*j));}
}
extern "C" std::int64_t range_reverse_range_sum(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(!input||length<2||length>INPUT_MAX)return -1;auto n64=input[0],q64=input[1];if(n64<0||n64>static_cast<std::int64_t>(NMAX)||q64<0||q64>static_cast<std::int64_t>(QMAX))return -1;auto n=static_cast<std::size_t>(n64),q=static_cast<std::size_t>(q64),offset=std::size_t(2);if(length<2+n)return -1;
    std::array<Node,NMAX> nodes{};for(std::size_t i=0;i<n;++i){auto value=input[offset++];if(value<0||value>1000000000)return -1;nodes[i]=Node{-1,-1,1,value,value,priority_for(i),false};}
    std::array<Operation,QMAX> ops{};std::size_t query_count=0;for(std::size_t i=0;i<q;++i){if(offset+3>length)return -1;auto kind=input[offset],left=input[offset+1],right=input[offset+2];offset+=3;if((kind!=0&&kind!=1)||left<0||left>right||right>n64)return -1;ops[i]={static_cast<int>(kind),static_cast<int>(left),static_cast<int>(right)};if(kind==1)++query_count;}
    if(offset!=length)return -1;int root=-1;for(std::size_t i=0;i<n;++i)root=merge(nodes,root,static_cast<int>(i));std::array<std::int64_t,QMAX> answers{};std::size_t answer_count=0;
    for(std::size_t i=0;i<q;++i){auto op=ops[i];int prefix,tail,middle,suffix;split(nodes,root,op.right,prefix,suffix);split(nodes,prefix,op.left,prefix,middle);if(op.kind==0)reverse_node(nodes,middle);else answers[answer_count++]=sum(nodes,middle);root=merge(nodes,merge(nodes,prefix,middle),suffix);}
    auto bytes=8*query_count;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<query_count;++i)put64(output,8*i,answers[i]);return static_cast<std::int64_t>(bytes);
}
