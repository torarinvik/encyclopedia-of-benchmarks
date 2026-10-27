#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxItems=6, MaxBidders=12, MaxInput=32, MaxOutput=104;
void put(std::uint8_t *out,std::size_t at,std::int64_t x){std::uint64_t b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(b&255);b>>=8;}}
}
extern "C" std::int64_t truthful_multiunit_ca_greedy2(const std::int64_t *a,std::size_t n,std::uint8_t *out,std::size_t cap){
 if(!a||n<5||n>MaxInput||a[0]<2||a[0]>MaxItems||a[1]<1||a[1]>MaxBidders)return -1;int r=static_cast<int>(a[0]),k=static_cast<int>(a[1]);if(n!=static_cast<std::size_t>(2+r+2*k))return -1;
 std::array<int,MaxItems>b{};std::array<double,MaxItems>y{};int B=100;for(int e=0;e<r;++e){if(a[2+e]<1||a[2+e]>8)return -1;b[e]=static_cast<int>(a[2+e]);if(b[e]<B)B=b[e];y[e]=1.0/static_cast<double>(b[e]);}
 std::array<int,MaxBidders>value{},mask{};for(int i=0;i<k;++i){auto v=a[2+r+2*i],m=a[3+r+2*i];if(v<1||v>100||m<1||m>=(1<<r))return -1;value[i]=static_cast<int>(v);mask[i]=static_cast<int>(m);}
 const double threshold=std::pow(2.718281828459045,static_cast<double>(B))*static_cast<double>(r);std::array<bool,MaxBidders>chosen{};std::array<int,MaxBidders>order{};int count=0;
 while(count<k){int best=-1;double bestScore=-1.0;for(int i=0;i<k;++i)if(!chosen[i]){double den=0.0;for(int e=0;e<r;++e)if(mask[i]&(1<<e))den+=y[e];double score=static_cast<double>(value[i])/den;if(best<0||score>bestScore){best=i;bestScore=score;}}if(best<0)break;chosen[best]=true;order[count++]=best;for(int e=0;e<r;++e)if(mask[best]&(1<<e))y[e]*=std::pow(threshold,1.0/static_cast<double>(b[e]));double dual=0.0;for(int e=0;e<r;++e)dual+=static_cast<double>(b[e])*y[e];if(dual>=threshold)break;}
 const std::size_t bytes=8*static_cast<std::size_t>(1+count);if(!out||cap<bytes)return -2;std::array<std::uint8_t,MaxOutput>staged{};put(staged.data(),0,count);for(int i=0;i<count;++i)put(staged.data(),8*static_cast<std::size_t>(i+1),order[i]);for(std::size_t i=0;i<bytes;++i)out[i]=staged[i];return static_cast<std::int64_t>(bytes);
}
