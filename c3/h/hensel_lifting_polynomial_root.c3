module hensel_lifting_polynomial_root;

const long HLR_MAX_DEGREE = 4;
const long HLR_MAX_PRIME = 43;
const long HLR_MAX_EXPONENT = 6;
const long HLR_MAX_MODULUS = 100000;
const usz HLR_MAX_LENGTH = 10;

fn long hlr_mod(long value, long modulus) {
    long result = value % modulus;
    if (result < 0) result += modulus;
    return result;
}

fn bool hlr_is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor * divisor <= value; divisor++)
        if (value % divisor == 0) return false;
    return true;
}

fn long hlr_eval(long* coefficients, long degree, long x, long modulus) {
    long result = 0;
    for (long i = degree; i >= 0; i--)
        result = hlr_mod(result * x + coefficients[i], modulus);
    return result;
}

fn long hlr_derivative(long* coefficients, long degree, long x, long prime) {
    long result = 0;
    for (long i = degree; i >= 1; i--)
        result = hlr_mod(result * x + i * coefficients[i], prime);
    return result;
}

fn long hensel_lifting_polynomial_root(long* input, usz length)
        @export("hensel_lifting_polynomial_root") {
    if (input == null || length < 6 || length > HLR_MAX_LENGTH) return -1;
    long degree = input[0];
    long prime = input[1];
    long exponent = input[2];
    long seed = input[3];
    if (degree < 1 || degree > HLR_MAX_DEGREE || prime < 2 || prime > HLR_MAX_PRIME ||
        exponent < 1 || exponent > HLR_MAX_EXPONENT || seed < 0 || seed >= prime ||
        length != (usz)(degree + 5) || !hlr_is_prime(prime)) return -1;
    long* coefficients = input + 4;
    for (long i = 0; i <= degree; i++)
        if (coefficients[i] < -1000 || coefficients[i] > 1000) return -1;

    long modulus = 1;
    for (long i = 0; i < exponent; i++) {
        if (modulus > HLR_MAX_MODULUS / prime) return -1;
        modulus *= prime;
    }
    if (hlr_eval(coefficients, degree, seed, prime) != 0) return -1;
    long derivative = hlr_derivative(coefficients, degree, seed, prime);
    if (derivative == 0) return -1;
    long inverse = 0;
    for (long candidate = 1; candidate < prime; candidate++) {
        if (derivative * candidate % prime == 1) {
            inverse = candidate;
            break;
        }
    }
    if (inverse == 0) return -1;

    long root = seed;
    long power = prime;
    for (long stage = 1; stage < exponent; stage++) {
        long next_power = power * prime;
        long residue = hlr_eval(coefficients, degree, root, next_power);
        long quotient_digit = residue / power;
        long correction = hlr_mod(-quotient_digit * inverse, prime);
        root += correction * power;
        power = next_power;
    }
    return root;
}
