#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t NMAX=128,QMAX=32;
struct Query { std::size_t left,right,id,block; };
std::size_t lower_bound_i64(const std::int64_t *a,std::size_t n,std::int64_t x){
    std::size_t lo=0,hi=n;while(lo<hi){auto mid=lo+(hi-lo)/2;if(a[mid]<x)lo=mid+1;else hi=mid;}return lo;
}
std::int64_t bit_sum(const std::int64_t bit[NMAX+1],std::size_t count){
    std::int64_t sum=0;while(count){sum+=bit[count];count-=count&(~count+1);}return sum;
}
void bit_add(std::int64_t bit[NMAX+1],std::size_t rank,int delta){
    for(std::size_t i=rank+1;i<=NMAX;i+=i&(~i+1))bit[i]+=delta;
}
bool before(const Query&a,const Query&b){
    if(a.block!=b.block)return a.block<b.block;
    if(a.right!=b.right)return (a.block&1)?a.right>b.right:a.right<b.right;
    return a.id<b.id;
}
void write_i64_le(std::uint8_t*out,std::size_t at,std::int64_t value){
    auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}

extern "C" std::int64_t static_range_inversions_query(const std::int64_t*input,
        std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(!input||length<2||length>195)return -1;
    auto n64=input[0],q64=input[1];if(n64<1||n64>128||q64<1||q64>32)return -1;
    auto n=static_cast<std::size_t>(n64),q=static_cast<std::size_t>(q64);if(length!=2+n+2*q)return -1;
    std::int64_t values[NMAX],sorted[NMAX];
    for(std::size_t i=0;i<n;++i){values[i]=input[2+i];if(values[i]<0||values[i]>1'000'000'000)return -1;sorted[i]=values[i];}
    std::sort(sorted,sorted+n);auto distinct=static_cast<std::size_t>(std::unique(sorted,sorted+n)-sorted);
    std::size_t rank[NMAX];for(std::size_t i=0;i<n;++i)rank[i]=lower_bound_i64(sorted,distinct,values[i]);
    std::size_t block=1;while((block+1)*(block+1)<=n)++block;
    Query queries[QMAX];std::size_t off=2+n;
    for(std::size_t k=0;k<q;++k){auto l=input[off++],r=input[off++];if(l<0||l>=r||r>n64)return -1;queries[k]={static_cast<std::size_t>(l),static_cast<std::size_t>(r),k,static_cast<std::size_t>(l)/block};}
    std::sort(queries,queries+q,before);
    std::int64_t bit[NMAX+1]{},answers[QMAX]{};std::size_t left=0,right=0,window=0;std::int64_t inversions=0;
    for(std::size_t qi=0;qi<q;++qi){const auto z=queries[qi];
        while(left>z.left){--left;auto x=rank[left];inversions+=bit_sum(bit,x);bit_add(bit,x,1);++window;}
        while(right<z.right){auto x=rank[right];inversions+=static_cast<std::int64_t>(window)-bit_sum(bit,x+1);bit_add(bit,x,1);++window;++right;}
        while(left<z.left){auto x=rank[left];inversions-=bit_sum(bit,x);bit_add(bit,x,-1);--window;++left;}
        while(right>z.right){--right;auto x=rank[right];inversions-=static_cast<std::int64_t>(window)-bit_sum(bit,x+1);bit_add(bit,x,-1);--window;}
        answers[z.id]=inversions;
    }
    auto bytes=8*q;if(!output||capacity<bytes)return -2;
    for(std::size_t k=0;k<q;++k)write_i64_le(output,8*k,answers[k]);return static_cast<std::int64_t>(bytes);
}
