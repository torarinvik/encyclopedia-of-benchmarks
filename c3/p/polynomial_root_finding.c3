module polynomial_root_finding;

const usz MAX_N = 8;
const usz MAX_POLY = 9;
const usz MAX_PRODUCT = 17;
const usz MAX_INPUT = 10;
const usz MAX_OUTPUT_BYTES = 72;
const long MODULUS = 998244353;
const long PRNG_MODULUS = 2147483647;
const int RANDOM_ATTEMPTS = 32;

struct Poly { long[MAX_PRODUCT] c; int degree; }

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn Poly zero_poly() {
    Poly result;
    for (usz i = 0; i < MAX_PRODUCT; i++) result.c[i] = 0;
    result.degree = -1;
    return result;
}

fn void trim(Poly* polynomial) {
    while (polynomial.degree >= 0 && polynomial.c[polynomial.degree] == 0) polynomial.degree--;
}

fn Poly poly_mod(Poly value, Poly* divisor) {
    if (divisor.degree <= 0 || value.degree < 0) return zero_poly();
    long inverse = power_mod(divisor.c[divisor.degree], MODULUS - 2);
    while (value.degree >= divisor.degree) {
        int shift = value.degree - divisor.degree;
        long factor = value.c[value.degree] * inverse % MODULUS;
        for (int i = 0; i <= divisor.degree; i++)
            value.c[shift + i] = normalize(value.c[shift + i] - factor * divisor.c[i]);
        trim(&value);
    }
    return value;
}

fn Poly multiply_mod(Poly* left, Poly* right, Poly* modulus_poly) {
    if (left.degree < 0 || right.degree < 0) return zero_poly();
    long[MAX_PRODUCT] product = {0};
    for (int i = 0; i <= left.degree; i++)
        for (int j = 0; j <= right.degree; j++)
            product[i + j] = (product[i + j] + left.c[i] * right.c[j]) % MODULUS;
    Poly expanded = zero_poly();
    expanded.degree = left.degree + right.degree;
    for (int i = 0; i <= expanded.degree; i++) expanded.c[i] = product[i];
    trim(&expanded);
    return poly_mod(expanded, modulus_poly);
}

fn Poly polynomial_power_mod(Poly base, long exponent, Poly* modulus_poly) {
    Poly result = zero_poly();
    result.c[0] = 1;
    result.degree = 0;
    base = poly_mod(base, modulus_poly);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply_mod(&result, &base, modulus_poly);
        base = multiply_mod(&base, &base, modulus_poly);
        exponent >>= 1;
    }
    return result;
}

fn Poly polynomial_gcd(Poly left, Poly right) {
    while (right.degree >= 0) {
        Poly remainder = poly_mod(left, &right);
        left = right;
        right = remainder;
    }
    if (left.degree < 0) return left;
    long inverse = power_mod(left.c[left.degree], MODULUS - 2);
    for (int i = 0; i <= left.degree; i++) left.c[i] = left.c[i] * inverse % MODULUS;
    return left;
}

fn Poly divide_exact(Poly value, Poly* divisor) {
    Poly quotient = zero_poly();
    quotient.degree = value.degree - divisor.degree;
    if (quotient.degree < 0) return quotient;
    long inverse = power_mod(divisor.c[divisor.degree], MODULUS - 2);
    while (value.degree >= divisor.degree) {
        int shift = value.degree - divisor.degree;
        long factor = value.c[value.degree] * inverse % MODULUS;
        quotient.c[shift] = factor;
        for (int i = 0; i <= divisor.degree; i++)
            value.c[shift + i] = normalize(value.c[shift + i] - factor * divisor.c[i]);
        trim(&value);
    }
    trim(&quotient);
    return quotient;
}

