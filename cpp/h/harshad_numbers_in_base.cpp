// Encode each base-b Harshad string below a limit with a trailing NUL byte.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 10000;

std::int64_t digit_sum(std::int64_t number, std::int64_t base) {
    std::int64_t sum = 0;
    while (number > 0) { sum += number % base; number /= base; }
    return sum;
}

std::size_t base_length(std::int64_t number, std::int64_t base) {
    std::size_t length = 0;
    do { number /= base; ++length; } while (number > 0);
    return length;
}

std::size_t required_length(std::int64_t limit, std::int64_t base) {
    std::size_t length = 0;
    for (std::int64_t number = 1; number < limit; ++number) {
        if (number % digit_sum(number, base) != 0) continue;
        length += base_length(number, base) + 1;
    }
    return length;
}

std::uint8_t digit_byte(std::int64_t digit) {
    return static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'A' + digit - 10);
}

std::size_t append_base(std::int64_t number, std::int64_t base,
                        std::uint8_t *output, std::size_t position) {
    std::uint8_t digits[64];
    std::size_t count = 0;
    do { digits[count++] = digit_byte(number % base); number /= base; } while (number > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}
}

extern "C" std::int64_t harshad_numbers_in_base(const std::int64_t *values, std::size_t length,
                                                 std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const auto limit = values[0], base = values[1];
    if (limit > max_limit || base < 2 || base > 36) return -1;
    const auto required = required_length(limit, base);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    for (std::int64_t number = 1; number < limit; ++number) {
        if (number % digit_sum(number, base) != 0) continue;
        position = append_base(number, base, output, position);
        output[position++] = 0;
    }
    return static_cast<std::int64_t>(position);
}
