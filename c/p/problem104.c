#include <stddef.h>
#include <stdint.h>

enum { MAX_FIBONACCI_INDEX = 1000002, MAX_LIMBS = 24000, LIMB_BASE = 1000000000 };

static int is_pandigital_1_to_9(uint32_t value)
{
    uint16_t mask = 0;
    for (int index = 0; index < 9; ++index) {
        const uint32_t digit = value % 10;
        if (digit == 0 || (mask & (uint16_t)(1u << digit)) != 0) return 0;
        mask |= (uint16_t)(1u << digit);
        value /= 10;
    }
    return value == 0 && mask == UINT16_C(0x3fe);
}

static uint32_t power_of_ten(uint32_t exponent)
{
    uint32_t value = 1;
    while (exponent-- > 0) value *= 10;
    return value;
}

static uint32_t leading_nine_digits(const uint32_t *limbs, size_t length)
{
    uint32_t top = limbs[length - 1];
    uint32_t width = 0;
    for (uint32_t value = top; value > 0; value /= 10) ++width;
    if (width >= 9 || length == 1) return top;
    const uint32_t fill = 9 - width;
    const uint32_t next_prefix = limbs[length - 2] / power_of_ten(width);
    return top * power_of_ten(fill) + next_prefix;
}

int64_t problem104(int64_t placeholder)
{
    if (placeholder != 0) return -1;
    uint32_t first_buffer[MAX_LIMBS] = {1};
    uint32_t second_buffer[MAX_LIMBS] = {1};
    uint32_t *previous = first_buffer;
    uint32_t *current = second_buffer;
    size_t previous_length = 1, current_length = 1;

    for (uint32_t index = 3; index <= MAX_FIBONACCI_INDEX; ++index) {
        size_t sum_length = previous_length > current_length ? previous_length : current_length;
        uint64_t carry = 0;
        for (size_t limb = 0; limb < sum_length; ++limb) {
            const uint64_t left = limb < previous_length ? previous[limb] : 0;
            const uint64_t right = limb < current_length ? current[limb] : 0;
            const uint64_t sum = left + right + carry;
            previous[limb] = (uint32_t)(sum % LIMB_BASE);
            carry = sum / LIMB_BASE;
        }
        size_t next_length = sum_length;
        if (carry != 0) {
            if (next_length == MAX_LIMBS) return -1;
            previous[next_length++] = (uint32_t)carry;
        }
        uint32_t *temporary = previous;
        previous = current;
        current = temporary;
        previous_length = current_length;
        current_length = next_length;

        if (is_pandigital_1_to_9(current[0])
            && is_pandigital_1_to_9(leading_nine_digits(current, current_length))) return (int64_t)index;
    }
    return -1;
}
