#include <stdint.h>

#define LIMBS 16
#define BASE UINT64_C(1000000000)

static void mul_add(const uint64_t src[LIMBS], uint64_t factor, uint64_t add, uint64_t dst[LIMBS])
{
    uint64_t carry = add;
    for (int i = 0; i < LIMBS; ++i) {
        const uint64_t value = src[i] * factor + carry;
        dst[i] = value % BASE;
        carry = value / BASE;
    }
}

static int ge(const uint64_t left[LIMBS], const uint64_t right[LIMBS])
{
    for (int i = LIMBS - 1; i >= 0; --i) {
        if (left[i] != right[i]) return left[i] > right[i];
    }
    return 1;
}

static void subtract(uint64_t left[LIMBS], const uint64_t right[LIMBS])
{
    uint64_t borrow = 0;
    for (int i = 0; i < LIMBS; ++i) {
        const uint64_t amount = right[i] + borrow;
        if (left[i] < amount) { left[i] = left[i] + BASE - amount; borrow = 1; }
        else { left[i] -= amount; borrow = 0; }
    }
}

int64_t problem80(int64_t placeholder)
{
    if (placeholder != 0) return -1;
    int64_t answer = 0;
    for (uint64_t number = 2; number < 100; ++number) {
        uint64_t integer_root = 0;
        while ((integer_root + 1) * (integer_root + 1) <= number) ++integer_root;
        if (integer_root * integer_root == number) continue;
        uint64_t root[LIMBS] = {0}, remainder[LIMBS] = {0};
        uint64_t scaled[LIMBS], trial[LIMBS];
        int64_t digit_sum = 0;
        for (int step = 0; step < 100; ++step) {
            mul_add(remainder, 100, step == 0 ? number : 0, remainder);
            int digit = 9;
            for (; digit >= 0; --digit) {
                mul_add(root, 20, (uint64_t)digit, scaled);
                mul_add(scaled, (uint64_t)digit, 0, trial);
                if (ge(remainder, trial)) break;
            }
            subtract(remainder, trial);
            mul_add(root, 10, (uint64_t)digit, root);
            digit_sum += digit;
        }
        answer += digit_sum;
    }
    return answer;
}
