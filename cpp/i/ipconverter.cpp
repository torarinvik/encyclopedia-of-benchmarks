#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_parseable_input_length = 38; }

extern "C" std::int64_t ipconverter(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const auto mode = input[0], payload_length_value = input[1];
    if ((mode != 0 && mode != 1) || payload_length_value < 0 || payload_length_value > 35) return -1;
    const auto payload_length = static_cast<std::size_t>(payload_length_value);
    if (length != payload_length + 2) return -1;

    std::int64_t octets[4]{};
    std::size_t position = 0;
    if (mode == 0) {
        if (payload_length < 7 || payload_length > 15) return -1;
        for (std::size_t octet = 0; octet < 4; ++octet) {
            std::size_t digits = 0;
            std::int64_t value = 0;
            while (position < payload_length && input[2 + position] != 46) {
                const auto byte = input[2 + position];
                if (digits == 3 || byte < 48 || byte > 57) return -1;
                value = value * 10 + byte - 48;
                if (value > 255) return -1;
                ++digits;
                ++position;
            }
            if (digits == 0) return -1;
            octets[octet] = value;
            if (octet < 3) {
                if (position >= payload_length || input[2 + position] != 46) return -1;
                ++position;
            } else if (position != payload_length) return -1;
        }
    } else {
        if (payload_length != 35) return -1;
        for (std::size_t octet = 0; octet < 4; ++octet) {
            std::int64_t value = 0;
            for (int bit = 0; bit < 8; ++bit) {
                const auto byte = input[2 + position++];
                if (byte != 48 && byte != 49) return -1;
                value = value * 2 + byte - 48;
            }
            octets[octet] = value;
            if (octet < 3 && input[2 + position++] != 46) return -1;
        }
        if (position != payload_length) return -1;
    }

    std::size_t output_length = mode == 0 ? 35 : 3;
    if (mode == 1)
        for (auto value : octets) output_length += value >= 100 ? 2 : value >= 10 ? 1 : 0;
    if (capacity < output_length || output == nullptr) return -2;

    position = 0;
    for (std::size_t octet = 0; octet < 4; ++octet) {
        if (mode == 0) {
            for (int bit = 7; bit >= 0; --bit)
                output[position++] = static_cast<std::uint8_t>('0' + ((octets[octet] >> bit) & 1));
        } else {
            auto value = octets[octet];
            if (value >= 100) { output[position++] = static_cast<std::uint8_t>('0' + value / 100); value %= 100; }
            if (value >= 10) { output[position++] = static_cast<std::uint8_t>('0' + value / 10); value %= 10; }
            output[position++] = static_cast<std::uint8_t>('0' + value);
        }
        if (octet < 3) output[position++] = '.';
    }
    return static_cast<std::int64_t>(position);
}
