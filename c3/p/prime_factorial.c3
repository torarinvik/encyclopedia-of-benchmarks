module prime_factorial;

const long MAX_INPUT = 4096;
const usz MAX_DISTINCT_FACTORS = 5;

fn bool is_prime_by_source_trial_division(long candidate) {
    if (candidate == 2) return true;
    long half_candidate = candidate / 2 + 1;
    for (long divisor = 2; divisor <= half_candidate; divisor++) {
        if (candidate % divisor == 0) return false;
        if (divisor == half_candidate) return true;
    }
    return false;
}

fn long prime_factorial(long value, char* output, usz output_capacity) @export("prime_factorial") {
    if (value < 2 || value > MAX_INPUT) return -1;
    uint[MAX_DISTINCT_FACTORS] factors;
    usz count = 0;
    for (long candidate = 2; candidate <= value; candidate++) {
        if (is_prime_by_source_trial_division(candidate) && value % candidate == 0) {
            factors[count++] = (uint)candidate;
        }
    }
    usz required = count * 4;
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    for (usz index = 0; index < count; index++) {
        uint factor = factors[index];
        for (usz byte_index = 0; byte_index < 4; byte_index++) {
            output[position++] = (char)(factor & 0xFF);
            factor >>= 8;
        }
    }
    return (long)position;
}
