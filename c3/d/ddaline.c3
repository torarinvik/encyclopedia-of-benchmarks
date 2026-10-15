module ddaline;

fn long java_round(double value) {
    double shifted = value + 0.5;
    long rounded = (long)shifted;
    if ((double)rounded > shifted) rounded--;
    return rounded;
}
fn void write_i64(char* output, usz* position, long value) {
    for (usz shift = 0; shift < 64; shift += 8) {
        output[(*position)++] = (char)((value >> shift) & 255);
    }
}
fn long ddaline(long* input, usz length, char* output, usz capacity) @export("ddaline") {
    if (input == null || length != 4) return -1;
    for (usz i = 0; i < 4; i++) if (input[i] < -128 || input[i] > 128) return -1;
    long dx = input[2] - input[0], dy = input[3] - input[1];
    long ax = dx < 0 ? -dx : dx, ay = dy < 0 ? -dy : dy;
    long steps = ax > ay ? ax : ay;
    if (steps > 256) return -1;
    usz output_bytes = (steps.usz() + 1) * 16;
    if (output == null || capacity < output_bytes) return -2;
    usz position = 0;
    if (steps == 0) { write_i64(output, &position, input[0]); write_i64(output, &position, input[1]); return 16; }
    double x_inc = (double)dx / (double)steps, y_inc = (double)dy / (double)steps;
    double x = (double)input[0], y = (double)input[1];
    for (long i = 0; i <= steps; i++) {
        write_i64(output, &position, java_round(x));
        write_i64(output, &position, java_round(y));
        x += x_inc;
        y += y_inc;
    }
    return output_bytes.long();
}
