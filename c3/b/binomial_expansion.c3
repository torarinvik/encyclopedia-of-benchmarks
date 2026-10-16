module binomial_expansion;

const long MAX_EXPONENT = 31;
const long INVALID_RESULT = -9223372036854775807L - 1;

fn long integer_power(long base, long exponent)
{
    long result = 1;
    for (long index = 0; index < exponent; index++) result *= base;
    return result;
}

fn long binomial_coefficient(long n, long k)
{
    long[32] coefficients;
    for (usz index = 0; index < 32; index++) coefficients[index] = 0;
    coefficients[0] = 1;
    for (long row = 1; row <= n; row++) {
        long column = row < k ? row : k;
        while (column > 0) {
            coefficients[column] += coefficients[column - 1];
            column--;
        }
    }
    return coefficients[k];
}

fn long binomial_expansion(long* input, usz length) @export("binomial_expansion")
{
    if (input == null || length != 3) return INVALID_RESULT;
    long a = input[0], b = input[1], exponent = input[2];
    if (a < -2 || a > 2 || b < -2 || b > 2 || exponent < 0 || exponent > MAX_EXPONENT)
        return INVALID_RESULT;

    long result = 0;
    for (long index = 0; index <= exponent; index++) {
        result += binomial_coefficient(exponent, index) *
                  integer_power(a, exponent - index) * integer_power(b, index);
    }
    return result;
}
