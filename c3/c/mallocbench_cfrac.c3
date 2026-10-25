/*
 * Clean-room bounded CFRAC profile based on the published
 * Morrison-Brillhart continued-fraction factorization method.
 * No code from the restricted arbitrary-precision package is included.
 */
module mallocbench_cfrac;

const MAX_BASE = 10;
const MAX_ITERATIONS = 48;
const MAX_PRIME = 10000;

fn ulong gcd(ulong a, ulong b) {
    while (b != 0) { ulong r = a % b; a = b; b = r; }
    return a;
}

fn ulong modpow(ulong base, ulong exponent, ulong modulus) {
    ulong result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1ul) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn bool is_prime(uint value) {
    if (value < 2) return false;
    for (uint divisor = 2; (ulong)divisor * divisor <= value; divisor++)
        if (value % divisor == 0) return false;
    return true;
}

fn bool make_base(ulong n, uint requested, uint[MAX_BASE] base) {
    uint count = 1;
    base[0] = 2;
    for (uint p = 3; p <= MAX_PRIME && count < requested; p += 2) {
        if (!is_prime(p)) continue;
        ulong residue = modpow(n % p, (p - 1) / 2, p);
        if (residue == 0) return false; // The source selects residue zero; this bounded domain rejects it.
        if (residue == 1) base[count++] = p;
    }
    return count == requested;
}

fn long dependency_factor(ulong n, ulong selected, uint relation_count,
    ulong[MAX_ITERATIONS] relation_a, uint8[MAX_ITERATIONS * MAX_BASE] relation_exp,
    uint[MAX_BASE] base, uint base_count) {
    ulong x = 1;
    ulong[MAX_BASE] exponent_sum;
    for (uint i = 0; i < relation_count; i++) {
        if ((selected & (1ul << i)) == 0) continue;
        x = (x * relation_a[i]) % n;
        for (uint j = 0; j < base_count; j++) exponent_sum[j] += relation_exp[i * MAX_BASE + j];
    }
    ulong y = 1;
    for (uint j = 0; j < base_count; j++) y = (y * modpow(base[j], exponent_sum[j] / 2, n)) % n;
    ulong minus = gcd(x >= y ? x - y : y - x, n);
    if (minus > 1 && minus < n) return (long)minus;
    ulong plus = gcd(x + y, n);
    if (plus > 1 && plus < n) return (long)plus;
    return 0;
}

fn long mallocbench_cfrac(long* input, usz length) @export("mallocbench_cfrac") {
    if (input == null || length != 3) return -1;
    long n_value = input[0], base_value = input[1], iteration_value = input[2];
    if (n_value < 15 || n_value > 1000000 || (n_value & 1) == 0 ||
        base_value < 2 || base_value > MAX_BASE || iteration_value < 1 || iteration_value > MAX_ITERATIONS) return -1;
    ulong n = (ulong)n_value;
    ulong root = 0;
    while ((root + 1) <= n / (root + 1)) root++;
    if (root * root == n) return -1;
    uint base_count = (uint)base_value, iteration_limit = (uint)iteration_value;
    uint[MAX_BASE] base;
    if (!make_base(n, base_count, base)) return -1;

    ulong[MAX_BASE + 1] basis_vector, basis_combo;
    bool[MAX_BASE + 1] basis_used;
    ulong[MAX_ITERATIONS] relation_a;
    uint8[MAX_ITERATIONS * MAX_BASE] relation_exp;
    uint relation_count = 0;
    long u = (long)(2 * root), previous_u = (long)(2 * root);
    long q_value = 0, q_denominator = 1, previous_denominator = (long)(n - root * root);
    long a_value = 1, previous_a = (long)root;
    uint sign = 0;

    for (uint iteration = 0; iteration < iteration_limit; iteration++) {
        long old_a = a_value;
        a_value = (q_value * a_value + previous_a) % (long)n;
        previous_a = old_a;
        long old_denominator = q_denominator;
        q_denominator = q_value * (previous_u - u) + previous_denominator;
        previous_denominator = old_denominator;
        previous_u = u;
        if (q_denominator <= 0) return (long)n;
        q_value = 1;
        long remainder = u - q_denominator;
        if (remainder >= q_denominator) {
            q_value = u / q_denominator;
            remainder = u % q_denominator;
        }
        u = (long)(2 * root) - remainder;
        sign ^= 1;
        if (q_denominator == 1) return (long)n;

        ulong residual = (ulong)q_denominator;
        uint8[MAX_BASE] exponents;
        for (uint j = 0; j < base_count; j++) {
            while (residual % base[j] == 0) { residual /= base[j]; exponents[j]++; }
        }
        if (residual != 1) continue;
        relation_a[relation_count] = (ulong)a_value;
        for (uint j = 0; j < base_count; j++) relation_exp[relation_count * MAX_BASE + j] = exponents[j];
        ulong vector = (ulong)sign;
        for (uint j = 0; j < base_count; j++) if ((exponents[j] & 1) != 0) vector |= 1ul << (j + 1);
        ulong combination = 1ul << relation_count;
        relation_count++;
        bool inserted = false;
        for (uint bit = 0; bit <= base_count; bit++) {
            if ((vector & (1ul << bit)) == 0) continue;
            if (basis_used[bit]) { vector ^= basis_vector[bit]; combination ^= basis_combo[bit]; }
            else {
                basis_used[bit] = true;
                basis_vector[bit] = vector;
                basis_combo[bit] = combination;
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            long factor = dependency_factor(n, combination, relation_count, relation_a, relation_exp, base, base_count);
            if (factor > 1) return factor;
        }
    }
    return (long)n;
}
