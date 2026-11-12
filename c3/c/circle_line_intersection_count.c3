module circle_line_intersection_count;

const MAX_Q = 32;
const MAX_OUTPUT_BYTES = 8 * MAX_Q;

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long circle_line_intersection_count(long* input, usz length,
        char* output, usz capacity) @export("circle_line_intersection_count") {
    if (input == null || length < 4 || length > 101) return -1;
    long center_x = input[0], center_y = input[1], radius = input[2], query_value = input[3];
    if (center_x < -1000 || center_x > 1000 || center_y < -1000 || center_y > 1000 ||
        radius < 0 || radius > 1000 || query_value < 0 || query_value > MAX_Q) return -1;
    usz query_count = (usz)query_value;
    if (length != 4 + 3 * query_count) return -1;

    long[MAX_Q] a_values = {}, b_values = {}, c_values = {};
    for (usz query = 0; query < query_count; query++) {
        long a = input[4 + 3 * query], b = input[5 + 3 * query], c = input[6 + 3 * query];
        if (a < -100 || a > 100 || b < -100 || b > 100 || (a == 0 && b == 0) ||
            c < -200000 || c > 200000) return -1;
        a_values[query] = a;
        b_values[query] = b;
        c_values[query] = c;
    }
    usz needed = 8 * query_count;
    if (needed > 0 && (output == null || capacity < needed)) return -2;

    char[MAX_OUTPUT_BYTES] staged = {};
    for (usz query = 0; query < query_count; query++) {
        long a = a_values[query], b = b_values[query], c = c_values[query];
        long offset = a * center_x + b * center_y + c;
        long normal_squared = a * a + b * b;
        long discriminant = radius * radius * normal_squared - offset * offset;
        long count = discriminant > 0 ? 2 : (discriminant == 0 ? 1 : 0);
        write_i64(&staged[0], 8 * query, count);
    }
    for (usz byte = 0; byte < needed; byte++) output[byte] = staged[byte];
    return (long)needed;
}
