#include <cstddef>
#include <cstdint>

extern "C" std::int64_t crc_polynomial_division(const std::int64_t* input, std::size_t length,
                                                  std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 3 + 64 + 16) return -1;
    const auto operation = input[0], raw_message_length = input[1], raw_polynomial_length = input[2];
    if (operation < 0 || operation > 1 || raw_message_length < 1 || raw_message_length > 64
        || raw_polynomial_length < 2 || raw_polynomial_length > 16) return -1;
    const auto message_length = static_cast<std::size_t>(raw_message_length);
    const auto polynomial_length = static_cast<std::size_t>(raw_polynomial_length);
    if (length != 3 + message_length + polynomial_length) return -1;

    std::uint8_t message[64], polynomial[16], dividend[79], remainder[16];
    for (std::size_t i = 0; i < message_length; ++i) {
        if (input[3 + i] < 0 || input[3 + i] > 1) return -1;
        message[i] = static_cast<std::uint8_t>(input[3 + i]);
    }
    for (std::size_t i = 0; i < polynomial_length; ++i) {
        const auto bit = input[3 + message_length + i];
        if (bit < 0 || bit > 1) return -1;
        polynomial[i] = static_cast<std::uint8_t>(bit);
    }
    if (polynomial[0] != 1 || polynomial[polynomial_length - 1] != 1) return -1;

    auto dividend_length = message_length;
    for (std::size_t i = 0; i < message_length; ++i) dividend[i] = message[i];
    if (operation == 0)
        for (std::size_t i = 0; i + 1 < polynomial_length; ++i) dividend[dividend_length++] = 0;

    std::size_t remainder_length = 0, cursor = 0;
    while (cursor < dividend_length) {
        while (remainder_length < polynomial_length && cursor < dividend_length)
            remainder[remainder_length++] = dividend[cursor++];
        if (remainder_length == polynomial_length) {
            if (remainder[0] == 1)
                for (std::size_t i = 0; i < polynomial_length; ++i) remainder[i] ^= polynomial[i];
            std::size_t leading_zeroes = 0;
            while (leading_zeroes < remainder_length && remainder[leading_zeroes] == 0) ++leading_zeroes;
            for (std::size_t i = leading_zeroes; i < remainder_length; ++i)
                remainder[i - leading_zeroes] = remainder[i];
            remainder_length -= leading_zeroes;
        }
    }

    std::size_t output_length;
    if (operation == 0) output_length = message_length + remainder_length;
    else {
        std::uint8_t nonzero = 0;
        for (std::size_t i = 0; i < remainder_length; ++i) nonzero |= remainder[i];
        remainder[0] = nonzero != 0;
        output_length = 1;
    }
    if (output == nullptr || capacity < output_length) return -2;
    if (operation == 0) {
        for (std::size_t i = 0; i < message_length; ++i) output[i] = message[i];
        for (std::size_t i = 0; i < remainder_length; ++i) output[message_length + i] = remainder[i];
    } else output[0] = remainder[0];
    return static_cast<std::int64_t>(output_length);
}
