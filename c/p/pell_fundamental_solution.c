#include <stddef.h>
#include <stdint.h>

int64_t pell_fundamental_solution(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;

    const int64_t d_value = input[0];
    if (d_value < 2 || d_value > 31) return -1;

    int64_t a0 = 1;
    while ((a0 + 1) * (a0 + 1) <= d_value) ++a0;
    if (a0 * a0 == d_value) return -1;

    int64_t m = 0;
    int64_t denominator = 1;
    int64_t coefficient = a0;
    int64_t p_previous_previous = 0;
    int64_t p_previous = 1;
    int64_t q_previous_previous = 1;
    int64_t q_previous = 0;

    for (;;) {
        const int64_t p = coefficient * p_previous + p_previous_previous;
        const int64_t q = coefficient * q_previous + q_previous_previous;
        if (p * p - d_value * q * q == 1) {
            return p * INT64_C(4294967296) + q;
        }

        p_previous_previous = p_previous;
        p_previous = p;
        q_previous_previous = q_previous;
        q_previous = q;

        const int64_t next_m = denominator * coefficient - m;
        const int64_t next_denominator =
            (d_value - next_m * next_m) / denominator;
        const int64_t next_coefficient = (a0 + next_m) / next_denominator;
        m = next_m;
        denominator = next_denominator;
        coefficient = next_coefficient;
    }
}
