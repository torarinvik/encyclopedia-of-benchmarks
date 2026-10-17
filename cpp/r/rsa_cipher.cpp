#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rsa_cipher_encrypt_ascii(const std::int64_t* input,
                                                  std::size_t input_length) noexcept {
    constexpr std::size_t max_parseable_input_values = 4;
    if (input == nullptr || input_length < 3 || input_length > max_parseable_input_values ||
        input_length != 3) return -1;

    const std::int64_t ascii_code = input[0];
    const std::int64_t exponent = input[1];
    const std::int64_t modulus = input[2];
    if (ascii_code < 0 || ascii_code > 127 || modulus < 128 || modulus > 65535 ||
        exponent < 1 || exponent >= modulus) return -1;

    std::int64_t result = 1;
    std::int64_t base = ascii_code % modulus;
    std::int64_t power = exponent;
    while (power > 0) {
        if ((power & 1) != 0) result = (result * base) % modulus;
        power >>= 1;
        if (power > 0) base = (base * base) % modulus;
    }
    return result;
}
