#include <cstddef>
#include <cstdint>
namespace { void put(uint8_t*o,int64_t x){uint64_t u=static_cast<uint64_t>(x);for(size_t b=0;b<8;++b)o[b]=static_cast<uint8_t>(u>>(8*b));} }
extern "C" int64_t mediabench_mpeg2_motion_vector_component(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=4)return -1;int64_t pred=v[0],rs=v[1],code=v[2],res=v[3];if(rs<0||rs>6||code < -16||code>16)return -1;int64_t lim=16LL<<rs;if(pred < -lim||pred>=lim)return -1;if((code==0||rs==0)?res!=0:(res<0||res>=(1LL<<rs)))return -1;int64_t vec=pred;if(code>0){vec+=((code-1)<<rs)+res+1;if(vec>=lim)vec-=2*lim;}else if(code<0){vec-=((-code-1)<<rs)+res+1;if(vec < -lim)vec+=2*lim;}if(!out||cap<8)return -2;put(out,vec);return 8;}
