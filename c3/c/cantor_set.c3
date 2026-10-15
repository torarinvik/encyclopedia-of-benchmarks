module cantor_set;

const long MAX_LEVEL = 6;
const ulong SCALE = 1000000ul;

fn bool put_byte(char* output, usz capacity, usz* length, char value) {
    if (*length >= capacity) return false;
    output[*length] = value;
    *length += 1;
    return true;
}

fn bool put_uint(char* output, usz capacity, usz* length, ulong value) {
    char[20] digits;
    usz count = 0;
    do {
        digits[count++] = (char)('0' + value % 10ul);
        value /= 10ul;
    } while (value != 0ul);
    while (count > 0) {
        count -= 1;
        if (!put_byte(output, capacity, length, digits[count])) return false;
    }
    return true;
}

fn bool put_fixed(char* output, usz capacity, usz* length, ulong ticks) {
    ulong fraction = ticks % SCALE;
    if (!put_uint(output, capacity, length, ticks / SCALE) ||
        !put_byte(output, capacity, length, '.')) return false;
    for (ulong divisor = 100000ul; divisor > 0ul; divisor /= 10ul) {
        char digit = (char)('0' + fraction / divisor % 10ul);
        if (!put_byte(output, capacity, length, digit)) return false;
    }
    return true;
}

// Render source-style Cantor levels with integer ternary interval positions.
fn long cantor_set(long* input, usz length, char* output, usz output_capacity) @export("cantor_set") {
    if (input == null || length != 3 || input[0] < 0 || input[0] > input[1] || input[1] > 100000 || input[2] < 0 || input[2] > MAX_LEVEL) return -1;
    if (output == null) return -2;
    ulong start = (ulong)input[0];
    ulong span = (ulong)(input[1] - input[0]);
    ulong[64] positions;
    ulong[64] next;
    positions[0] = 0ul;
    usz interval_count = 1;
    usz output_length = 0;
    ulong denominator = 1ul;
    for (long level = 0; level <= input[2]; level++) {
        if (!put_byte(output, output_capacity, &output_length, 'L') ||
            !put_byte(output, output_capacity, &output_length, 'e') ||
            !put_byte(output, output_capacity, &output_length, 'v') ||
            !put_byte(output, output_capacity, &output_length, 'e') ||
            !put_byte(output, output_capacity, &output_length, 'l') ||
            !put_byte(output, output_capacity, &output_length, ' ') ||
            !put_uint(output, output_capacity, &output_length, (ulong)level) ||
            !put_byte(output, output_capacity, &output_length, '\t')) return -2;
        for (usz i = 0; i < interval_count; i++) {
            ulong left_num = start * denominator + span * positions[i];
            ulong right_num = start * denominator + span * (positions[i] + 1ul);
            ulong left = (left_num * SCALE + denominator / 2ul) / denominator;
            ulong right = (right_num * SCALE + denominator / 2ul) / denominator;
            if (!put_byte(output, output_capacity, &output_length, '\t') ||
                !put_byte(output, output_capacity, &output_length, '[') ||
                !put_fixed(output, output_capacity, &output_length, left) ||
                !put_byte(output, output_capacity, &output_length, ']') ||
                !put_byte(output, output_capacity, &output_length, ' ') ||
                !put_byte(output, output_capacity, &output_length, '-') ||
                !put_byte(output, output_capacity, &output_length, '-') ||
                !put_byte(output, output_capacity, &output_length, ' ') ||
                !put_byte(output, output_capacity, &output_length, '[') ||
                !put_fixed(output, output_capacity, &output_length, right) ||
                !put_byte(output, output_capacity, &output_length, ']')) return -2;
        }
        if (!put_byte(output, output_capacity, &output_length, '\n')) return -2;
        if (level < input[2]) {
            if (!put_byte(output, output_capacity, &output_length, '\n')) return -2;
            for (usz i = 0; i < interval_count; i++) {
                next[2 * i] = positions[i] * 3ul;
                next[2 * i + 1] = positions[i] * 3ul + 2ul;
            }
            interval_count *= 2;
            for (usz i = 0; i < interval_count; i++) positions[i] = next[i];
            denominator *= 3ul;
        }
    }
    if (output_length >= output_capacity) return -2;
    output[output_length++] = 0;
    return (long)output_length;
}
