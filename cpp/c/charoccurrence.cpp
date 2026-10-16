#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input = 128;
constexpr std::size_t max_output = 1024;

std::size_t append_decimal(std::uint8_t *buffer, std::size_t offset, std::size_t value) {
    std::uint8_t digits[3];
    std::size_t count = 0;
    do {
        digits[count++] = static_cast<std::uint8_t>('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count != 0) {
        buffer[offset++] = digits[--count];
    }
    return offset;
}
}

extern "C" std::int64_t charoccurrence(const std::int64_t *values, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity) {
    if (length > max_input || (length != 0 && values == nullptr)) {
        return -1;
    }
    std::size_t counts[128]{};
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) {
            return -1;
        }
        ++counts[static_cast<std::size_t>(values[index])];
    }

    std::uint8_t encoded[max_output]{};
    std::size_t used = 0;
    for (std::size_t codepoint = 0; codepoint < 128; ++codepoint) {
        if (counts[codepoint] == 0) {
            continue;
        }
        if (used != 0) {
            encoded[used++] = ',';
        }
        used = append_decimal(encoded, used, codepoint);
        encoded[used++] = '=';
        used = append_decimal(encoded, used, counts[codepoint]);
    }
    if (used > output_capacity) {
        return -2;
    }
    if (used != 0 && output == nullptr) {
        return -2;
    }
    for (std::size_t index = 0; index < used; ++index) {
        output[index] = encoded[index];
    }
    return static_cast<std::int64_t>(used);
}
