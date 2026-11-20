module smarandache_wellin_prime_prefix_scan;

const long MAX_COUNT = 6;
const usz MAX_OUTPUT_VALUES = 3;

fn bool is_small_prime(ulong value) {
    if (value < 2) return false;
    for (ulong divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn ulong multiply_mod(ulong left, ulong right, ulong modulus) {
    return (left * right) % modulus;
}

fn ulong power_mod(ulong base, ulong exponent, ulong modulus) {
    ulong result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = multiply_mod(result, base, modulus);
        exponent >>= 1;
        if (exponent != 0) base = multiply_mod(base, base, modulus);
    }
    return result;
}

fn bool is_prime_prefix(ulong value) {
    ulong[12] small_primes = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};
    ulong[3] bases = {2, 7, 61};
    if (value < 2) return false;
    for (usz index = 0; index < 12; index++) {
        if (value == small_primes[index]) return true;
        if (value % small_primes[index] == 0) return false;
    }
    ulong odd_part = value - 1;
    usz twos = 0;
    while ((odd_part & 1) == 0) {
        odd_part >>= 1;
        twos++;
    }
    for (usz index = 0; index < 3; index++) {
        ulong witness = power_mod(bases[index], odd_part, value);
        if (witness == 1 || witness == value - 1) continue;
        usz round = 1;
        while (round < twos && witness != value - 1) {
            witness = multiply_mod(witness, witness, value);
            round++;
        }
        if (witness != value - 1) return false;
    }
    return true;
}

fn long smarandache_wellin_prime_prefix_scan(long* input, usz length,
        char* output, usz capacity) @export("smarandache_wellin_prime_prefix_scan") {
    if (input == null || length < 1 || length > 2) return -1;
    if (input[0] < 0 || input[0] > MAX_COUNT || length != 1) return -1;

    ulong[3] staged_values = {0};
    usz result_count = 0;
    ulong prefix = 0;
    ulong candidate = 2;
    for (long index = 0; index < input[0]; index++) {
        while (!is_small_prime(candidate)) {
            if (candidate == 2) candidate++;
            else candidate += 2;
        }
        ulong scale = 10;
        while (scale <= candidate) scale *= 10;
        prefix = prefix * scale + candidate;
        if (is_prime_prefix(prefix)) {
            staged_values[result_count] = prefix;
            result_count++;
        }
        if (candidate == 2) candidate++;
        else candidate += 2;
    }
    usz byte_count = result_count * 8;
    if (output == null || capacity < byte_count) return -2;
    char[24] bytes = {0};
    for (usz item = 0; item < result_count; item++) {
        for (usz byte = 0; byte < 8; byte++)
            bytes[item * 8 + byte] = (char)((staged_values[item] >> (byte * 8)) & 255);
    }
    for (usz byte = 0; byte < byte_count; byte++) output[byte] = bytes[byte];
    return (long)byte_count;
}
