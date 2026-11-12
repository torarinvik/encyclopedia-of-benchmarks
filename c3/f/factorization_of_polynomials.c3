module factorization_of_polynomials;

const usz MAX_N = 8;
const usz MAX_POLY = 9;
const usz MAX_FACTORS = 8;
const usz MAX_INPUT = 12;
const usz MAX_OUTPUT_BYTES = 216;

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn int power_small(int base, int exponent) {
    int value = 1;
    for (int i = 0; i < exponent; i++) value *= base;
    return value;
}

fn void monic_from_code(long* polynomial, int degree, int code, int prime) {
    for (int i = 0; i < degree; i++) {
        polynomial[i] = code % prime;
        code /= prime;
    }
    polynomial[degree] = 1;
}

fn bool exact_quotient(long* polynomial, int degree, long* divisor,
                       int divisor_degree, int prime, long* quotient) {
    if (degree < divisor_degree) return false;
    long[MAX_POLY] remainder = {0};
    for (int i = 0; i <= degree; i++) remainder[i] = polynomial[i];
    int quotient_degree = degree - divisor_degree;
    for (int i = 0; i <= quotient_degree; i++) quotient[i] = 0;
    for (int shift = quotient_degree; shift >= 0; shift--) {
        long factor = remainder[shift + divisor_degree];
        quotient[shift] = factor;
        for (int j = 0; j <= divisor_degree; j++) {
            long value = (remainder[shift + j] - factor * divisor[j]) % prime;
            if (value < 0) value += prime;
            remainder[shift + j] = value;
        }
    }
    for (int i = 0; i < divisor_degree; i++) if (remainder[i] != 0) return false;
    return true;
}

fn bool irreducible(long* candidate, int degree, int prime) {
    for (int divisor_degree = 1; divisor_degree <= degree / 2; divisor_degree++) {
        int limit = power_small(prime, divisor_degree);
        for (int code = 0; code < limit; code++) {
            long[MAX_POLY] divisor = {0};
            long[MAX_POLY] quotient = {0};
            monic_from_code(&divisor[0], divisor_degree, code, prime);
            if (exact_quotient(candidate, degree, &divisor[0], divisor_degree,
                               prime, &quotient[0])) return false;
        }
    }
    return true;
}

fn void swap_factor(long[MAX_FACTORS][MAX_POLY]* factors, int* degrees,
                    long* multiplicities, int left, int right) {
    long[MAX_POLY] row = {0};
    for (int j = 0; j < MAX_POLY; j++) {
        row[j] = factors[left][j];
        factors[left][j] = factors[right][j];
        factors[right][j] = row[j];
    }
    int degree = degrees[left];
    degrees[left] = degrees[right];
    degrees[right] = degree;
    long multiplicity = multiplicities[left];
    multiplicities[left] = multiplicities[right];
    multiplicities[right] = multiplicity;
}

fn int factor_polynomial(long* coefficients, int input_degree, int prime,
                         long[MAX_FACTORS][MAX_POLY]* factors,
                         int* degrees, long* multiplicities) {
    long[MAX_POLY] work = {0};
    for (int i = 0; i <= input_degree; i++) work[i] = coefficients[i];
    int work_degree = input_degree;
    int factor_count = 0;
    for (int degree = 1; degree <= input_degree / 2; degree++) {
        int limit = power_small(prime, degree);
        for (int code = 0; code < limit; code++) {
            long[MAX_POLY] candidate = {0};
            monic_from_code(&candidate[0], degree, code, prime);
            if (!irreducible(&candidate[0], degree, prime)) continue;
            long[MAX_POLY] quotient = {0};
            long multiplicity = 0;
            while (work_degree >= degree &&
                   exact_quotient(&work[0], work_degree, &candidate[0], degree,
                                  prime, &quotient[0])) {
                multiplicity++;
                work_degree -= degree;
                for (int i = 0; i <= work_degree; i++) work[i] = quotient[i];
            }
            if (multiplicity != 0) {
                degrees[factor_count] = degree;
                multiplicities[factor_count] = multiplicity;
                for (int i = 0; i <= degree; i++) factors[factor_count][i] = candidate[i];
                factor_count++;
            }
        }
    }
    if (work_degree > 0) {
        degrees[factor_count] = work_degree;
        multiplicities[factor_count] = 1;
        for (int i = 0; i <= work_degree; i++) factors[factor_count][i] = work[i];
        factor_count++;
    }
    for (int i = 0; i < factor_count; i++) {
        for (int j = i + 1; j < factor_count; j++) {
            bool after = degrees[i] > degrees[j];
            if (degrees[i] == degrees[j]) {
                for (int k = 0; k <= degrees[i]; k++) {
                    if (factors[i][k] == factors[j][k]) continue;
                    after = factors[i][k] > factors[j][k];
                    break;
                }
            }
            if (after) swap_factor(factors, degrees, multiplicities, i, j);
        }
    }
    return factor_count;
}

fn long factorization_of_polynomials(long* input, usz length, uint8* output, usz capacity)
    @export("factorization_of_polynomials") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long degree_value = input[0];
    long prime_value = input[1];
    if (degree_value < 0 || degree_value > (long)MAX_N ||
        (prime_value != 2 && prime_value != 3 && prime_value != 5) ||
        length != (usz)degree_value + 3) return -1;
    int degree = (int)degree_value;
    int prime = (int)prime_value;
    if (input[degree + 2] != 1) return -1;
    for (int i = 0; i <= degree; i++)
        if (input[i + 2] < 0 || input[i + 2] >= prime) return -1;

    long[MAX_FACTORS][MAX_POLY] factors = {0};
    int[MAX_FACTORS] degrees = {0};
    long[MAX_FACTORS] multiplicities = {0};
    int factor_count = factor_polynomial(&input[2], degree, prime,
                                         &factors, &degrees[0], &multiplicities[0]);
    usz words = 1;
    for (int i = 0; i < factor_count; i++) words += (usz)degrees[i] + 3;
    usz bytes = words * 8;
    if (bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < bytes) return -2;

    usz word = 0;
    store_le(output, 8 * word++, (long)factor_count);
    for (int i = 0; i < factor_count; i++) {
        store_le(output, 8 * word++, multiplicities[i]);
        store_le(output, 8 * word++, (long)degrees[i]);
        for (int j = 0; j <= degrees[i]; j++)
            store_le(output, 8 * word++, factors[i][j]);
    }
    return (long)bytes;
}
