#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_POLY = 9, MAX_PRODUCT = 17, MAX_INPUT = 10,
       MAX_OUTPUT_BYTES = 72, RANDOM_ATTEMPTS = 32 };
static const int64_t MODULUS = INT64_C(998244353);
static const int64_t PRNG_MODULUS = INT64_C(2147483647);

typedef struct { int64_t coefficients[MAX_PRODUCT]; int degree; } Polynomial;

static int64_t normalize(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t power_mod(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static Polynomial zero_poly(void)
{
    Polynomial result = {{0}, -1};
    return result;
}

static void trim(Polynomial *poly)
{
    while (poly->degree >= 0 && poly->coefficients[poly->degree] == 0) --poly->degree;
}

static Polynomial poly_mod(Polynomial value, const Polynomial *divisor)
{
    if (divisor->degree < 0 || divisor->degree == 0 || value.degree < 0) return zero_poly();
    const int64_t inverse = power_mod(divisor->coefficients[divisor->degree], MODULUS - 2);
    while (value.degree >= divisor->degree) {
        const int shift = value.degree - divisor->degree;
        const int64_t factor = value.coefficients[value.degree] * inverse % MODULUS;
        for (int i = 0; i <= divisor->degree; ++i)
            value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor->coefficients[i]);
        trim(&value);
    }
    return value;
}

static Polynomial multiply_mod(const Polynomial *left, const Polynomial *right,
                               const Polynomial *modulus_poly)
{
    if (left->degree < 0 || right->degree < 0) return zero_poly();
    int64_t product[MAX_PRODUCT] = {0};
    for (int i = 0; i <= left->degree; ++i)
        for (int j = 0; j <= right->degree; ++j)
            product[i + j] = (product[i + j] + left->coefficients[i] * right->coefficients[j]) % MODULUS;
    Polynomial expanded = {{0}, left->degree + right->degree};
    for (int i = 0; i <= expanded.degree; ++i) expanded.coefficients[i] = product[i];
    trim(&expanded);
    return poly_mod(expanded, modulus_poly);
}

static Polynomial polynomial_power_mod(Polynomial base, int64_t exponent,
                                       const Polynomial *modulus_poly)
{
    Polynomial result = {{1}, 0};
    base = poly_mod(base, modulus_poly);
    while (exponent > 0) {
        if (exponent & 1) result = multiply_mod(&result, &base, modulus_poly);
        base = multiply_mod(&base, &base, modulus_poly);
        exponent >>= 1;
    }
    return result;
}

static Polynomial polynomial_gcd(Polynomial left, Polynomial right)
{
    while (right.degree >= 0) {
        Polynomial remainder = poly_mod(left, &right);
        left = right;
        right = remainder;
    }
    if (left.degree < 0) return left;
    const int64_t inverse = power_mod(left.coefficients[left.degree], MODULUS - 2);
    for (int i = 0; i <= left.degree; ++i) left.coefficients[i] = left.coefficients[i] * inverse % MODULUS;
    return left;
}

static Polynomial divide_exact(Polynomial value, const Polynomial *divisor)
{
    Polynomial quotient = zero_poly();
    quotient.degree = value.degree - divisor->degree;
    if (quotient.degree < 0) return quotient;
    for (int i = 0; i <= quotient.degree; ++i) quotient.coefficients[i] = 0;
    const int64_t inverse = power_mod(divisor->coefficients[divisor->degree], MODULUS - 2);
    while (value.degree >= divisor->degree) {
        const int shift = value.degree - divisor->degree;
        const int64_t factor = value.coefficients[value.degree] * inverse % MODULUS;
        quotient.coefficients[shift] = factor;
        for (int i = 0; i <= divisor->degree; ++i)
            value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor->coefficients[i]);
        trim(&value);
    }
    trim(&quotient);
    return quotient;
}

