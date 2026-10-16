/* Damm validation and check-digit calculation over decimal digit arrays. */
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_digits=256; constexpr std::int8_t table[100]={0, 3, 1, 7, 5, 9, 8, 6, 4, 2, 7, 0, 9, 2, 1, 5, 4, 8, 6, 3, 4, 2, 0, 6, 8, 7, 1, 3, 5, 9, 1, 7, 5, 0, 9, 8, 3, 4, 2, 6, 6, 1, 2, 3, 0, 4, 5, 9, 7, 8, 3, 6, 7, 4, 2, 0, 9, 5, 8, 1, 5, 8, 6, 9, 7, 2, 0, 1, 3, 4, 8, 9, 4, 5, 3, 6, 2, 0, 1, 7, 9, 4, 3, 8, 6, 1, 7, 2, 0, 5, 2, 5, 8, 1, 4, 3, 6, 7, 9, 0}; }
extern "C" std::int64_t damm(const std::int64_t *input,std::size_t length) noexcept {
 if(input==nullptr||length<3||length>max_digits+2)return -1;const auto mode=input[0],n=input[1];
 if((mode!=0&&mode!=1)||n<1||n>static_cast<std::int64_t>(max_digits)||length!=static_cast<std::size_t>(n)+2)return -1;
 int state=0;for(std::size_t i=0;i<static_cast<std::size_t>(n);++i){const auto d=input[i+2];if(d<0||d>9)return -1;state=table[state*10+static_cast<int>(d)];}
 return mode==0?(state==0?1:0):state;
}
