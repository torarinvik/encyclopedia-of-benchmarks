#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxRounds = 8, MaxInput = 259;
}

extern "C" std::int64_t freivalds_matrix_product_verification(
        const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], rounds64 = input[1];
    if (n64 < 1 || n64 > 8 || rounds64 < 1 || rounds64 > 8) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto rounds = static_cast<std::size_t>(rounds64);
    const auto matrix_words = n * n;
    if (length != 2 + 3 * matrix_words + rounds * n) return -1;
    for (std::size_t word = 2; word < 2 + 3 * matrix_words; ++word)
        if (input[word] < -3 || input[word] > 3) return -1;
    const auto signs_offset = 2 + 3 * matrix_words;
    for (std::size_t word = signs_offset; word < length; ++word)
        if (input[word] != -1 && input[word] != 1) return -1;

    std::array<std::int64_t, MaxN> bx{}, abx{}, cx{};
    for (std::size_t round = 0; round < rounds; ++round) {
        for (std::size_t row = 0; row < n; ++row) {
            std::int64_t sum = 0;
            for (std::size_t col = 0; col < n; ++col)
                sum += input[2 + matrix_words + row * n + col]
                     * input[signs_offset + round * n + col];
            bx[row] = sum;
        }
        for (std::size_t row = 0; row < n; ++row) {
            std::int64_t left = 0, right = 0;
            for (std::size_t col = 0; col < n; ++col) {
                left += input[2 + row * n + col] * bx[col];
                right += input[2 + 2 * matrix_words + row * n + col]
                       * input[signs_offset + round * n + col];
            }
            abx[row] = left;
            cx[row] = right;
        }
        for (std::size_t row = 0; row < n; ++row)
            if (abx[row] != cx[row]) return 0;
    }
    return 1;
}
