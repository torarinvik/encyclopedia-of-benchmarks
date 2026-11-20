module pisano_period;

const long MAX_MODULUS = 64;
const usz MAX_INPUT_LENGTH = 2;

fn long pisano_period(long* input, usz length) @export("pisano_period") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_MODULUS) return -1;

    long modulus = input[0];
    long initial_next = 1 % modulus;
    long previous = 0;
    long current = initial_next;
    for (long period = 1; period <= 6 * modulus; period++) {
        long next = (previous + current) % modulus;
        previous = current;
        current = next;
        if (previous == 0 && current == initial_next) return period;
    }
    return -1;
}
