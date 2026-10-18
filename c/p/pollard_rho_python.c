#include <stddef.h>
#include <stdint.h>

#define MAX_NUM INT64_C(1000000)

static int64_t gcd_nonnegative(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t advance(int64_t value, int64_t step, int64_t modulus) {
    return (value * value + step) % modulus;
}

int64_t pollard_rho_python(const int64_t *input, size_t length) {
    if (input == NULL || length != 5) return -1;
    const int64_t num = input[0];
    int64_t seed = input[1];
    int64_t step = input[2];
    const int64_t attempts = input[3];
    const int64_t step_limit = input[4];
    if (num < 2 || num > MAX_NUM || seed < 0 || seed >= num || step < 0 || step > 1000 ||
        attempts < 1 || attempts > 8 || step_limit < 1 || step_limit > 64) return -1;
    if (num > 2 && num % 2 == 0) return 2;

    for (int64_t attempt = 0; attempt < attempts; ++attempt) {
        int64_t tortoise = seed;
        int64_t hare = seed;
        for (int64_t iteration = 0; iteration < step_limit; ++iteration) {
            tortoise = advance(tortoise, step, num);
            hare = advance(advance(hare, step, num), step, num);
            const int64_t difference = hare >= tortoise ? hare - tortoise : tortoise - hare;
            const int64_t divisor = gcd_nonnegative(difference, num);
            if (divisor == 1) continue;
            if (divisor < num) return divisor;
            break;
        }
        seed = hare;
        ++step;
    }
    return 0;
}
