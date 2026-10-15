module binary_prime_constant_sequence;

const usz MAX_COUNT = 4096;

fn bool is_prime(long candidate) {
    if (candidate < 2) return false;
    for (long divisor = 2; divisor <= candidate / divisor; divisor++) {
        if (candidate % divisor == 0) return false;
    }
    return true;
}

fn long binary_prime_constant_sequence(long* input, usz length, char* output,
                                      usz output_capacity)
        @export("binary_prime_constant_sequence") {
    if (input == null || length != 1 || input[0] < 0 || input[0] > (long)MAX_COUNT) return -1;
    usz count = (usz)input[0];
    if (output_capacity < count || (count != 0 && output == null)) return -2;

    usz next = 1;
    for (long candidate = 2; candidate <= input[0]; candidate++) {
        if (!is_prime(candidate)) continue;
        while (next < (usz)candidate) {
            output[next - 1] = 0;
            next++;
        }
        output[(usz)candidate - 1] = 1;
        next = (usz)candidate + 1;
    }
    while (next <= count) {
        output[next - 1] = 0;
        next++;
    }
    return (long)count;
}
