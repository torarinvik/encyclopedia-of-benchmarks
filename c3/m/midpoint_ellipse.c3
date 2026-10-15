module midpoint_ellipse;

fn void write_i32_le(char* output, usz position, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn usz count_points(long a, long b) {
    if (a == 0 && b == 0) return 1;
    if (a == 0) return (usz)(2 * b + 1);
    if (b == 0) return (usz)(2 * a + 1);
    long x = 0, y = b;
    double d1 = (double)(b * b - a * a * b) + 0.25 * (double)(a * a);
    double dx = 2.0 * b * b * x;
    double dy = 2.0 * a * a * y;
    usz count = 0;
    while (dx < dy) {
        count += 4;
        if (d1 < 0) { x++; dx += 2 * b * b; d1 += dx + b * b; }
        else { x++; y--; dx += 2 * b * b; dy -= 2 * a * a; d1 += dx - dy + b * b; }
    }
    double d2 = b * b * (x + 0.5) * (x + 0.5) + a * a * (y - 1) * (y - 1) - a * a * b * b;
    while (y >= 0) {
        count += 4;
        if (d2 > 0) { y--; dy -= 2 * a * a; d2 += a * a - dy; }
        else { y--; x++; dx += 2 * b * b; dy -= 2 * a * a; d2 += dx - dy + a * a; }
    }
    return count;
}

fn void write_symmetric(char* output, usz* position, long center_x, long center_y,
        long x, long y) {
    write_i32_le(output, *position, center_x + x); write_i32_le(output, *position + 4, center_y + y); *position = *position + 8;
    write_i32_le(output, *position, center_x - x); write_i32_le(output, *position + 4, center_y + y); *position = *position + 8;
    write_i32_le(output, *position, center_x + x); write_i32_le(output, *position + 4, center_y - y); *position = *position + 8;
    write_i32_le(output, *position, center_x - x); write_i32_le(output, *position + 4, center_y - y); *position = *position + 8;
}

fn long midpoint_ellipse(long* input, usz length, char* output, usz output_capacity)
        @export("midpoint_ellipse") {
    if (input == null || length != 4 || input[0] < -10000 || input[0] > 10000 ||
        input[1] < -10000 || input[1] > 10000 || input[2] < 0 || input[2] > 100 ||
        input[3] < 0 || input[3] > 100) return -1;
    long center_x = input[0], center_y = input[1], a = input[2], b = input[3];
    usz count = count_points(a, b);
    usz required = count * 8;
    if (output == null || output_capacity < required) return -2;
    if (a == 0 && b == 0) { write_i32_le(output, 0, center_x); write_i32_le(output, 4, center_y); return 1; }
    if (a == 0) {
        for (long y = center_y - b; y <= center_y + b; y++) {
            usz position = (usz)(y - (center_y - b)) * 8;
            write_i32_le(output, position, center_x); write_i32_le(output, position + 4, y);
        }
        return (long)count;
    }
    if (b == 0) {
        for (long x = center_x - a; x <= center_x + a; x++) {
            usz position = (usz)(x - (center_x - a)) * 8;
            write_i32_le(output, position, x); write_i32_le(output, position + 4, center_y);
        }
        return (long)count;
    }
    long x = 0, y = b;
    double d1 = (double)(b * b - a * a * b) + 0.25 * (double)(a * a);
    double dx = 2.0 * b * b * x;
    double dy = 2.0 * a * a * y;
    usz position = 0;
    while (dx < dy) {
        write_symmetric(output, &position, center_x, center_y, x, y);
        if (d1 < 0) { x++; dx += 2 * b * b; d1 += dx + b * b; }
        else { x++; y--; dx += 2 * b * b; dy -= 2 * a * a; d1 += dx - dy + b * b; }
    }
    double d2 = b * b * (x + 0.5) * (x + 0.5) + a * a * (y - 1) * (y - 1) - a * a * b * b;
    while (y >= 0) {
        write_symmetric(output, &position, center_x, center_y, x, y);
        if (d2 > 0) { y--; dy -= 2 * a * a; d2 += a * a - dy; }
        else { y--; x++; dx += 2 * b * b; dy -= 2 * a * a; d2 += dx - dy + a * a; }
    }
    return (long)count;
}
