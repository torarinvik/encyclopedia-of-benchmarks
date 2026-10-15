module amicable_pairs_below;

const usz MAX_LIMIT = 8000;

fn void write_u32_le(char* output, usz* position, long value) {
    long encoded = value;
    for (usz byte = 0; byte < 4; byte++) {
        output[*position] = (char)(encoded % 256);
        encoded /= 256;
        *position = *position + 1;
    }
}

fn long amicable_pairs_below(long* values, usz length, char* output, usz output_capacity)
        @export("amicable_pairs_below") {
    if (values == null || length != 1) return -1;
    if (values[0] < 1 || values[0] > (long)MAX_LIMIT) return -1;
    usz limit = (usz)values[0];
    long[MAX_LIMIT] divisor_sums;
    for (usz index = 0; index < MAX_LIMIT; index++) divisor_sums[index] = 0;
    for (usz divisor = 1; divisor < limit; divisor++) {
        for (usz multiple = divisor * 2; multiple < limit; multiple += divisor) {
            divisor_sums[multiple] += (long)divisor;
        }
    }

    usz pair_count = 0;
    for (usz smaller = 2; smaller < limit; smaller++) {
        long larger = divisor_sums[smaller];
        if (larger > (long)smaller && larger < (long)limit &&
            divisor_sums[(usz)larger] == (long)smaller) pair_count++;
    }
    usz required = pair_count * 8;
    if (output_capacity < required || (required > 0 && output == null)) return -2;

    usz position = 0;
    for (usz smaller = 2; smaller < limit; smaller++) {
        long larger = divisor_sums[smaller];
        if (larger > (long)smaller && larger < (long)limit &&
            divisor_sums[(usz)larger] == (long)smaller) {
            write_u32_le(output, &position, (long)smaller);
            write_u32_le(output, &position, larger);
        }
    }
    return (long)pair_count;
}
