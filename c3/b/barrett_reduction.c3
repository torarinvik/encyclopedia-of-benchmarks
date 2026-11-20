module barrett_reduction;

const long RADIX = 4294967296;
const long MAX_MODULUS = 65535;
const usz MAX_VALUES = 12;
const usz MAX_LENGTH = 15;

fn long barrett_reduction(long* input, usz length)
        @export("barrett_reduction") {
    if (input == null || length < 2 || length > MAX_LENGTH) return -1;
    long modulus = input[0];
    long count_value = input[1];
    if (modulus < 2 || modulus > MAX_MODULUS || count_value < 0 || count_value > (long)MAX_VALUES) return -1;
    usz count = (usz)count_value;
    if (length != 2 + count) return -1;
    long square_bound = modulus * modulus;
    for (usz i = 0; i < count; i++)
        if (input[2 + i] < 0 || input[2 + i] >= square_bound) return -1;

    long reciprocal = RADIX / modulus;
    long checksum = 0;
    for (usz i = 0; i < count; i++) {
        long value = input[2 + i];
        long quotient = (value * reciprocal) / RADIX;
        long remainder = value - quotient * modulus;
        if (remainder >= modulus) remainder -= modulus;
        checksum += ((long)i + 1) * (remainder + 1);
    }
    return checksum;
}
