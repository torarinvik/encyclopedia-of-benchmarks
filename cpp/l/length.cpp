#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PAYLOAD_BYTES = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 259;
constexpr std::size_t OUTPUT_BYTES = 16;

std::int64_t utf8_scalar_count(const std::uint8_t *bytes, std::size_t length)
{
    std::size_t index = 0;
    std::int64_t count = 0;
    while (index < length) {
        const std::uint8_t lead = bytes[index];
        if (lead >= 1 && lead <= 0x7f) {
            ++index;
        } else if (lead >= 0xc2 && lead <= 0xdf) {
            if (index + 1 >= length || bytes[index + 1] < 0x80 || bytes[index + 1] > 0xbf) return -1;
            index += 2;
        } else if (lead >= 0xe0 && lead <= 0xef) {
            if (index + 2 >= length) return -1;
            const std::uint8_t second = bytes[index + 1], third = bytes[index + 2];
            if (second < 0x80 || second > 0xbf || third < 0x80 || third > 0xbf ||
                (lead == 0xe0 && second < 0xa0) || (lead == 0xed && second > 0x9f)) return -1;
            index += 3;
        } else {
            return -1;
        }
        ++count;
    }
    return count;
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t length(const std::int64_t *input, std::size_t input_length,
                                 std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_PAYLOAD_BYTES)) return -1;
    const std::size_t payload_length = static_cast<std::size_t>(input[0]);
    if (input_length != payload_length + 2) return -1;

    std::uint8_t payload[MAX_PAYLOAD_BYTES] = {};
    for (std::size_t index = 0; index <= payload_length; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < 0 || value > 255) return -1;
        if (index == payload_length) {
            if (value != 0) return -1;
        } else {
            if (value == 0) return -1;
            payload[index] = static_cast<std::uint8_t>(value);
        }
    }
    const std::int64_t scalar_count = utf8_scalar_count(payload, payload_length);
    if (scalar_count < 0) return -1;
    if (output == nullptr || output_capacity < OUTPUT_BYTES) return -2;

    put_i64_le(output, 0, static_cast<std::int64_t>(payload_length));
    put_i64_le(output, 8, scalar_count);
    return static_cast<std::int64_t>(OUTPUT_BYTES);
}