static int split_with_affine(Polynomial poly, int64_t slope, int64_t offset,
                             Polynomial *first, Polynomial *second)
{
    Polynomial affine = {{0}, 1};
    affine.coefficients[0] = offset;
    affine.coefficients[1] = slope;
    affine = poly_mod(affine, &poly);
    Polynomial powered = polynomial_power_mod(affine, (MODULUS - 1) / 2, &poly);
    if (powered.degree < 0) { powered.coefficients[0] = MODULUS - 1; powered.degree = 0; }
    else powered.coefficients[0] = normalize(powered.coefficients[0] - 1);
    trim(&powered);
    Polynomial part = polynomial_gcd(poly, powered);
    if (part.degree <= 0 || part.degree >= poly.degree) return 0;
    *first = part;
    *second = divide_exact(poly, &part);
    return 1;
}

static void collect_roots(Polynomial poly, int64_t *roots, int *root_count,
                          int64_t state)
{
    if (poly.degree == 1) {
        roots[(*root_count)++] = normalize(-poly.coefficients[0] * power_mod(poly.coefficients[1], MODULUS - 2));
        return;
    }
    Polynomial first, second;
    for (int attempt = 0; attempt < RANDOM_ATTEMPTS; ++attempt) {
        state = state * INT64_C(48271) % PRNG_MODULUS;
        int64_t slope = state % MODULUS;
        if (slope == 0) slope = 1;
        state = state * INT64_C(48271) % PRNG_MODULUS;
        const int64_t offset = state % MODULUS;
        if (split_with_affine(poly, slope, offset, &first, &second)) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + 1);
            return;
        }
    }
    for (int64_t offset = 0; offset < MODULUS; ++offset) {
        if (split_with_affine(poly, 1, offset, &first, &second)) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + offset + 1);
            return;
        }
    }
}

static int find_roots(Polynomial polynomial, int64_t *roots)
{
    if (polynomial.degree <= 0) return 0;
    Polynomial x = {{0}, 1};
    x.coefficients[1] = 1;
    Polynomial x_mod = poly_mod(x, &polynomial);
    Polynomial x_to_p = polynomial_power_mod(x_mod, MODULUS, &polynomial);
    int largest = x_to_p.degree > x_mod.degree ? x_to_p.degree : x_mod.degree;
    for (int i = 0; i <= largest; ++i) {
        const int64_t left = i <= x_to_p.degree ? x_to_p.coefficients[i] : 0;
        const int64_t right = i <= x_mod.degree ? x_mod.coefficients[i] : 0;
        x_to_p.coefficients[i] = normalize(left - right);
    }
    x_to_p.degree = largest;
    trim(&x_to_p);
    Polynomial linear_part = polynomial_gcd(polynomial, x_to_p);
    if (linear_part.degree <= 0) return 0;
    int64_t seed = 1;
    for (int i = 0; i <= polynomial.degree; ++i)
        seed = (seed * 31 + polynomial.coefficients[i]) % (PRNG_MODULUS - 1) + 1;
    int root_count = 0;
    collect_roots(linear_part, roots, &root_count, seed);
    for (int i = 0; i < root_count; ++i)
        for (int j = i + 1; j < root_count; ++j)
            if (roots[j] < roots[i]) { int64_t temp = roots[i]; roots[i] = roots[j]; roots[j] = temp; }
    return root_count;
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t polynomial_root_finding(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT ||
        input[0] < 0 || input[0] > MAX_N || length != (size_t)input[0] + 2) return -1;
    Polynomial polynomial = {{0}, (int)input[0]};
    for (int i = 0; i <= polynomial.degree; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
        polynomial.coefficients[i] = input[i + 1];
    }
    if (polynomial.coefficients[polynomial.degree] == 0) return -1;
    int64_t roots[MAX_N] = {0};
    const int root_count = find_roots(polynomial, roots);
    const size_t bytes = 8u * (size_t)(root_count + 1);
    if (output == NULL || capacity < bytes) return -2;
    store_le(output, 0, root_count);
    for (int i = 0; i < root_count; ++i) store_le(output, 8u * (size_t)(i + 1), roots[i]);
    return (int64_t)bytes;
}
