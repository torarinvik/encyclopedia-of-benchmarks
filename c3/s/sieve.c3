module sieve;

const long SIEVE_LIMIT = 8192;
const long MAX_ITERATIONS = 64;

fn long sieve(long iterations, char* output, usz output_capacity) @export("sieve") {
    if (iterations < 0 || iterations > MAX_ITERATIONS) return -1;

    char[8193] flags;
    long count = 0;
    for (long pass = 0; pass < iterations; pass++) {
        count = 0;
        for (long value = 2; value <= SIEVE_LIMIT; value++) flags[value] = 1;
        for (long value = 2; value <= SIEVE_LIMIT; value++) {
            if (flags[value] != 0) {
                count++;
                for (long multiple = value + value; multiple <= SIEVE_LIMIT; multiple += value)
                    flags[multiple] = 0;
            }
        }
    }

    char[10] reversed_digits;
    usz digit_count = 0;
    long remaining = count;
    do {
        reversed_digits[digit_count++] = (char)(48 + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    usz required = 8 + digit_count;
    if (output == null || output_capacity < required) return -2;
    output[0] = (char)67; output[1] = (char)111; output[2] = (char)117;
    output[3] = (char)110; output[4] = (char)116; output[5] = (char)58;
    output[6] = (char)32;
    for (usz index = 0; index < digit_count; index++)
        output[7 + index] = reversed_digits[digit_count - index - 1];
    output[required - 1] = (char)10;
    return (long)required;
}
