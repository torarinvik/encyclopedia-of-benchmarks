#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_keys = 128, none = -1;
struct Node { std::int64_t key; int parent, child, left, right, degree; };
void store_i64_le(std::uint8_t* out, std::size_t at, std::int64_t value) noexcept {
    auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t b=0;b<8;++b) out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
void remove_ring(std::array<Node,max_keys>& a,int x) noexcept { a[a[x].left].right=a[x].right; a[a[x].right].left=a[x].left; }
void add_root(std::array<Node,max_keys>& a,int& minimum,int x) noexcept {
    a[x].parent=none;
    if(minimum==none){a[x].left=a[x].right=x;minimum=x;}
    else{int m=minimum,r=a[m].right;a[x].left=m;a[x].right=r;a[m].right=x;a[r].left=x;if(a[x].key<a[m].key)minimum=x;}
}
void link_child(std::array<Node,max_keys>& a,int p,int c) noexcept {
    remove_ring(a,c);a[c].parent=p;
    if(a[p].child==none){a[c].left=a[c].right=c;a[p].child=c;}
    else{int x=a[p].child,r=a[x].right;a[c].left=x;a[c].right=r;a[x].right=c;a[r].left=c;}
    ++a[p].degree;
}
void consolidate(std::array<Node,max_keys>& a,int& minimum) noexcept {
    int roots[max_keys],count=0,x=minimum;
    if(x==none)return;
    do{roots[count++]=x;x=a[x].right;}while(x!=minimum);
    int degree[max_keys+1];for(int& d:degree)d=none;
    for(int i=0;i<count;++i){x=roots[i];if(a[x].parent!=none)continue;int d=a[x].degree;while(degree[d]!=none){int y=degree[d];if(a[y].key<a[x].key){int t=x;x=y;y=t;}degree[d]=none;link_child(a,x,y);d=a[x].degree;}degree[d]=x;}
    minimum=none;for(int d:degree)if(d!=none)add_root(a,minimum,d);
}
}

extern "C" std::int64_t fibonacci_heap(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
    if((input==nullptr&&length>0)||length>max_keys)return -1;
    for(std::size_t i=0;i<length;++i)if(input[i]<INT32_MIN||input[i]>INT32_MAX)return -1;
    const std::size_t bytes=length*8;
    if(capacity<bytes||(length>0&&output==nullptr))return -2;
    std::array<Node,max_keys> a{};int minimum=none;
    for(std::size_t i=0;i<length;++i){a[i].key=input[i];a[i].parent=a[i].child=none;a[i].degree=0;a[i].left=a[i].right=static_cast<int>(i);add_root(a,minimum,static_cast<int>(i));}
    for(std::size_t out=0;out<length;++out){int z=minimum;store_i64_le(output,out*8,a[z].key);
        if(a[z].child!=none){int children[max_keys],c=a[z].child,k=0;do{children[k++]=c;c=a[c].right;}while(c!=a[z].child);for(int j=0;j<k;++j)add_root(a,minimum,children[j]);}
        remove_ring(a,z);if(a[z].right==z)minimum=none;else{minimum=a[z].right;consolidate(a,minimum);}
    }
    return static_cast<std::int64_t>(bytes);
}
