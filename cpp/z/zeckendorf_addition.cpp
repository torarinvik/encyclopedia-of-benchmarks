#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_bits = 64;
constexpr std::size_t max_parseable = 131;
constexpr std::size_t max_output = 66;

bool canonical(const std::int64_t* bits, std::size_t length) noexcept {
    if (length == 1 && bits[0] == 0) return true;
    if (length == 0 || bits[0] != 1) return false;
    for (std::size_t i = 0; i < length; ++i) {
        if (bits[i] != 0 && bits[i] != 1) return false;
        if (i + 1 < length && bits[i] == 1 && bits[i + 1] == 1) return false;
    }
    return true;
}

void stage_one(std::array<std::uint8_t, max_output>& d, std::size_t n) noexcept {
    for (std::size_t i = 0; i + 3 < n; ++i) {
        if (d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 0) {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; ++d[i + 3];
        } else if (d[i] == 0 && d[i + 1] == 3 && d[i + 2] == 0) {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; ++d[i + 3];
        } else if (d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 1) {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0;
        } else if (d[i] == 0 && d[i + 1] == 1 && d[i + 2] == 2) {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 1;
        }
    }
    if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 3 && d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    } else if (n >= 4 && d[n - 4] == 0 && d[n - 3] == 1 && d[n - 2] == 2 && d[n - 1] == 0) {
        d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 1) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0;
    }
    if (n >= 2 && d[n - 2] == 0 && d[n - 1] == 3) {
        d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 2 && d[n - 2] == 0 && d[n - 1] == 2) {
        d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 1 && d[n - 1] == 2) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    }
}
}

extern "C" std::int64_t zeckendorf_addition(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_parseable) return -1;
    const auto first_n = input[0];
    if (first_n < 1 || first_n > static_cast<std::int64_t>(max_bits)) return -1;
    const auto second_n_index = static_cast<std::size_t>(first_n) + 1;
    if (second_n_index >= length) return -1;
    const auto second_n = input[second_n_index];
    if (second_n < 1 || second_n > static_cast<std::int64_t>(max_bits)) return -1;
    if (length != second_n_index + static_cast<std::size_t>(second_n) + 1) return -1;
    const auto* first = input + 1;
    const auto* second = input + second_n_index + 1;
    if (!canonical(first, static_cast<std::size_t>(first_n)) ||
        !canonical(second, static_cast<std::size_t>(second_n))) return -1;

    const auto width = static_cast<std::size_t>(first_n > second_n ? first_n : second_n);
    const auto first_offset = width - static_cast<std::size_t>(first_n);
    const auto second_offset = width - static_cast<std::size_t>(second_n);
    std::array<std::uint8_t, max_output> digits{};
    auto digit_count = width + 1;
    for (std::size_t i = 0; i < width; ++i) {
        const auto a = i < first_offset ? 0 : static_cast<std::uint8_t>(first[i - first_offset]);
        const auto b = i < second_offset ? 0 : static_cast<std::uint8_t>(second[i - second_offset]);
        digits[i + 1] = static_cast<std::uint8_t>(a + b);
    }
    stage_one(digits, digit_count);
    for (auto i = digit_count; i > 0; --i) digits[i] = digits[i - 1];
    digits[0] = 0;
    ++digit_count;
    for (std::size_t i = digit_count - 2; i > 0; --i) {
        const auto start = i - 1;
        if (digits[start] == 0 && digits[start + 1] == 1 && digits[start + 2] == 1) {
            digits[start] = 1; digits[start + 1] = 0; digits[start + 2] = 0;
        }
    }
    for (std::size_t i = 0; i + 2 < digit_count; ++i) {
        if (digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1) {
            digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0;
        }
    }
    std::size_t first_output = 0;
    while (first_output + 1 < digit_count && digits[first_output] == 0) ++first_output;
    const auto required = digit_count - first_output;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i)
        output[i] = static_cast<std::uint8_t>('0' + digits[first_output + i]);
    return static_cast<std::int64_t>(required);
}
