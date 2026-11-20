module powerful_numbers_square_cube_enumeration;

const long MAX_INPUT_WORDS = 2;
const long MAX_LIMIT = 100;
const usz MAX_VALUES = 14;

fn bool is_squarefree(long value) {
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % (divisor * divisor) == 0) return false;
    }
    return true;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long powerful_numbers_square_cube_enumeration(long *input, usz length,
        char *output, usz capacity) @export("powerful_numbers_square_cube_enumeration") {
    if (input == null || length < 1 || length > MAX_INPUT_WORDS || length != 1) return -1;
    long limit = input[0];
    if (limit < 1 || limit > MAX_LIMIT) return -1;

    long[MAX_VALUES] values = {0};
    usz count = 0;
    for (long b = 1; b * b * b <= limit; b++) {
        if (!is_squarefree(b)) continue;
        long cube = b * b * b;
        for (long a = 1; a * a * cube <= limit; a++) {
            values[count] = a * a * cube;
            count++;
        }
    }
    for (usz index = 1; index < count; index++) {
        long value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = value;
    }

    usz output_bytes = (count + 1) * 8;
    if (output == null || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (long)count);
    for (usz index = 0; index < count; index++)
        store_i64_le(output, (index + 1) * 8, values[index]);
    return (long)output_bytes;
}
