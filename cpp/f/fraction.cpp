#include <cstddef>
#include <cstdint>

static std::int64_t gcd_pos(std::int64_t a, std::int64_t b) {
    if (a < 0) a = -a; if (b < 0) b = -b;
    while (b != 0) { auto r = a % b; a = b; b = r; }
    return a;
}
static void put_i64(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i=0;i<8;++i) out[at+i]=static_cast<std::uint8_t>(bits>>(8*i));
}
extern "C" std::int64_t fraction(const std::int64_t *v, std::size_t n, std::uint8_t *out, std::size_t cap) {
    if (!v || n!=4) return -1;
    auto n1=v[0],d1=v[1],n2=v[2],d2=v[3];
    if(n1 < -10000 || n1 > 10000 || n2 < -10000 || n2 > 10000 || d1 < -1000 || d1 > 1000 || d2 < -1000 || d2 > 1000 || d1==0 || d2==0) return -1;
    if(!out || cap<16) return -2;
    auto g=gcd_pos(d1,d2);
    auto numerator=(d2/g)*n1+(d1/g)*n2;
    auto denominator=(d1/g)*d2;
    auto reduce=gcd_pos(numerator,denominator);
    numerator/=reduce; denominator/=reduce;
    if(denominator<0){numerator=-numerator;denominator=-denominator;}
    put_i64(out,0,numerator);put_i64(out,8,denominator);return 16;
}
