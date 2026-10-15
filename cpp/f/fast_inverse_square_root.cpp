#include <cmath>
#include <cstdint>
#include <cstring>

namespace {
constexpr double MIN_VALUE = 1e-6;
constexpr double MAX_VALUE = 1e6;
}

// Match PHP's float32 pack/unpack using IEEE-754 binary32 bit reinterpretation.
extern "C" double fast_inverse_square_root(double value) noexcept
{
    if (std::isnan(value) || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    const float seed_input = static_cast<float>(value);
    std::int32_t bits;
    std::memcpy(&bits, &seed_input, sizeof(bits));
    bits = INT32_C(0x5f3759df) - (bits >> 1);
    float seed;
    std::memcpy(&seed, &bits, sizeof(seed));
    const double y = static_cast<double>(seed);
    return y * (1.5 - 0.5 * value * y * y);
}
