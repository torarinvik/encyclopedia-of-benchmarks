#include <stddef.h>
#include <stdint.h>

#define LIMBS ((size_t)4)
#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)

static void divide_words(const uint32_t *dividend, const uint32_t *divisor,
                         uint32_t *quotient, uint32_t *remainder) {
    uint32_t rem[LIMBS + 1] = {0};
    for (size_t offset = 0; offset < LIMBS * 32; ++offset) {
        const size_t bit = LIMBS * 32 - 1 - offset;
        uint32_t carry = (dividend[bit / 32] >> (bit % 32)) & 1u;
        for (size_t i = 0; i < LIMBS; ++i) {
            const uint32_t next = rem[i] >> 31;
            rem[i] = (rem[i] << 1) | carry;
            carry = next;
        }
        rem[LIMBS] = carry;

        {
            int comparison = rem[LIMBS] == 0 ? 0 : 1;
            if (comparison == 0) {
                for (size_t i = LIMBS; i > 0; --i) {
                    if (rem[i - 1] > divisor[i - 1]) { comparison = 1; break; }
                    if (rem[i - 1] < divisor[i - 1]) { comparison = -1; break; }
                }
            }
            if (comparison >= 0) {
                uint64_t borrow = 0;
                for (size_t i = 0; i < LIMBS; ++i) {
                    const uint64_t subtrahend = (uint64_t)divisor[i] + borrow;
                    const uint64_t old = rem[i];
                    if (old >= subtrahend) { rem[i] = (uint32_t)(old - subtrahend); borrow = 0; }
                    else { rem[i] = (uint32_t)(old + UINT64_C(0x100000000) - subtrahend); borrow = 1; }
                }
                rem[LIMBS] = (uint32_t)((uint64_t)rem[LIMBS] - borrow);
                quotient[bit / 32] |= UINT32_C(1) << (bit % 32);
            }
        }
    }
    for (size_t i = 0; i < LIMBS; ++i) remainder[i] = rem[i];
}

int64_t uint128_t(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 10) return INVALID_RESULT;
    if (length != 1 + 2 * LIMBS || (input[0] != 0 && input[0] != 1)) return INVALID_RESULT;
    uint32_t dividend[LIMBS], divisor[LIMBS];
    int divisor_nonzero = 0;
    for (size_t i = 0; i < LIMBS; ++i) {
        const int64_t a = input[1 + i], b = input[1 + LIMBS + i];
        if (a < 0 || a > INT64_C(4294967295) || b < 0 || b > INT64_C(4294967295)) return INVALID_RESULT;
        dividend[i] = (uint32_t)a;
        divisor[i] = (uint32_t)b;
        divisor_nonzero |= divisor[i] != 0;
    }
    if (!divisor_nonzero) return INVALID_RESULT;
    if (output == NULL || capacity < LIMBS * 4) return OUTPUT_ERROR;
    uint32_t quotient[LIMBS] = {0}, remainder[LIMBS] = {0};
    divide_words(dividend, divisor, quotient, remainder);
    const uint32_t *answer = input[0] == 0 ? quotient : remainder;
    for (size_t i = 0; i < LIMBS; ++i)
        for (size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = (uint8_t)(answer[i] >> (byte * 8));
    return 16;
}
