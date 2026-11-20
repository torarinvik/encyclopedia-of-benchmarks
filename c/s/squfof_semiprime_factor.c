#include <stddef.h>
#include <stdint.h>

#define SQUFOF_MAX_NUMBER 1000000000000LL
#define SQUFOF_MAX_STEPS 256

static int64_t squfof_isqrt(int64_t value, int64_t upper) {
    int64_t low = 0;
    int64_t high = upper + 1;
    while (low + 1 < high) {
        const int64_t middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

static int64_t squfof_gcd(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t squfof_reverse(int64_t number, int64_t discriminant, int64_t root_bound,
                              int64_t p, int64_t q, int64_t reverse_cap) {
    const int64_t square_root = squfof_isqrt(q, root_bound);
    if (square_root * square_root != q) return 0;
    const int64_t quotient = (root_bound - p) / square_root;
    int64_t r = quotient * square_root + p;
    int64_t previous_s = square_root;
    int64_t s = (discriminant - r * r) / square_root;
    for (int64_t step = 0; step < reverse_cap; ++step) {
        const int64_t next_quotient = (root_bound + r) / s;
        const int64_t next_r = next_quotient * s - r;
        if (next_r == r) {
            const int64_t factor = squfof_gcd(number, r);
            if (factor > 1 && factor < number) {
                const int64_t other = number / factor;
                return factor < other ? factor : other;
            }
            return 0;
        }
        const int64_t next_s = previous_s + next_quotient * (r - next_r);
        previous_s = s;
        s = next_s;
        r = next_r;
    }
    return 0;
}

int64_t squfof_semiprime_factor(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t number = input[0];
    const int64_t forward_cap = input[1];
    const int64_t reverse_cap = input[2];
    if (number < 3 || number > SQUFOF_MAX_NUMBER || number % 2 == 0
        || forward_cap < 0 || forward_cap > SQUFOF_MAX_STEPS
        || reverse_cap < 0 || reverse_cap > SQUFOF_MAX_STEPS) return -1;

    const int64_t initial_root = squfof_isqrt(number, 1000000);
    if (initial_root * initial_root == number) return initial_root;
    const int64_t discriminant = number % 4 == 1 ? 2 * number : number;
    const int64_t a = squfof_isqrt(discriminant, 1414214);
    int64_t previous_q = 1;
    int64_t q = discriminant - a * a;
    int64_t p = a;
    int64_t index = 1;
    for (int64_t step = 0; step < forward_cap; ++step) {
        const int64_t quotient = (a + p) / q;
        const int64_t next_p = quotient * q - p;
        const int64_t next_q = previous_q + quotient * (p - next_p);
        previous_q = q;
        q = next_q;
        p = next_p;
        ++index;
        if (index % 2 == 0) {
            const int64_t factor = squfof_reverse(number, discriminant, a, p, q, reverse_cap);
            if (factor != 0) return factor;
        }
    }
    return 0;
}
