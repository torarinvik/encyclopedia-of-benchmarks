#include <cstddef>
#include <cstdint>
namespace{constexpr std::size_t N=32,L=35;void put64(std::uint8_t*o,std::size_t p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255U);b>>=8;}}}
extern "C" std::int64_t max_average_length_bounded_segment(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<4||len>L)return -1;auto n64=in[0],l64=in[1],u64=in[2];if(n64<1||n64>N||l64<1||u64<l64||u64>n64||len!=3+static_cast<std::size_t>(n64))return -1;auto n=static_cast<std::size_t>(n64),lower=static_cast<std::size_t>(l64),upper=static_cast<std::size_t>(u64);
 for(std::size_t i=0;i<n;++i)if(in[3+i]<-10000||in[3+i]>10000)return -1;if(!out||cap<32)return -2;
 std::int64_t bs=0,bl=1,bstart=0,bend=0;bool have=false;
 for(std::size_t start=0;start<n;++start){std::int64_t sum=0;auto limit=start+upper<n?start+upper:n;for(std::size_t end=start+1;end<=limit;++end){sum+=in[3+end-1];auto length=end-start;if(length<lower)continue;auto left=sum*bl,right=bs*static_cast<std::int64_t>(length);
  if(!have||left>right||(left==right&&(length<static_cast<std::size_t>(bl)||(length==static_cast<std::size_t>(bl)&&(start<static_cast<std::size_t>(bstart)||(start==static_cast<std::size_t>(bstart)&&end<static_cast<std::size_t>(bend))))))){bs=sum;bl=static_cast<std::int64_t>(length);bstart=static_cast<std::int64_t>(start);bend=static_cast<std::int64_t>(end);have=true;}
 }}put64(out,0,bs);put64(out,8,bl);put64(out,16,bstart);put64(out,24,bend);return 32;
}
