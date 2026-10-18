#include <cstddef>
#include <cstdint>

extern "C" std::int64_t permutation_count(const std::int64_t* input, std::size_t input_length) {
    if (input == nullptr || input_length != 2) return -1;
    const auto n = input[0], r = input[1];
    if (n < 0 || n > 18 || r < 0 || r > 18) return -1;
    std::int64_t result = 1;
    if (r > n) {
        for (std::int64_t factor = 2; factor <= n; ++factor) result *= factor;
    } else {
        for (std::int64_t i = 0; i < r; ++i) result *= n - i;
    }
    return result;
}
