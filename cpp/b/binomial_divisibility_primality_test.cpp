#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 1000;
}

extern "C" std::int64_t binomial_divisibility_primality_test(
    const std::int64_t *packed, std::size_t length) noexcept {
    if (packed == nullptr || length != 1) return -1;
    const auto n_value = packed[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_value);

    std::array<std::int64_t, max_n + 1> row{};
    row[0] = 1;
    for (std::size_t degree = 1; degree <= n; ++degree) {
        row[degree] = 1;
        for (std::size_t index = degree - 1; index > 0; --index)
            row[index] = (row[index] + row[index - 1]) % n_value;
    }
    for (std::size_t index = 1; index < n; ++index)
        if (row[index] != 0) return 0;
    return 1;
}
