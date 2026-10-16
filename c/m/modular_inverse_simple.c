#include <stdint.h>

static uint64_t gcd_u64(uint64_t left, uint64_t right)
{
    while (right != 0) {
        const uint64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t modular_inverse_simple(int64_t x_input, int64_t y_input)
{
    if (x_input < 1 || x_input > 999 || y_input < 2 || y_input > 1000) return -1;
    const uint64_t x = (uint64_t)x_input, y = (uint64_t)y_input;
    if (gcd_u64(x, y) != 1) return -1;

    uint64_t auxiliary = 0, iteration = 0;
    do {
        auxiliary = y * iteration + 1;
        ++iteration;
    } while (auxiliary % x != 0);
    return (int64_t)(auxiliary / x);
}
