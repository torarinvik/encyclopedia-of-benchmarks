// Lyndon factorization using Duval's linear-time algorithm.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 4096;

bool valid_input(const std::int64_t *values, std::size_t length) {
    if (length > MAX_LENGTH || (length != 0 && values == nullptr)) return false;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 127) return false;
    }
    return true;
}

std::size_t factor_count(const std::int64_t *values, std::size_t length) {
    std::size_t start = 0, count = 0;
    while (start < length) {
        std::size_t end = start + 1, repeat = start;
        while (end < length && values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start;
            else ++repeat;
            ++end;
        }
        const std::size_t factor_length = end - repeat;
        while (start <= repeat) {
            ++count;
            start += factor_length;
        }
    }
    return count;
}

void store_u32_le(std::uint8_t *output, std::size_t offset, std::size_t value) {
    const std::uint32_t packed = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(packed >> (8 * byte));
}

void write_factors(const std::int64_t *values, std::size_t length, std::uint8_t *output) {
    std::size_t start = 0, factor_index = 0;
    while (start < length) {
        std::size_t end = start + 1, repeat = start;
        while (end < length && values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start;
            else ++repeat;
            ++end;
        }
        const std::size_t factor_length = end - repeat;
        while (start <= repeat) {
            store_u32_le(output, 4 * factor_index, factor_length);
            ++factor_index;
            start += factor_length;
        }
    }
}
} // namespace

extern "C" std::int64_t duval_algorithm(const std::int64_t *values, std::size_t length,
                                         std::uint8_t *output, std::size_t output_capacity) {
    if (!valid_input(values, length)) return -1;
    const std::size_t count = factor_count(values, length);
    const std::size_t required = 4 * count;
    if (required == 0) return 0;
    if (output == nullptr || output_capacity < required) return -2;
    write_factors(values, length, output);
    return static_cast<std::int64_t>(count);
}
