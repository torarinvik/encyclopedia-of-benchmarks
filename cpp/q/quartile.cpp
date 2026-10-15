// Sort up to ten bounded values and encode quartile statistics.
#include <cstddef>
#include <cstdint>

static void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

extern "C" std::int64_t quartile(const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > 11) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > 10 || length != static_cast<std::size_t>(count_value) + 1) return -1;
    std::int64_t values[10]{};
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 99) return -1;
        values[i] = input[i + 1];
    }
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t j = 0; j < count; ++j) {
            if (values[i] < values[j]) { const auto temporary = values[i]; values[i] = values[j]; values[j] = temporary; }
        }
    }
    const auto q1 = values[count / 4];
    const auto q3 = values[(3 * count) / 4];
    const std::size_t required = (count + 4) * 8;
    if (output == nullptr || output_capacity < required) return -2;
    store_i64_le(output, 0, count_value);
    for (std::size_t i = 0; i < count; ++i) store_i64_le(output, 8 * (i + 1), values[i]);
    store_i64_le(output, 8 * (count + 1), q1);
    store_i64_le(output, 8 * (count + 2), q3);
    store_i64_le(output, 8 * (count + 3), q3 - q1);
    return static_cast<std::int64_t>(required);
}
