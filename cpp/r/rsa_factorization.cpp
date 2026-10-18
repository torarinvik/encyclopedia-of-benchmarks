#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
constexpr std::int64_t FACTOR_BASE = 65536;
constexpr std::size_t MAX_PACKED_LENGTH = 21;

std::int64_t gcd_i64(std::int64_t a, std::int64_t b) noexcept
{
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a;
}

std::int64_t power_mod_i64(std::int64_t base, std::int64_t exponent, std::int64_t modulus) noexcept
{
    std::int64_t result = 1, power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}
}

extern "C" std::int64_t rsa_factorization(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 4 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const auto d=packed[0], e=packed[1], modulus=packed[2], attempts=packed[3];
    if (d<1||d>1000000||e<1||e>1000000||modulus<3||modulus>65535||(modulus&1)==0||
        attempts<1||attempts>16||length!=static_cast<std::size_t>(4+attempts)) return INVALID_RESULT;
    const auto k=d*e-1;
    if (k<=0||(k&1)!=0) return INVALID_RESULT;
    for (std::int64_t i=0;i<attempts;++i) { const auto base=packed[4+static_cast<std::size_t>(i)];if(base<2||base>modulus-1)return INVALID_RESULT; }
    for (std::int64_t i=0;i<attempts;++i) {
        const auto base=packed[4+static_cast<std::size_t>(i)];
        auto t=k;
        while ((t&1)==0) {
            t/=2;
            const auto x=power_mod_i64(base,t,modulus);
            const auto factor=gcd_i64(x-1,modulus);
            if(x>1&&factor>1){auto p=factor,q=modulus/factor;if(p>q){const auto temp=p;p=q;q=temp;}return p*FACTOR_BASE+q;}
        }
    }
    return INVALID_RESULT;
}
