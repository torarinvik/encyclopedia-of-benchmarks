// Enumerate Kaprekar numbers as decimal NUL-terminated values.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t MAX_END = 100000; }

static bool is_kaprekar(std::int64_t number) {
    if (number == 0 || number == 1) return true;
    const std::int64_t square = number * number;
    std::int64_t split = 1;
    for (auto remaining = number; remaining > 0; remaining /= 10) split *= 10;
    const auto right = square % split;
    return right != 0 && square / split + right == number;
}

static std::size_t decimal_length(std::int64_t number) {
    std::size_t length = 1;
    while (number >= 10) { number /= 10; ++length; }
    return length;
}

static std::size_t required_length(std::int64_t start, std::int64_t end) {
    std::size_t bytes = 0;
    for (auto number = start; number <= end; ++number)
        if (is_kaprekar(number)) bytes += decimal_length(number) + 1;
    return bytes;
}

static std::size_t append_decimal(std::int64_t number, std::uint8_t *output, std::size_t position) {
    std::uint8_t digits[20];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>('0' + number % 10); number /= 10; } while (number > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

extern "C" std::int64_t kaprekar_numbers_in_range(const std::int64_t *values, std::size_t length,
                                                   std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const auto start = values[0], end = values[1];
    if (start < 0 || start > end || end > MAX_END) return -1;
    const auto required = required_length(start, end);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    for (auto number = start; number <= end; ++number) {
        if (!is_kaprekar(number)) continue;
        position = append_decimal(number, output, position);
        output[position++] = 0;
    }
    return static_cast<std::int64_t>(position);
}
