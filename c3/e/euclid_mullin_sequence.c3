module euclid_mullin_sequence;

const usz MAX_PARSEABLE_LENGTH = 2;
const long MAX_N = 8;

fn long least_prime_factor(long value) {
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return divisor;
    }
    return value;
}

fn long euclid_mullin_term(long index) {
    long product = 1;
    long term = 1;
    for (long position = 0; position < index; position++) {
        term = least_prime_factor(product + 1);
        product *= term;
    }
    return term;
}

fn long euclid_mullin_sequence(long* input, usz length)
    @export("euclid_mullin_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    return euclid_mullin_term(input[0]);
}
