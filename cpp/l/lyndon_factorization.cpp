#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 256; }
extern "C" std::int64_t lyndon_factorization(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (length < 1 || length > max_length + 1 || input == nullptr) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_length) ||
        length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 97 || input[i + 1] > 122) return -1;
    const std::size_t required = 2 * n;
    if (capacity < required || (required != 0 && output == nullptr)) return -2;
    std::size_t start = 0, out = 0;
    while (start < n) {
        std::size_t candidate = start + 1, match = start;
        while (candidate < n && input[match + 1] <= input[candidate + 1]) {
            if (input[match + 1] < input[candidate + 1]) match = start; else ++match;
            ++candidate;
        }
        const auto factor_length = candidate - match;
        while (start <= match) {
            for (std::size_t j = 0; j < factor_length; ++j) output[out++] = static_cast<std::uint8_t>(input[start + j + 1]);
            output[out++] = 0;
            start += factor_length;
        }
    }
    return static_cast<std::int64_t>(out);
}
