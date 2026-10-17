#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 64;
constexpr std::int64_t min_value = -1'000'000;
constexpr std::int64_t max_value = 1'000'000;
}

extern "C" std::int64_t minone(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_length) return -1;
    std::int64_t total = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = input[i];
        if (value < min_value || value > max_value) return -1;
        total += value * value;
    }
    return total;
}
