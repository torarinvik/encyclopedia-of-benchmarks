#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_length = 2;
constexpr std::int64_t max_n = 30;

std::int64_t riordan_number_value(std::int64_t n) noexcept {
    std::array<std::int64_t, 31> values{};
    values[0] = 1;
    for (std::int64_t size = 2; size <= n; ++size) {
        values[size] = (size - 1) * (2 * values[size - 1] + 3 * values[size - 2])
                       / (size + 1);
    }
    return values[n];
}
}

extern "C" std::int64_t riordan_number(const std::int64_t* input,
                                        std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 0 || input[0] > max_n) return -1;
    return riordan_number_value(input[0]);
}
