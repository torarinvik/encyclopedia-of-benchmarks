#include <cstddef>
#include <cstdint>
namespace { constexpr int max_values=512;int choose(const std::int64_t*v,const int*t,int l,int r){if(l<0)return r;if(r<0)return l;return v[l]<=v[r]?l:r;}void put(std::uint8_t*out,std::size_t o,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t i=0;i<8;++i)out[o+i]=static_cast<std::uint8_t>(b>>(8*i));} }
extern "C" std::int64_t tournament_sort(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(!input||length<1||input[0]<0||input[0]>max_values)return -1;auto n=static_cast<std::size_t>(input[0]);if(length!=1+n)return -1;std::int64_t values[max_values];for(std::size_t i=0;i<n;++i){if(input[i+1]<INT32_MIN||input[i+1]>INT32_MAX)return -1;values[i]=input[i+1];}
 std::size_t leaves=1;while(leaves<n)leaves*=2;int tree[2*max_values+1];for(std::size_t i=0;i<2*leaves;++i)tree[i]=-1;for(std::size_t i=0;i<n;++i)tree[leaves+i]=static_cast<int>(i);for(std::size_t node=leaves;node-->1;)tree[node]=choose(values,tree,static_cast<int>(2*node),static_cast<int>(2*node+1));
 auto bytes=(1+n)*8;if(!output||capacity<bytes)return -2;put(output,0,static_cast<std::int64_t>(n));for(std::size_t out=0;out<n;++out){int w=tree[1];put(output,(1+out)*8,values[w]);std::size_t node=leaves+static_cast<std::size_t>(w);tree[node]=-1;while(node>1){node/=2;tree[node]=choose(values,tree,static_cast<int>(2*node),static_cast<int>(2*node+1));}}return static_cast<std::int64_t>(bytes);
}
