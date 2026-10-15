module bresenhams_line;

const long COORDINATE_LIMIT = 1000000;
const long STEP_LIMIT = 4096;

fn void write_i32_le(char* output, usz position, long value) {
    uint bits = (uint)(int)value;
    for (usz shift = 0; shift < 32; shift += 8) {
        output[position + shift / 8] = (char)((bits >> shift) & 255);
    }
}

fn long bresenhams_line(long* values, usz length, char* output, usz output_capacity)
    @export("bresenhams_line") {
    if (values == null || length != 4) return -1;
    for (usz index = 0; index < 4; index++) {
        if (values[index] < -COORDINATE_LIMIT || values[index] > COORDINATE_LIMIT) return -1;
    }

    long x0 = values[0];
    long y0 = values[1];
    long x1 = values[2];
    long y1 = values[3];
    long dx = x0 < x1 ? x1 - x0 : x0 - x1;
    long dy = y0 < y1 ? y1 - y0 : y0 - y1;
    long major_steps = dx > dy ? dx : dy;
    if (major_steps > STEP_LIMIT) return -1;
    usz required = (usz)(major_steps + 1) * 8;
    if (output == null || output_capacity < required) return -2;

    long sx = x0 < x1 ? 1 : -1;
    long sy = y0 < y1 ? 1 : -1;
    long x = x0;
    long y = y0;
    long err = dx - dy;
    usz position = 0;
    while (true) {
        write_i32_le(output, position, x);
        write_i32_le(output, position + 4, y);
        position += 8;
        if (x == x1 && y == y1) break;
        long e2 = 2 * err;
        if (e2 >= -dy) { err -= dy; x += sx; }
        if (e2 <= dx) { err += dx; y += sy; }
    }
    return (long)position;
}
