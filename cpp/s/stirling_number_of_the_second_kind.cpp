#include <cstddef>
#include <cstdint>

extern "C" std::int64_t stirling_number_of_the_second_kind(
    const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::int64_t modulus = 998244353;
    constexpr std::int64_t max_n = 16;
    if (input == nullptr || length != 1) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > max_n) return -1;
    const auto n = static_cast<std::size_t>(n_value);

    std::int64_t row[17]{};
    row[0] = 1;
    for (std::size_t current_n = 1; current_n <= n; ++current_n) {
        for (std::size_t k = current_n; k > 0; --k) {
            row[k] = (row[k - 1] + static_cast<std::int64_t>(k) * row[k]) % modulus;
        }
        row[0] = 0;
    }

    std::int64_t result = 0;
    for (std::size_t k = 0; k <= n; ++k) {
        const auto next = static_cast<std::int64_t>(k + 1);
        const auto weight = next * next * next;
        result = (result + weight * row[k]) % modulus;
    }
    return result;
}
