#include <cstddef>
#include <cstdint>
namespace {
std::size_t append_i64(std::uint8_t* out,std::size_t at,std::int64_t x){if(x<0){out[at++]='-';x=-x;}if(x==0){out[at++]='0';return at;}std::uint8_t rev[24];std::size_t n=0;while(x){rev[n++]=std::uint8_t('0'+x%10);x/=10;}while(n)out[at++]=rev[--n];return at;}
std::int64_t raw(std::uint8_t*out,std::int64_t x){return std::int64_t(append_i64(out,0,x));}
std::int64_t scaled(std::uint8_t*out,std::int64_t x,std::int64_t scale,const char*name,std::size_t size){if(x%scale)return -1;auto at=append_i64(out,0,x/scale);out[at++]='.';out[at++]='0';out[at++]=' ';for(std::size_t i=0;i<size;++i)out[at++]=std::uint8_t(name[i]);return std::int64_t(at);}
}
extern "C" std::int64_t prefix_conversions_string(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap) noexcept {if(!v||n!=2||(v[0]!=0&&v[0]!=1)||v[1]<-1000000000000LL||v[1]>1000000000000LL)return -1;if(!out||cap<8192)return -2;auto x=v[1];if(x<=0)return raw(out,x);if(v[0]==0){if(x>1000000000)return scaled(out,x,1000000000,"giga",4);if(x>1000000)return scaled(out,x,1000000,"mega",4);if(x>1000)return scaled(out,x,1000,"kilo",4);if(x>100)return scaled(out,x,100,"hecto",5);if(x>10)return scaled(out,x,10,"deca",4);}else{if(x>1073741824)return scaled(out,x,1073741824,"giga",4);if(x>1048576)return scaled(out,x,1048576,"mega",4);if(x>1024)return scaled(out,x,1024,"kilo",4);}return raw(out,x);}
