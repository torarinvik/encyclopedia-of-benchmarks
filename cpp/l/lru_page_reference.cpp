/* Return page-reference hit/eviction events and final MRU-to-LRU state. */
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t lru_page_reference(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap) noexcept {
 if(!in||len<2)return -1;auto c64=in[0],n64=in[1];if(c64<1||c64>64||(c64&(c64-1))||n64<0||n64>256||len!=static_cast<std::size_t>(n64)+2)return -1;
 auto c=static_cast<std::size_t>(c64),n=static_cast<std::size_t>(n64);for(std::size_t i=0;i<n;++i)if(in[2+i]<0||in[2+i]>1000000)return -1;
 std::int64_t cache[64],events[512];std::size_t used=0;
 for(std::size_t i=0;i<n;++i){auto page=in[2+i];std::int64_t evicted=-1;std::size_t p=0;while(p<used&&cache[p]!=page)++p;if(p<used){for(std::size_t j=p;j>0;--j)cache[j]=cache[j-1];cache[0]=page;events[2*i]=1;}else{if(used==c){evicted=cache[used-1];--used;}for(std::size_t j=used;j>0;--j)cache[j]=cache[j-1];cache[0]=page;++used;events[2*i]=0;}events[2*i+1]=evicted;}
 auto words=2*n+2+used;if(!out||cap<words*8)return -2;std::int64_t result[578];std::size_t k=0;result[k++]=static_cast<std::int64_t>(n);for(std::size_t i=0;i<2*n;++i)result[k++]=events[i];result[k++]=static_cast<std::int64_t>(used);for(std::size_t i=0;i<used;++i)result[k++]=cache[i];
 for(std::size_t i=0;i<k;++i){auto bits=static_cast<std::uint64_t>(result[i]);for(std::size_t b=0;b<8;++b)out[i*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}return static_cast<std::int64_t>(words*8);
}
