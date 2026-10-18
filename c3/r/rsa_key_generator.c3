module rsa_key_generator;

const long INVALID_RESULT = -1;
const long MIN_KEY_SIZE = 2;
const long MAX_KEY_SIZE = 20;
const long MAX_DRAWS = 1024;
const usz MAX_PACKED_LENGTH = 1027;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong LOW_63_MASK = 0x7ffffffffffffffful;

struct DrawState {
    long* values;
    usz length;
    usz cursor;
    long key_size;
    bool failed;
}

fn bool next_draw(DrawState* state, long low, long high, long* result) {
    if (state.cursor >= state.length) { state.failed = true; return false; }
    long value = state.values[state.cursor];
    state.cursor += 1;
    if (value < low || value >= high) { state.failed = true; return false; }
    result[0] = value;
    return true;
}

fn long gcd_i64(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a < 0 ? -a : a;
}

fn long power_mod_i64(long base, long exponent_input, long modulus) {
    long exponent = exponent_input;
    long result = 1, power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}

fn bool rabin_miller(long num, DrawState* state) {
    long s = num - 1, t = 0;
    while ((s % 2) == 0) { s /= 2; t += 1; }
    for (int round = 0; round < 5; round += 1) {
        long base;
        if (!next_draw(state, 2, num - 1, &base)) return false;
        long value = power_mod_i64(base, s, num);
        if (value != 1) {
            long i = 0;
            while (value != num - 1) {
                if (i == t - 1) return false;
                i += 1;
                value = (value * value) % num;
            }
        }
    }
    return true;
}

fn bool is_prime_low_num(long num, DrawState* state) {
    if (num < 2) return false;
    if (num <= 997) {
        for (long divisor = 2; divisor * divisor <= num; divisor += 1)
            if (num % divisor == 0) return false;
        return true;
    }
    for (long divisor = 2; divisor <= 997; divisor += 1)
        if (num % divisor == 0) return false;
    return rabin_miller(num, state);
}

fn bool generate_large_prime(DrawState* state, long* prime) {
    long low = 1l << (state.key_size - 1);
    long high = 1l << state.key_size;
    while (!state.failed) {
        long candidate;
        if (!next_draw(state, low, high, &candidate)) return false;
        if (is_prime_low_num(candidate, state)) { prime[0] = candidate; return true; }
    }
    return false;
}

fn long find_mod_inverse(long a, long modulus) {
    if (gcd_i64(a, modulus) != 1) return INVALID_RESULT;
    long u1 = 1, u2 = 0, u3 = a;
    long v1 = 0, v2 = 1, v3 = modulus;
    while (v3 != 0) {
        long quotient = u3 / v3;
        long next_v1 = u1 - quotient * v1;
        long next_v2 = u2 - quotient * v2;
        long next_v3 = u3 - quotient * v3;
        u1 = v1; u2 = v2; u3 = v3;
        v1 = next_v1; v2 = next_v2; v3 = next_v3;
    }
    return u1 % modulus;
}

fn ulong hash_i64(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint byte = 0; byte < 8; byte += 1)
        hash = (hash ^ ((bits >> (byte * 8)) & 255ul)) * FNV_PRIME;
    return hash;
}

fn long rsa_key_generator(long* packed, usz length) @export("rsa_key_generator") {
    if (packed == null || length < 2 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    long key_size = packed[0], draw_count = packed[1];
    if (key_size < MIN_KEY_SIZE || key_size > MAX_KEY_SIZE || draw_count < 0 || draw_count > MAX_DRAWS ||
        length != (usz)(2 + draw_count)) return INVALID_RESULT;
    long draw_limit = 1l << key_size;
    for (usz i = 0; i < (usz)draw_count; i += 1)
        if (packed[2 + i] < 2 || packed[2 + i] >= draw_limit) return INVALID_RESULT;

    DrawState state = {packed, length, 2, key_size, false};
    long p, q;
    if (!generate_large_prime(&state, &p) || !generate_large_prime(&state, &q)) return INVALID_RESULT;
    long n = p * q;
    long phi = (p - 1) * (q - 1);
    long low = 1l << (key_size - 1), high = 1l << key_size;
    long e;
    while (true) {
        if (!next_draw(&state, low, high, &e)) return INVALID_RESULT;
        if (gcd_i64(e, phi) == 1) break;
    }
    long d = find_mod_inverse(e, phi);
    ulong hash = FNV_OFFSET_BASIS;
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, e);
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, d);
    return (long)(hash & LOW_63_MASK);
}
