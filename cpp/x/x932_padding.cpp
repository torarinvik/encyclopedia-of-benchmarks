#include <cstddef>
#include <cstdint>
extern "C" std::int64_t x932_padding(const std::int64_t* values,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
 if(!values||length<1||length>257||values[0]<1||values[0]>64)return -1; auto block=static_cast<std::size_t>(values[0]),n=length-1; for(std::size_t i=1;i<length;i++)if(values[i]<0||values[i]>255)return -1; auto pad=block-(n%block),total=n+pad; if(total>capacity||!output)return -2; for(std::size_t i=0;i<n;i++)output[i]=static_cast<std::uint8_t>(values[i+1]); for(std::size_t i=n;i<total-1;i++)output[i]=0; output[total-1]=static_cast<std::uint8_t>(pad); return static_cast<std::int64_t>(total);
}
