module midpoint_circle;

fn void write_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    output[position] = (char)bits;
    output[position + 1] = (char)(bits >> 8);
    output[position + 2] = (char)(bits >> 16);
    output[position + 3] = (char)(bits >> 24);
}

usz count_points(long radius) {
    if (radius == 0) return 1;
    long x = radius;
    long y = 0;
    long decision = 1 - radius;
    usz count = 8;
    while (x > y) {
        y++;
        if (decision <= 0) decision += 2 * y + 1;
        else {
            x--;
            decision += 2 * y - 2 * x + 1;
        }
        count += 8;
    }
    return count;
}

fn void write_point(char* output, usz* position, long x, long y) {
    write_i32_le(output, position[0], x);
    write_i32_le(output, position[0] + 4, y);
    position[0] += 8;
}

fn void write_symmetric(char* output, usz* position, long center_x, long center_y, long x, long y) {
    write_point(output, position, center_x + x, center_y + y);
    write_point(output, position, center_x - x, center_y + y);
    write_point(output, position, center_x + x, center_y - y);
    write_point(output, position, center_x - x, center_y - y);
    write_point(output, position, center_x + y, center_y + x);
    write_point(output, position, center_x - y, center_y + x);
    write_point(output, position, center_x + y, center_y - x);
    write_point(output, position, center_x - y, center_y - x);
}

fn long midpoint_circle(long* input, usz length, char* output, usz output_capacity)
    @export("midpoint_circle") {
    if (input == null || length != 3 || input[0] < -10000 || input[0] > 10000 ||
        input[1] < -10000 || input[1] > 10000 || input[2] < 0 || input[2] > 1000) return -1;
    long center_x = input[0], center_y = input[1], radius = input[2];
    usz count = count_points(radius);
    usz required = count * 8;
    if (output == null || output_capacity < required) return -2;
    if (radius == 0) {
        write_i32_le(output, 0, center_x);
        write_i32_le(output, 4, center_y);
        return 1;
    }

    usz position = 0;
    long x = radius, y = 0, decision = 1 - radius;
    write_symmetric(output, &position, center_x, center_y, x, y);
    while (x > y) {
        y++;
        if (decision <= 0) decision += 2 * y + 1;
        else {
            x--;
            decision += 2 * y - 2 * x + 1;
        }
        write_symmetric(output, &position, center_x, center_y, x, y);
    }
    return (long)count;
}
