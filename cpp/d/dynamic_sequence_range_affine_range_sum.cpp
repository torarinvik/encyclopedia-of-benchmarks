#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MOD = 998244353;
constexpr int NMAX = 32, QMAX = 32, NODEMAX = NMAX + QMAX, INPUTMAX = 195, NONE = -1;
struct Node { int left=NONE, right=NONE, size=1; std::int64_t value=0, sum=0, mul=1, add=0; std::uint64_t priority=0; bool reversed=false; };
struct Operation { int kind=0, left=0, right=0, node=NONE; std::int64_t mul=0, add=0; };
std::uint64_t priority_for(std::size_t id) { std::int64_t state=1; for(std::size_t i=0;i<=id;++i) state=(state*48271)%2147483647; return static_cast<std::uint64_t>(state); }
int size(const std::array<Node,NODEMAX>& t,int x) { return x<0?0:t[static_cast<std::size_t>(x)].size; }
std::int64_t sum(const std::array<Node,NODEMAX>& t,int x) { return x<0?0:t[static_cast<std::size_t>(x)].sum; }
bool higher(const std::array<Node,NODEMAX>& t,int a,int b) { const auto& x=t[static_cast<std::size_t>(a)]; const auto& y=t[static_cast<std::size_t>(b)]; return x.priority!=y.priority?x.priority>y.priority:a>b; }
void pull(std::array<Node,NODEMAX>& t,int x) { auto& n=t[static_cast<std::size_t>(x)]; n.size=1+size(t,n.left)+size(t,n.right); n.sum=(n.value+sum(t,n.left)+sum(t,n.right))%MOD; }
void affine(std::array<Node,NODEMAX>& t,int x,std::int64_t m,std::int64_t a) { if(x<0)return; auto& n=t[static_cast<std::size_t>(x)]; n.value=(m*n.value+a)%MOD; n.sum=(m*n.sum+a*n.size)%MOD; n.mul=(m*n.mul)%MOD; n.add=(m*n.add+a)%MOD; }
void reverse_node(std::array<Node,NODEMAX>& t,int x) { if(x<0)return; auto& n=t[static_cast<std::size_t>(x)]; std::swap(n.left,n.right); n.reversed=!n.reversed; }
void push(std::array<Node,NODEMAX>& t,int x) { auto& n=t[static_cast<std::size_t>(x)]; if(n.mul!=1||n.add!=0){affine(t,n.left,n.mul,n.add);affine(t,n.right,n.mul,n.add);n.mul=1;n.add=0;} if(n.reversed){reverse_node(t,n.left);reverse_node(t,n.right);n.reversed=false;} }
void split(std::array<Node,NODEMAX>& t,int root,int count,int& a,int& b) { if(root<0){a=b=NONE;return;} push(t,root); auto& n=t[static_cast<std::size_t>(root)]; if(size(t,n.left)>=count){int x,y;split(t,n.left,count,x,y);n.left=y;pull(t,root);a=x;b=root;}else{int x,y;split(t,n.right,count-size(t,n.left)-1,x,y);n.right=x;pull(t,root);a=root;b=y;} }
int merge(std::array<Node,NODEMAX>& t,int a,int b) { if(a<0)return b;if(b<0)return a;if(higher(t,a,b)){push(t,a);auto& n=t[static_cast<std::size_t>(a)];n.right=merge(t,n.right,b);pull(t,a);return a;}push(t,b);auto& n=t[static_cast<std::size_t>(b)];n.left=merge(t,a,n.left);pull(t,b);return b; }
void put64(std::uint8_t* out,std::size_t at,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j)out[at+j]=static_cast<std::uint8_t>(bits>>(8*j));}
}

extern "C" std::int64_t dynamic_sequence_range_affine_range_sum(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(!input||length<2||length>INPUTMAX)return -1;
    auto n64=input[0],q64=input[1];if(n64<0||n64>NMAX||q64<0||q64>QMAX)return -1;
    auto n=static_cast<std::size_t>(n64),q=static_cast<std::size_t>(q64),offset=std::size_t(2);if(length<2+n)return -1;
    std::array<Node,NODEMAX> nodes{};
    for(std::size_t i=0;i<n;++i){auto v=input[offset++];if(v<0||v>=MOD)return -1;nodes[i]=Node{NONE,NONE,1,v,v,1,0,priority_for(i),false};}
    std::array<Operation,QMAX> ops{};std::size_t current=n,node_count=n,queries=0;
    for(std::size_t i=0;i<q;++i){if(offset>=length)return -1;auto tag=input[offset++];if(tag<0||tag>4)return -1;Operation op{};op.kind=static_cast<int>(tag);
        if(tag==0){if(offset+2>length)return -1;auto at=input[offset++],v=input[offset++];if(at<0||static_cast<std::uint64_t>(at)>current||current>=NODEMAX||v<0||v>=MOD)return -1;op.left=static_cast<int>(at);op.node=static_cast<int>(node_count);nodes[node_count]=Node{NONE,NONE,1,v,v,1,0,priority_for(node_count),false};++node_count;++current;}
        else if(tag==1){if(offset>=length)return -1;auto at=input[offset++];if(at<0||static_cast<std::uint64_t>(at)>=current)return -1;op.left=static_cast<int>(at);--current;}
        else if(tag==2||tag==4){if(offset+2>length)return -1;auto l=input[offset++],r=input[offset++];if(l<0||l>r||static_cast<std::uint64_t>(r)>current)return -1;op.left=static_cast<int>(l);op.right=static_cast<int>(r);if(tag==4)++queries;}
        else{if(offset+4>length)return -1;auto l=input[offset++],r=input[offset++],m=input[offset++],a=input[offset++];if(l<0||l>r||static_cast<std::uint64_t>(r)>current||m<0||m>=MOD||a<0||a>=MOD)return -1;op.left=static_cast<int>(l);op.right=static_cast<int>(r);op.mul=m;op.add=a;}
        ops[i]=op;
    }
    if(offset!=length)return -1;int root=NONE;for(std::size_t i=0;i<n;++i)root=merge(nodes,root,static_cast<int>(i));std::array<std::int64_t,QMAX> answers{};std::size_t answer_count=0;
    for(std::size_t i=0;i<q;++i){const auto op=ops[i];int prefix,suffix,middle;split(nodes,root,op.left,prefix,suffix);if(op.kind==0){root=merge(nodes,merge(nodes,prefix,op.node),suffix);continue;}if(op.kind==1){split(nodes,suffix,1,middle,suffix);root=merge(nodes,prefix,suffix);continue;}split(nodes,suffix,op.right-op.left,middle,suffix);if(op.kind==2)reverse_node(nodes,middle);else if(op.kind==3)affine(nodes,middle,op.mul,op.add);else answers[answer_count++]=sum(nodes,middle);root=merge(nodes,merge(nodes,prefix,middle),suffix);}
    auto bytes=8*queries;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<queries;++i)put64(output,8*i,answers[i]);return static_cast<std::int64_t>(bytes);
}