fn bool split_with_affine(Poly polynomial, long slope, long offset,
                          Poly* first, Poly* second) {
    Poly affine = zero_poly();
    affine.c[0] = offset; affine.c[1] = slope; affine.degree = 1;
    affine = poly_mod(affine, &polynomial);
    Poly powered = polynomial_power_mod(affine, (MODULUS - 1) / 2, &polynomial);
    if (powered.degree < 0) { powered.c[0] = MODULUS - 1; powered.degree = 0; }
    else powered.c[0] = normalize(powered.c[0] - 1);
    trim(&powered);
    Poly part = polynomial_gcd(polynomial, powered);
    if (part.degree <= 0 || part.degree >= polynomial.degree) return false;
    *first = part;
    *second = divide_exact(polynomial, &part);
    return true;
}

fn void collect_roots(Poly polynomial, long* roots, int* root_count, long state) {
    if (polynomial.degree == 1) {
        roots[root_count[0]] = normalize(-polynomial.c[0] * power_mod(polynomial.c[1], MODULUS - 2));
        root_count[0]++;
        return;
    }
    Poly first, second;
    for (int attempt = 0; attempt < RANDOM_ATTEMPTS; attempt++) {
        state = state * 48271 % PRNG_MODULUS;
        long slope = state % MODULUS;
        if (slope == 0) slope = 1;
        state = state * 48271 % PRNG_MODULUS;
        long offset = state % MODULUS;
        if (split_with_affine(polynomial, slope, offset, &first, &second)) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + 1);
            return;
        }
    }
    for (long offset = 0; offset < MODULUS; offset++) {
        if (split_with_affine(polynomial, 1, offset, &first, &second)) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + offset + 1);
            return;
        }
    }
}

fn int find_roots(Poly polynomial, long* roots) {
    if (polynomial.degree <= 0) return 0;
    Poly x = zero_poly(); x.c[1] = 1; x.degree = 1;
    Poly x_mod = poly_mod(x, &polynomial);
    Poly x_to_p = polynomial_power_mod(x_mod, MODULUS, &polynomial);
    int largest = x_to_p.degree > x_mod.degree ? x_to_p.degree : x_mod.degree;
    for (int i = 0; i <= largest; i++) {
        long left = i <= x_to_p.degree ? x_to_p.c[i] : 0;
        long right = i <= x_mod.degree ? x_mod.c[i] : 0;
        x_to_p.c[i] = normalize(left - right);
    }
    x_to_p.degree = largest;
    trim(&x_to_p);
    Poly linear_part = polynomial_gcd(polynomial, x_to_p);
    if (linear_part.degree <= 0) return 0;
    long seed = 1;
    for (int i = 0; i <= polynomial.degree; i++)
        seed = (seed * 31 + polynomial.c[i]) % (PRNG_MODULUS - 1) + 1;
    int root_count = 0;
    collect_roots(linear_part, roots, &root_count, seed);
    for (int i = 0; i < root_count; i++)
        for (int j = i + 1; j < root_count; j++)
            if (roots[j] < roots[i]) { long temp = roots[i]; roots[i] = roots[j]; roots[j] = temp; }
    return root_count;
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long polynomial_root_finding(long* input, usz length, uint8* output, usz capacity)
    @export("polynomial_root_finding") {
    if (input == null || length < 2 || length > MAX_INPUT || input[0] < 0 ||
        input[0] > (long)MAX_N || length != (usz)input[0] + 2) return -1;
    Poly polynomial = zero_poly();
    polynomial.degree = (int)input[0];
    for (int i = 0; i <= polynomial.degree; i++) {
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
        polynomial.c[i] = input[i + 1];
    }
    if (polynomial.c[polynomial.degree] == 0) return -1;
    long[MAX_N] roots = {0};
    int root_count = find_roots(polynomial, &roots[0]);
    usz bytes = 8 * (usz)(root_count + 1);
    if (output == null || capacity < bytes) return -2;
    store_le(output, 0, (long)root_count);
    for (int i = 0; i < root_count; i++) store_le(output, 8 * (usz)(i + 1), roots[i]);
    return (long)bytes;
}
