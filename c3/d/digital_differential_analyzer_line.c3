module digital_differential_analyzer_line;

fn long round_ties_to_even(double value) {
    long lower = (long)value;
    if ((double)lower > value) lower--;
    double fraction = value - (double)lower;
    if (fraction > 0.5 || (fraction == 0.5 && lower % 2 != 0)) lower++;
    return lower;
}

fn void write_i32_le(char* output, usz* position, long value) {
    uint bits = (uint)(int)value;
    for (usz shift = 0; shift < 32; shift += 8) output[(*position)++] = (char)((bits >> shift) & 255);
}

fn long digital_differential_analyzer_line(long* values, usz length, char* output,
                                           usz output_capacity) @export("digital_differential_analyzer_line")
{
    if (length != 4) return -1;
    for (usz index = 0; index < 4; index++)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    long dx = values[2] - values[0], dy = values[3] - values[1];
    long abs_dx = dx < 0 ? -dx : dx, abs_dy = dy < 0 ? -dy : dy;
    long steps = abs_dx > abs_dy ? abs_dx : abs_dy;
    if (steps == 0 || steps > 4096) return -1;
    usz output_bytes = steps.usz() * 8;
    if (output_capacity < output_bytes || output == null) return -2;
    double x_increment = (double)dx / (double)steps;
    double y_increment = (double)dy / (double)steps;
    double x = (double)values[0], y = (double)values[1];
    usz position = 0;
    for (long step = 0; step < steps; step++) {
        x += x_increment;
        y += y_increment;
        write_i32_le(output, &position, round_ties_to_even(x));
        write_i32_le(output, &position, round_ties_to_even(y));
    }
    return output_bytes.long();
}
