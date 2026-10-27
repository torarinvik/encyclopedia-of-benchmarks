#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t N=16,K=8,L=35; void put64(std::uint8_t*o,std::size_t p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t j=0;j<8;j++){o[p+j]=static_cast<std::uint8_t>(b&255U);b>>=8;}} }
extern "C" std::int64_t min_hash_bottom_k(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<4||len>L)return -1;auto nr=in[0],kr=in[1];if(nr<1||nr>N||kr<1||kr>K||len!=2+2*static_cast<std::size_t>(nr))return -1;auto n=static_cast<std::size_t>(nr),k=static_cast<std::size_t>(kr);std::size_t ids[N],count=0;std::int64_t ranks[N];
 for(std::size_t i=0;i<n;i++){auto id=in[2+2*i],rank=in[3+2*i];if(id<0||id>=N||rank<0||rank>1000)return -1;for(std::size_t j=0;j<i;j++)if(id==static_cast<std::int64_t>(ids[j]))return -1;std::size_t pos=0;while(pos<count&&(ranks[pos]<rank||(ranks[pos]==rank&&ids[pos]<static_cast<std::size_t>(id)))pos++;if(pos<k){std::size_t next=count<k?count:k-1;while(next>pos){ids[next]=ids[next-1];ranks[next]=ranks[next-1];next--;}ids[pos]=static_cast<std::size_t>(id);ranks[pos]=rank;if(count<k)count++;}}
 auto bytes=8*(1+2*count);if(!out||cap<bytes)return -2;put64(out,0,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;i++){put64(out,8+16*i,static_cast<std::int64_t>(ids[i]));put64(out,16+16*i,ranks[i]);}return static_cast<std::int64_t>(bytes);
}
