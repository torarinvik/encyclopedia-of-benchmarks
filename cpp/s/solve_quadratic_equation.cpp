#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
namespace { constexpr std::int64_t LIMIT=1'000'000;
void put_f64_le(std::uint8_t* out,std::size_t offset,double value) noexcept {std::uint64_t bits;std::memcpy(&bits,&value,8);for(std::size_t b=0;b<8;++b)out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));} }
extern "C" std::int64_t solve_quadratic_equation(const std::int64_t* values,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
    if(values==nullptr||length!=2)return -1;const auto pi=values[0],qi=values[1];if(pi < -LIMIT||pi>LIMIT||qi < -LIMIT||qi>LIMIT)return -1;
    const double p=static_cast<double>(pi),q=static_cast<double>(qi);const double root=std::sqrt(p*p/4.0-q);if(std::isnan(root))return 0;
    const double x1=-p/2.0-root,x2=-p/2.0+root;
    if(x1==x2){if(output==nullptr||capacity<8)return -2;put_f64_le(output,0,x1);return 1;}
    if(output==nullptr||capacity<16)return -2;put_f64_le(output,0,x1);put_f64_le(output,8,x2);return 2;
}
