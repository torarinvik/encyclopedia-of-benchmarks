#include <cstddef>
#include <cstdint>

static std::uint64_t gcd_u64(std::uint64_t a, std::uint64_t b) {
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static std::uint64_t add_mod(std::uint64_t a, std::uint64_t b, std::uint64_t modulus) {
    return a >= modulus - b ? a - (modulus - b) : a + b;
}

static std::uint64_t mul_mod(std::uint64_t a, std::uint64_t b, std::uint64_t modulus) {
    std::uint64_t result = 0;
    a %= modulus;
    while (b != 0) {
        if ((b & 1) != 0) result = add_mod(result, a, modulus);
        b >>= 1;
        if (b != 0) a = add_mod(a, a, modulus);
    }
    return result;
}

static std::uint64_t inverse_mod(std::uint64_t value, std::uint64_t modulus) {
    std::uint64_t old_r = modulus, r = value % modulus;
    std::uint64_t old_t = 0, t = 1;
    while (r != 0) {
        const std::uint64_t quotient = old_r / r;
        const std::uint64_t next_r = old_r % r;
        const std::uint64_t product = mul_mod(quotient % modulus, t, modulus);
        const std::uint64_t next_t = old_t >= product ? old_t - product : modulus - (product - old_t);
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    return old_t;
}

static void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t merkle_hellman_cryptosystem(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 12 || length > 43) return -1;
    if (input[0] < 0 || input[0] > 127 || input[10] < 1 || input[10] > 32) return -1;
    const auto draw_count = static_cast<std::size_t>(input[10]);
    if (length != 11 + draw_count) return -1;

    constexpr std::uint64_t word_max = 4294967295ULL;
    std::uint64_t easy[8];
    std::uint64_t sum = 4294967296ULL;
    for (std::size_t index = 0; index < 8; ++index) {
        if (input[1 + index] < 0 || static_cast<std::uint64_t>(input[1 + index]) > word_max) return -1;
        easy[index] = sum + static_cast<std::uint64_t>(input[1 + index]);
        sum += easy[index];
    }
    if (input[9] < 0 || static_cast<std::uint64_t>(input[9]) > word_max) return -1;
    const std::uint64_t modulus = sum + static_cast<std::uint64_t>(input[9]);
    for (std::size_t index = 0; index < draw_count; ++index) {
        const auto draw_value = input[11 + index];
        if (draw_value < 0 || static_cast<std::uint64_t>(draw_value) > modulus) return -1;
        const auto divisor = gcd_u64(static_cast<std::uint64_t>(draw_value), modulus);
        if (index + 1 < draw_count && divisor == 1) return -1;
        if (index + 1 == draw_count && divisor != 1) return -1;
    }
    if (output == nullptr || capacity < 17) return -2;

    const auto multiplier = static_cast<std::uint64_t>(input[10 + draw_count]);
    std::uint64_t hard[8];
    for (std::size_t index = 0; index < 8; ++index)
        hard[index] = mul_mod(multiplier, easy[index], modulus);

    std::uint64_t ciphertext = 0;
    const auto message = static_cast<std::uint64_t>(input[0]);
    for (int bit_index = 7; bit_index >= 0; --bit_index)
        if (((message >> bit_index) & 1) != 0)
            ciphertext += hard[7 - bit_index];

    const auto inverse = inverse_mod(multiplier, modulus);
    std::uint64_t residue = mul_mod(inverse, ciphertext % modulus, modulus);
    std::uint8_t decoded = 0;
    for (std::size_t index = 0; index < 8; ++index) {
        const auto weight = easy[7 - index];
        if (residue >= weight) {
            residue -= weight;
            decoded = static_cast<std::uint8_t>(decoded | static_cast<std::uint8_t>(1u << index));
        }
    }
    if (residue != 0 || decoded != static_cast<std::uint8_t>(message)) return -1;

    put_i64_le(output, 0, static_cast<std::int64_t>(ciphertext));
    put_i64_le(output, 8, 1);
    output[16] = decoded;
    return 17;
}
