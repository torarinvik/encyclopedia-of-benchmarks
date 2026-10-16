#include <cstddef>
#include <cstdint>

extern "C" std::int64_t two_pointers_pair_exists(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 258) return -1;
    const auto target = input[0], n = input[1];
    if (n < 0 || n > 256 || length != 2 + static_cast<std::size_t>(n) || target < -2000000 || target > 2000000) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) {
        const auto value = input[2 + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (i > 0 && input[1 + i] > value) return -1;
    }
    if (n < 2) return 0;
    std::size_t left = 0, right = static_cast<std::size_t>(n) - 1;
    while (left < right) {
        const auto sum = input[2 + left] + input[2 + right];
        if (sum == target) return 1;
        if (sum < target) ++left;
        else --right;
    }
    return 0;
}
