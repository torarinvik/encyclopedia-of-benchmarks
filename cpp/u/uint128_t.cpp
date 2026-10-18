#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t limbs = 4;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;

void divide_words(const std::uint32_t *dividend, const std::uint32_t *divisor,
                  std::uint32_t *quotient, std::uint32_t *remainder) {
    std::uint32_t rem[limbs + 1] = {};
    for (std::size_t offset = 0; offset < limbs * 32; ++offset) {
        const std::size_t bit = limbs * 32 - 1 - offset;
        std::uint32_t carry = (dividend[bit / 32] >> (bit % 32)) & 1u;
        for (std::size_t i = 0; i < limbs; ++i) {
            const std::uint32_t next = rem[i] >> 31;
            rem[i] = (rem[i] << 1) | carry;
            carry = next;
        }
        rem[limbs] = carry;
        int comparison = rem[limbs] == 0 ? 0 : 1;
        if (comparison == 0) {
            for (std::size_t i = limbs; i > 0; --i) {
                if (rem[i - 1] > divisor[i - 1]) { comparison = 1; break; }
                if (rem[i - 1] < divisor[i - 1]) { comparison = -1; break; }
            }
        }
        if (comparison >= 0) {
            std::uint64_t borrow = 0;
            for (std::size_t i = 0; i < limbs; ++i) {
                const std::uint64_t sub = static_cast<std::uint64_t>(divisor[i]) + borrow;
                const std::uint64_t old = rem[i];
                if (old >= sub) { rem[i] = static_cast<std::uint32_t>(old - sub); borrow = 0; }
                else { rem[i] = static_cast<std::uint32_t>(old + UINT64_C(0x100000000) - sub); borrow = 1; }
            }
            rem[limbs] = static_cast<std::uint32_t>(static_cast<std::uint64_t>(rem[limbs]) - borrow);
            quotient[bit / 32] |= UINT32_C(1) << (bit % 32);
        }
    }
    for (std::size_t i = 0; i < limbs; ++i) remainder[i] = rem[i];
}
}

extern "C" std::int64_t uint128_t(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > 10 || length != 1 + 2 * limbs ||
        (input[0] != 0 && input[0] != 1)) return invalid_result;
    std::uint32_t dividend[limbs], divisor[limbs];
    bool divisor_nonzero = false;
    for (std::size_t i = 0; i < limbs; ++i) {
        const std::int64_t a = input[1 + i], b = input[1 + limbs + i];
        if (a < 0 || a > INT64_C(4294967295) || b < 0 || b > INT64_C(4294967295)) return invalid_result;
        dividend[i] = static_cast<std::uint32_t>(a);
        divisor[i] = static_cast<std::uint32_t>(b);
        divisor_nonzero = divisor_nonzero || divisor[i] != 0;
    }
    if (!divisor_nonzero) return invalid_result;
    if (output == nullptr || capacity < 16) return output_error;
    std::uint32_t quotient[limbs] = {}, remainder[limbs] = {};
    divide_words(dividend, divisor, quotient, remainder);
    const std::uint32_t *answer = input[0] == 0 ? quotient : remainder;
    for (std::size_t i = 0; i < limbs; ++i)
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = static_cast<std::uint8_t>(answer[i] >> (byte * 8));
    return 16;
}
