#include <stddef.h>
#include <stdint.h>

#define MAX_DIGITS ((size_t)64)
#define MAX_OUTPUT_DIGITS ((size_t)1665)
#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)

typedef struct {
    size_t length;
    uint32_t digits[MAX_OUTPUT_DIGITS];
} big_uint;

static void trim(big_uint *value) {
    while (value->length > 0 && value->digits[value->length - 1] == 0) --value->length;
}

static big_uint from_small(uint32_t value, uint32_t base) {
    big_uint result = {0};
    while (value > 0) {
        result.digits[result.length++] = value % base;
        value /= base;
    }
    return result;
}

static void add(big_uint *left, const big_uint *right, uint32_t base) {
    size_t index = 0;
    uint64_t carry = 0;
    while (index < right->length || carry != 0) {
        const uint64_t sum = carry + (index < left->length ? left->digits[index] : 0) +
                             (index < right->length ? right->digits[index] : 0);
        if (index == left->length) ++left->length;
        left->digits[index] = (uint32_t)(sum % base);
        carry = sum / base;
        ++index;
    }
    if (left->length < right->length) left->length = right->length;
}

static big_uint multiply(const big_uint *left, const big_uint *right, uint32_t base) {
    big_uint result = {0};
    if (left->length == 0 || right->length == 0) return result;
    result.length = left->length + right->length;
    for (size_t i = 0; i < left->length; ++i) {
        uint64_t carry = 0;
        for (size_t j = 0; j < right->length; ++j) {
            const size_t at = i + j;
            const uint64_t product = (uint64_t)left->digits[i] * right->digits[j] +
                                     result.digits[at] + carry;
            result.digits[at] = (uint32_t)(product % base);
            carry = product / base;
        }
        size_t at = i + right->length;
        while (carry != 0) {
            const uint64_t sum = result.digits[at] + carry;
            result.digits[at] = (uint32_t)(sum % base);
            carry = sum / base;
            ++at;
            if (at > result.length) result.length = at;
        }
    }
    trim(&result);
    return result;
}

static big_uint power(big_uint factor, size_t exponent, uint32_t base) {
    big_uint result = from_small(1, base);
    while (exponent > 0) {
        if ((exponent & 1u) != 0) result = multiply(&result, &factor, base);
        exponent >>= 1;
        if (exponent > 0) factor = multiply(&factor, &factor, base);
    }
    return result;
}

static big_uint convert_base(const uint32_t *digits, size_t length,
                             uint32_t source_base, uint32_t target_base) {
    if (length == 0) return (big_uint){0};
    if (source_base == target_base) {
        big_uint copy = {0};
        copy.length = length;
        for (size_t i = 0; i < length; ++i) copy.digits[i] = digits[i];
        return copy;
    }
    if (length == 1) return from_small(digits[0], target_base);

    const size_t middle = length / 2;
    big_uint low = convert_base(digits, middle, source_base, target_base);
    const big_uint high = convert_base(digits + middle, length - middle, source_base, target_base);
    const big_uint factor = from_small(source_base, target_base);
    const big_uint scale = power(factor, middle, target_base);
    const big_uint shifted_high = multiply(&high, &scale, target_base);
    add(&low, &shifted_high, target_base);
    return low;
}

int64_t uint_convert_base(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_DIGITS + 4) return INVALID_RESULT;
    const int64_t source_value = input[0], target_value = input[1], count_value = input[2];
    if (source_value < 2 || source_value > (INT64_C(1) << 26) ||
        target_value < 2 || target_value > (INT64_C(1) << 26) ||
        count_value < 0 || count_value > (int64_t)MAX_DIGITS ||
        length != (size_t)count_value + 3) return INVALID_RESULT;

    const uint32_t source_base = (uint32_t)source_value;
    const uint32_t target_base = (uint32_t)target_value;
    const size_t count = (size_t)count_value;
    uint32_t source_digits[MAX_DIGITS];
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 3] < 0 || input[i + 3] >= source_value) return INVALID_RESULT;
        source_digits[i] = (uint32_t)input[i + 3];
    }
    if (count > 0 && source_digits[count - 1] == 0) return INVALID_RESULT;

    const big_uint result = convert_base(source_digits, count, source_base, target_base);
    const size_t output_bytes = result.length * 4;
    if (output == NULL || output_capacity < output_bytes) return OUTPUT_ERROR;
    for (size_t i = 0; i < result.length; ++i) {
        const uint32_t digit = result.digits[i];
        for (size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = (uint8_t)(digit >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
