#include <cstddef>
#include <cstdint>
extern "C" std::int64_t print_amatrix_in_spiral_order(const std::int64_t* v,std::size_t n) noexcept {
 if(!v||n<3||n>66||v[0]<1||v[0]>8||v[1]<1||v[1]>8||n!=2+static_cast<std::size_t>(v[0]*v[1]))return -1;
 const std::size_t rows=v[0],cols=v[1];for(std::size_t i=2;i<n;++i)if(v[i]<INT32_MIN||v[i]>INT32_MAX)return -1;
 std::size_t top=0,bottom=rows-1,left=0,right=cols-1;std::uint32_t h=2166136261u;
 auto feed=[&](std::int64_t x){std::uint32_t u=static_cast<std::uint32_t>(static_cast<std::int32_t>(x));for(unsigned s=0;s<32;s+=8)h=(h^((u>>s)&255u))*16777619u;};
 while(top<=bottom&&left<=right){for(std::size_t c=left;c<=right;++c)feed(v[2+top*cols+c]);++top;for(std::size_t r=top;r<=bottom;++r)feed(v[2+r*cols+right]);if(right==0)break;--right;if(top<=bottom){for(std::size_t c=right+1;c>left;--c)feed(v[2+bottom*cols+c-1]);if(bottom==0)break;--bottom;}if(left<=right){for(std::size_t r=bottom+1;r>top;--r)feed(v[2+(r-1)*cols+left]);++left;}}return h;
}
