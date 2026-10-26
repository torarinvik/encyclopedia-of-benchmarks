#include <cstddef>
#include <cstdint>
#include <cstring>

static void put_i32(std::uint8_t *out, std::size_t at, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (unsigned b = 0; b < 4; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}

extern "C" std::int64_t prolangs_c_numeric_token(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > 24) return -1;
    char text[25];
    for (std::size_t j = 0; j < length; ++j) {
        if (input[j] < 32 || input[j] > 127) return -1;
        text[j] = static_cast<char>(input[j]);
    }
    std::size_t i = 0;
    std::uint32_t integer = 0;
    bool had_integer = false;
    if (text[i] >= '0' && text[i] <= '9') {
        had_integer = true;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            const unsigned d = static_cast<unsigned>(text[i++] - '0');
            if (integer > (2147483647u - d) / 10u) return -1;
            integer = integer * 10u + d;
        }
        if (i == length) {
            if (capacity < 12 || output == nullptr) return -2;
            put_i32(output, 0, 256); put_i32(output, 4, static_cast<std::int32_t>(integer)); put_i32(output, 8, 0);
            return 12;
        }
    }
    std::uint32_t fraction_digits = 0;
    unsigned fractional_count = 0, leading_zeros = 0;
    bool has_dot = false;
    if (i < length && text[i] == '.') {
        has_dot = true; ++i;
        while (i < length && text[i] == '0') { ++leading_zeros; ++i; }
        if (leading_zeros > 6) return -1;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            if (fractional_count == 6) return -1;
            fraction_digits = fraction_digits * 10u + static_cast<unsigned>(text[i++] - '0');
            ++fractional_count;
        }
        if (leading_zeros + fractional_count > 6) return -1;
    }
    float value = 0.0f;
    if (fractional_count != 0) {
        value = static_cast<float>(fraction_digits);
        while (value >= 1.0f) value /= 10.0f;
        while (leading_zeros-- != 0) value /= 10.0f;
    }
    value += static_cast<float>(integer);
    bool has_exponent = false;
    if (i < length && (text[i] == 'e' || text[i] == 'E')) {
        has_exponent = true; ++i;
        int sign = 1;
        if (i < length && (text[i] == '+' || text[i] == '-')) { if (text[i++] == '-') sign = -1; }
        if (i == length || text[i] < '0' || text[i] > '9') return -1;
        int exponent = 0;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            exponent = exponent * 10 + (text[i++] - '0');
            if (exponent > 6) return -1;
        }
        exponent *= sign;
        while (exponent > 0) { value *= 10.0f; --exponent; }
        while (exponent < 0) { value /= 10.0f; ++exponent; }
    }
    if (i != length || (!has_dot && !has_exponent) || (!had_integer && !has_dot)) return -1;
    if (capacity < 12 || output == nullptr) return -2;
    std::int32_t bits; std::memcpy(&bits, &value, sizeof(bits));
    put_i32(output, 0, 2001); put_i32(output, 4, static_cast<std::int32_t>(integer)); put_i32(output, 8, bits);
    return 12;
}
