module numbers_with_prime_divisor_count_not_two;

const usz MAX_INPUT_LENGTH = 2;
const usz MAX_LIMIT = 1000;
const long MAX_LIMIT_VALUE = 1000;

fn bool is_prime_count(ushort value) {
    if (value < 2) return false;
    for (ushort divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn void store_i64(char* output, usz offset, long value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long numbers_with_prime_divisor_count_not_two(long* input, usz length,
        char* output, usz capacity) @export("numbers_with_prime_divisor_count_not_two") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_LIMIT_VALUE) return -1;

    usz limit = (usz)input[0];
    ushort[MAX_LIMIT] divisor_counts;
    for (usz divisor = 1; divisor < limit; divisor++) {
        for (usz multiple = divisor; multiple < limit; multiple += divisor)
            divisor_counts[multiple]++;
    }
    usz selected_count = 0;
    for (usz n = 1; n < limit; n++) {
        ushort count = divisor_counts[n];
        if (count != 2 && is_prime_count(count)) selected_count++;
    }
    usz output_bytes = selected_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    usz output_index = 0;
    for (usz n = 1; n < limit; n++) {
        ushort count = divisor_counts[n];
        if (count != 2 && is_prime_count(count)) {
            store_i64(output, output_index * 8, (long)n);
            output_index++;
        }
    }
    return (long)output_bytes;
}
