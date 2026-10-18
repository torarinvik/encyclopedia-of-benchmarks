#include <cstddef>
#include <cstdint>

extern "C" std::int64_t smallest_prime_factor(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length != 1) return -1;
    const std::int64_t n = input[0];
    if (n < 2 || n > 1'000'005) return -1;
    for (std::int64_t factor = 2; factor <= n / factor; ++factor)
        if (n % factor == 0) return factor;
    return n;
}
