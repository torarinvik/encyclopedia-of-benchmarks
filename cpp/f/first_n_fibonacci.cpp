// Emit the first n Fibonacci terms as decimal NUL-terminated values.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t MIN_COUNT = 3; constexpr std::int64_t MAX_COUNT = 79; }

static std::size_t decimal_length(std::int64_t number) {
    std::size_t length = 1;
    while (number >= 10) { number /= 10; ++length; }
    return length;
}

static std::size_t required_length(std::int64_t count) {
    std::size_t bytes = 0;
    std::int64_t previous = 0, current = 1;
    for (std::int64_t index = 0; index < count; ++index) {
        std::int64_t value;
        if (index == 0) value = 0;
        else if (index == 1) value = 1;
        else { value = previous + current; previous = current; current = value; }
        bytes += decimal_length(value) + 1;
    }
    return bytes;
}

static std::size_t append_decimal(std::int64_t number, std::uint8_t *output, std::size_t position) {
    std::uint8_t digits[20];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>('0' + number % 10); number /= 10; } while (number > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

extern "C" std::int64_t first_n_fibonacci(const std::int64_t *values, std::size_t length,
                                            std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 1) return -1;
    const auto count = values[0];
    if (count < MIN_COUNT || count > MAX_COUNT) return -1;
    const auto required = required_length(count);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    std::int64_t previous = 0, current = 1;
    for (std::int64_t index = 0; index < count; ++index) {
        std::int64_t value;
        if (index == 0) value = 0;
        else if (index == 1) value = 1;
        else { value = previous + current; previous = current; current = value; }
        position = append_decimal(value, output, position);
        output[position++] = 0;
    }
    return static_cast<std::int64_t>(position);
}
