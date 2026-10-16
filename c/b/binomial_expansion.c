/* Evaluate the bounded integer binomial expansion exactly. */
#include <stddef.h>
#include <stdint.h>

#define MAX_EXPONENT 31
#define INVALID_RESULT INT64_MIN

static int64_t integer_power(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    for (int64_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

static int64_t binomial_coefficient(int64_t n, int64_t k)
{
    int64_t coefficients[MAX_EXPONENT + 1] = {0};
    coefficients[0] = 1;
    for (int64_t row = 1; row <= n; ++row) {
        int64_t column = row < k ? row : k;
        while (column > 0) {
            coefficients[column] += coefficients[column - 1];
            --column;
        }
    }
    return coefficients[k];
}

int64_t binomial_expansion(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return INVALID_RESULT;
    const int64_t a = input[0], b = input[1], exponent = input[2];
    if (a < -2 || a > 2 || b < -2 || b > 2 || exponent < 0 || exponent > MAX_EXPONENT)
        return INVALID_RESULT;

    int64_t result = 0;
    for (int64_t index = 0; index <= exponent; ++index) {
        result += binomial_coefficient(exponent, index) *
                  integer_power(a, exponent - index) * integer_power(b, index);
    }
    return result;
}
