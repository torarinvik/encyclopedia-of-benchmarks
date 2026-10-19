#include <cstddef>
#include <cstdint>

namespace {
constexpr size_t max_characters = 31;
constexpr size_t max_output_bytes = 1 + 2 * max_characters;
}

extern "C" int64_t misc_lowercase(const int64_t *input, size_t input_length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == nullptr || input_length < 1 || input_length > max_characters + 2) return -1;
    const int64_t raw_length = input[0];
    if (raw_length < 0 || raw_length > static_cast<int64_t>(max_characters) ||
        input_length != static_cast<size_t>(raw_length) + 1) return -1;
    const size_t length = static_cast<size_t>(raw_length);
    uint16_t lowered[max_characters];
    uint8_t ascii_flag = 1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t raw = input[index + 1];
        if (raw < 0 || raw > 65535) return -1;
        const uint16_t value = static_cast<uint16_t>(raw);
        if (value > 0x7f) ascii_flag = 0;
        lowered[index] = static_cast<uint16_t>(value | ((value >= 'A' && value <= 'Z') << 5));
    }
    const size_t required = 1 + 2 * length;
    if (output == nullptr || output_capacity < required) return -2;
    uint8_t staged[max_output_bytes];
    staged[0] = ascii_flag;
    for (size_t index = 0; index < length; ++index) {
        staged[1 + 2 * index] = static_cast<uint8_t>(lowered[index] & 0xff);
        staged[2 + 2 * index] = static_cast<uint8_t>(lowered[index] >> 8);
    }
    for (size_t index = 0; index < required; ++index) output[index] = staged[index];
    return static_cast<int64_t>(required);
}
