#include <stddef.h>
#include <stdint.h>

#define MAX_PARAMETER INT64_C(1000000000)

static int64_t floor_sum(int64_t n, int64_t m, int64_t a, int64_t b) {
    int64_t answer = 0;
    for (;;) {
        if (a >= m) {
            const int64_t quotient = a / m;
            int64_t left = n;
            int64_t right = n - 1;
            if (left % 2 == 0) left /= 2;
            else right /= 2;
            answer += left * right * quotient;
            a %= m;
        }
        if (b >= m) {
            answer += n * (b / m);
            b %= m;
        }
        const int64_t numerator = a * n + b;
        const int64_t height = numerator / m;
        if (height == 0) return answer;
        b = numerator % m;
        n = height;
        const int64_t previous_m = m;
        m = a;
        a = previous_m;
    }
}

int64_t min_of_mod_of_linear(const int64_t *input, size_t length) {
    if (input == NULL || length != 4) return -1;
    const int64_t n = input[0];
    const int64_t m = input[1];
    const int64_t a = input[2];
    const int64_t b = input[3];
    if (n < 1 || n > MAX_PARAMETER || m < 1 || m > MAX_PARAMETER
        || a < 0 || a >= m || b < 0 || b >= m) return -1;
    const int64_t base = floor_sum(n, m, a, b);
    const int64_t target = base + n;
    int64_t low = -1;
    int64_t high = m - 1;
    while (high - low > 1) {
        const int64_t candidate = low + (high - low) / 2;
        const int64_t shift = m - 1 - candidate;
        if (floor_sum(n, m, a, b + shift) < target) high = candidate;
        else low = candidate;
    }
    return high;
}
