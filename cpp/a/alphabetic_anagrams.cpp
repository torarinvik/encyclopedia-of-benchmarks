#include <array>
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t factorial(std::int64_t value) {
    std::int64_t result = 1;
    for (std::int64_t factor = 2; factor <= value; ++factor) result *= factor;
    return result;
}
}

extern "C" std::int64_t alphabetic_anagrams(const std::int64_t *input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 10) return -1;
    const auto n = input[0];
    if (n < 0 || n > 8 || length != static_cast<std::size_t>(n) + 1) return -1;
    std::array<std::int64_t, 26> frequency{};
    for (std::int64_t position = 0; position < n; ++position) {
        const auto symbol = input[position + 1];
        if (symbol < 0 || symbol > 25) return -1;
        ++frequency[static_cast<std::size_t>(symbol)];
    }
    std::int64_t denominator = 1;
    for (const auto count : frequency) denominator *= factorial(count);
    auto ways = factorial(n) / denominator;
    std::int64_t rank = 1, remaining = n;
    for (std::int64_t position = 0; position < n; ++position) {
        const auto actual = input[position + 1];
        for (std::int64_t smaller = 0; smaller < actual; ++smaller) {
            const auto count = frequency[static_cast<std::size_t>(smaller)];
            if (count > 0) rank += ways * count / remaining;
        }
        const auto index = static_cast<std::size_t>(actual);
        ways = ways * frequency[index] / remaining;
        --frequency[index];
        --remaining;
    }
    return rank;
}
