#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT_VALUES = 66;
constexpr std::size_t MAX_DECODED_LENGTH = 52;
constexpr std::uint64_t MAX_U32 = UINT64_C(4294967295);

bool decode_group(const std::int64_t *values, std::size_t start, std::size_t count,
                  std::uint32_t &decoded) noexcept
{
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < 5; ++index) {
        std::uint64_t digit = 84;
        if (index < count) {
            const auto byte = values[start + index];
            if (byte < 33 || byte > 117) return false;
            digit = static_cast<std::uint64_t>(byte - 33);
        }
        value = value * 85 + digit;
    }
    if (value > MAX_U32) return false;
    decoded = static_cast<std::uint32_t>(value);
    return true;
}
}

extern "C" std::int64_t base85(const std::int64_t *values, std::size_t length,
                                std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const auto mode = values[0];
    const std::size_t payload_length = length - 1;
    std::size_t output_length = 0;

    if (mode == 0) {
        for (std::size_t index = 1; index < length; ++index)
            if (values[index] < 0 || values[index] > 255) return -1;
        const std::size_t remainder = payload_length % 4;
        output_length = (payload_length / 4) * 5 + (remainder == 0 ? 0 : remainder + 1);
    } else if (mode == 1) {
        if (payload_length % 5 == 1) return -1;
        for (std::size_t offset = 0; offset < payload_length;) {
            const std::size_t count = payload_length - offset < 5 ? payload_length - offset : 5;
            std::uint32_t ignored = 0;
            if (count == 1 || !decode_group(values, offset + 1, count, ignored)) return -1;
            output_length += count == 5 ? 4 : count - 1;
            offset += count;
        }
        if (output_length > MAX_DECODED_LENGTH) return -1;
    } else {
        return -1;
    }

    if (output_capacity < output_length || (output_length != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    if (mode == 0) {
        constexpr std::uint32_t powers[5] = {UINT32_C(52200625), UINT32_C(614125),
                                              UINT32_C(7225), UINT32_C(85), UINT32_C(1)};
        for (std::size_t offset = 0; offset < payload_length; offset += 4) {
            const std::size_t count = payload_length - offset < 4 ? payload_length - offset : 4;
            std::uint32_t value = 0;
            for (std::size_t byte = 0; byte < 4; ++byte) {
                value <<= 8;
                if (byte < count) value |= static_cast<std::uint32_t>(values[offset + byte + 1]);
            }
            for (std::size_t digit = 0; digit < 5; ++digit) {
                const auto encoded = static_cast<std::uint8_t>(value / powers[digit] + 33);
                value %= powers[digit];
                if (count == 4 || digit < count + 1) output[written++] = encoded;
            }
        }
    } else {
        for (std::size_t offset = 0; offset < payload_length;) {
            const std::size_t count = payload_length - offset < 5 ? payload_length - offset : 5;
            std::uint32_t value = 0;
            (void)decode_group(values, offset + 1, count, value);
            const std::size_t byte_count = count == 5 ? 4 : count - 1;
            for (std::size_t byte = 0; byte < byte_count; ++byte)
                output[written++] = static_cast<std::uint8_t>(value >> (24 - 8 * byte));
            offset += count;
        }
    }
    return static_cast<std::int64_t>(written);
}
