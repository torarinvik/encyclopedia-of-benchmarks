module shootout_random;

const long MAX_CALL_COUNT = 1000000;
const long MODULUS = 139968;
const long FRACTION_SCALE = 1000000000;
const usz MAX_OUTPUT_BYTES = 13;

fn long shootout_random(long call_count, char* output, usz output_capacity) @export("shootout_random") {
    if (call_count < 1 || call_count > MAX_CALL_COUNT) return -1;

    long state = 42;
    for (long call = 0; call < call_count; call++)
        state = (state * 3877 + 29573) % MODULUS;

    long scaled = (100 * state * FRACTION_SCALE + MODULUS / 2) / MODULUS;
    long whole = scaled / FRACTION_SCALE;
    long fraction = scaled % FRACTION_SCALE;
    char[MAX_OUTPUT_BYTES] staged;
    char[3] reversed_digits;
    usz digit_count = 0;
    do {
        reversed_digits[digit_count++] = (char)('0' + whole % 10);
        whole /= 10;
    } while (whole != 0);

    usz used = 0;
    while (digit_count > 0) staged[used++] = reversed_digits[--digit_count];
    staged[used++] = '.';
    for (long place = 100000000; place > 0; place /= 10) {
        staged[used++] = (char)('0' + fraction / place);
        fraction %= place;
    }
    staged[used++] = '\n';

    if (output == null || output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
