#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_degree = 16;
constexpr std::size_t max_parseable_length = 21;

std::int64_t reduce_field(std::int64_t value) noexcept {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}
}

extern "C" std::int64_t chebyshev_clenshaw_evaluation(const std::int64_t* input,
                                                        std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_parseable_length) return -1;
    const auto degree_value = input[0];
    if (degree_value < 0 || degree_value > static_cast<std::int64_t>(max_degree)) return -1;
    const auto degree = static_cast<std::size_t>(degree_value);
    if (length != degree + 3) return -1;
    const auto x = input[1];
    if (x < 0 || x >= modulus) return -1;
    for (std::size_t i = 0; i <= degree; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= modulus) return -1;

    const auto twice_x = 2 * x % modulus;
    std::int64_t next_one = 0;
    std::int64_t next_two = 0;
    for (auto k = degree; k > 0; --k) {
        const auto current = reduce_field(input[2 + k] + twice_x * next_one - next_two);
        next_two = next_one;
        next_one = current;
    }
    return reduce_field(input[2] + x * next_one - next_two);
}
