/* Compute Fibonacci numbers by portable 64-bit fast doubling. */
#include <stdint.h>

int64_t fibonacci_fast(int64_t input)
{
    if (input < 0 || input > 92) return -1;
    const uint64_t n = (uint64_t)input;
    uint64_t bit = 1;
    while (bit <= n / 2) bit <<= 1;
    uint64_t current = 0, next = 1;
    while (bit != 0) {
        const uint64_t even = current * (2 * next - current);
        const uint64_t odd = current * current + next * next;
        if ((n & bit) != 0) {
            current = odd;
            next = even + odd;
        } else {
            current = even;
            next = odd;
        }
        bit >>= 1;
    }
    return (int64_t)current;
}
