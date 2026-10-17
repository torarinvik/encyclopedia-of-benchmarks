module minone;

const usz MAX_LENGTH = 64;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;

fn long minone(long* input, usz length) @export("minone") {
    if (input == null || length < 1 || length > MAX_LENGTH) return -1;
    long total = 0;
    for (usz i = 0; i < length; i++) {
        long value = input[i];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1;
        total += value * value;
    }
    return total;
}
