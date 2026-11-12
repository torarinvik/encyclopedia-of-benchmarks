#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t N=8, M=32, BASE=8, INPUT_MAX=2+2*N+4*M;
constexpr std::int64_t INF=INT64_C(1)<<60;
struct Node { bool valid=false; std::size_t winner=0; std::int64_t best=0, lazy=0, deadline=INF; };
struct Op { std::int64_t kind=0, left=0, right=0, delta=0; };

void pull(std::array<Node,2*BASE>& tree,std::size_t node,const std::array<std::int64_t,N>& slope){
    const auto l=2*node,r=l+1;
    if(!tree[l].valid&&!tree[r].valid){tree[node].valid=false;tree[node].deadline=INF;return;}
    if(!tree[l].valid||!tree[r].valid){const auto c=tree[r].valid?r:l;tree[node].valid=true;tree[node].winner=tree[c].winner;tree[node].best=tree[c].best;tree[node].deadline=tree[c].deadline;return;}
    const auto li=tree[l].winner,ri=tree[r].winner;
    const bool choose_left=tree[l].best>tree[r].best||(tree[l].best==tree[r].best&&slope[li]>slope[ri]);
    const auto win=choose_left?l:r,lose=choose_left?r:l;
    const auto wi=tree[win].winner,lo=tree[lose].winner;
    auto crossing=INF;
    if(slope[wi]<slope[lo]){const auto gap=tree[win].best-tree[lose].best,sg=slope[lo]-slope[wi];crossing=gap<=0?0:(gap+sg-1)/sg;}
    tree[node].valid=true;tree[node].winner=wi;tree[node].best=tree[win].best;
    tree[node].deadline=std::min(crossing,std::min(tree[l].deadline,tree[r].deadline));
}
void apply(std::array<Node,2*BASE>& tree,std::size_t node,const std::array<std::int64_t,N>& slope,std::int64_t delta){
    if(!tree[node].valid)return;tree[node].best+=slope[tree[node].winner]*delta;tree[node].lazy+=delta;tree[node].deadline-=delta;
}
void push(std::array<Node,2*BASE>& tree,std::size_t node,const std::array<std::int64_t,N>& slope){
    const auto delta=tree[node].lazy;if(delta==0||node>=BASE)return;apply(tree,2*node,slope,delta);apply(tree,2*node+1,slope,delta);tree[node].lazy=0;
}
void repair(std::array<Node,2*BASE>& tree,std::size_t node,const std::array<std::int64_t,N>& slope){
    if(node>=BASE||!tree[node].valid)return;push(tree,node,slope);
    if(tree[2*node].valid&&tree[2*node].deadline<=0)repair(tree,2*node,slope);
    if(tree[2*node+1].valid&&tree[2*node+1].deadline<=0)repair(tree,2*node+1,slope);pull(tree,node,slope);
}
void translate(std::array<Node,2*BASE>& tree,std::size_t node,std::size_t lo,std::size_t hi,
    std::size_t ql,std::size_t qr,std::int64_t delta,const std::array<std::int64_t,N>& slope){
    if(ql<=lo&&hi<=qr){apply(tree,node,slope,delta);repair(tree,node,slope);return;}
    push(tree,node,slope);const auto mid=(lo+hi)/2;
    if(ql<mid)translate(tree,2*node,lo,mid,ql,qr,delta,slope);
    if(mid<qr)translate(tree,2*node+1,mid,hi,ql,qr,delta,slope);pull(tree,node,slope);
}
std::int64_t query(std::array<Node,2*BASE>& tree,std::size_t node,std::size_t lo,std::size_t hi,
    std::size_t ql,std::size_t qr,const std::array<std::int64_t,N>& slope){
    if(ql<=lo&&hi<=qr)return tree[node].best;
    push(tree,node,slope);const auto mid=(lo+hi)/2;auto answer=std::numeric_limits<std::int64_t>::min();
    if(ql<mid)answer=query(tree,2*node,lo,mid,ql,qr,slope);
    if(mid<qr)answer=std::max(answer,query(tree,2*node+1,mid,hi,ql,qr,slope));pull(tree,node,slope);return answer;
}
void store(std::uint8_t* output,std::size_t at,std::int64_t value){const auto bits=static_cast<std::uint64_t>(value);for(std::size_t i=0;i<8;++i)output[at+i]=static_cast<std::uint8_t>(bits>>(8*i));}
}

extern "C" std::int64_t kinetic_tournament_tree(const std::int64_t* input,std::size_t length,
    std::uint8_t* output,std::size_t capacity) noexcept {
    if(input==nullptr||length<2||length>INPUT_MAX)return -1;
    const auto nr=input[0],mr=input[1];if(nr<1||nr>N||mr<1||mr>M)return -1;
    const auto n=static_cast<std::size_t>(nr),m=static_cast<std::size_t>(mr);std::size_t cur=2;
    std::array<std::int64_t,N> slope{},intercept{};
    for(std::size_t i=0;i<n;++i){if(cur+2>length)return -1;slope[i]=input[cur++];intercept[i]=input[cur++];if(slope[i]<-8||slope[i]>8||intercept[i]<-64||intercept[i]>64||(i&&slope[i]<=slope[i-1]))return -1;}
    std::array<Op,M> ops{};std::size_t query_count=0;
    for(std::size_t i=0;i<m;++i){if(cur>=length)return -1;const auto kind=input[cur++];
        if(kind==0){if(cur+3>length)return -1;const auto l=input[cur++],r=input[cur++],d=input[cur++];if(l<0||l>r||r>=nr||d<1||d>8)return -1;ops[i]={0,l,r,d};}
        else if(kind==1){if(cur+2>length)return -1;const auto l=input[cur++],r=input[cur++];if(l<0||l>r||r>=nr)return -1;ops[i]={1,l,r,0};++query_count;}else return -1;
    }
    if(cur!=length||query_count==0)return -1;const auto required=8*query_count;if(output==nullptr||capacity<required)return -2;
    std::array<Node,2*BASE> tree{};for(auto& node:tree)node.deadline=INF;
    for(std::size_t i=0;i<n;++i){auto& leaf=tree[BASE+i];leaf.valid=true;leaf.winner=i;leaf.best=intercept[i];}
    for(std::size_t node=BASE-1;node>0;--node)pull(tree,node,slope);
    std::array<std::int64_t,M> answers{};std::size_t answer_count=0;
    for(std::size_t i=0;i<m;++i){const auto op=ops[i];if(op.kind==0)translate(tree,1,0,BASE,static_cast<std::size_t>(op.left),static_cast<std::size_t>(op.right)+1,op.delta,slope);else answers[answer_count++]=query(tree,1,0,BASE,static_cast<std::size_t>(op.left),static_cast<std::size_t>(op.right)+1,slope);}
    for(std::size_t i=0;i<answer_count;++i)store(output,8*i,answers[i]);return static_cast<std::int64_t>(required);
}
