module brownian_tree_diffusion_limited_aggregation;

const usz SIDE = 33;
const usz MAX_POINTS = 17;
const long MAX_ATTEMPTS = 16;
const long MAX_STEPS = 512;
const ulong GOLDEN = 0x9e3779b97f4a7c15;
const ulong MULTIPLIER = 0x2545f4914f6cdd1d;

fn ulong dla_next(ulong* state) {
    ulong value = *state;
    value ^= value >> 12;
    value ^= value << 25;
    value ^= value >> 27;
    *state = value;
    return value * MULTIPLIER;
}

fn bool dla_touches(char* occupied, long x, long y) {
    usz at = (usz)(y * 33 + x);
    return occupied[at - 1] != 0 || occupied[at - 33] != 0 ||
           occupied[at + 1] != 0 || occupied[at + 33] != 0;
}

fn void dla_store_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long brownian_tree_diffusion_limited_aggregation(
        long* input, usz length, char* output, usz capacity)
        @export("brownian_tree_diffusion_limited_aggregation") {
    if (input == null || length != 3) return -1;
    long attempts_value = input[0], seed_value = input[1], steps_value = input[2];
    if (attempts_value < 0 || attempts_value > MAX_ATTEMPTS || seed_value < 1 ||
        steps_value < 1 || steps_value > MAX_STEPS) return -1;

    char[SIDE * SIDE] occupied;
    long[MAX_POINTS] point_x;
    long[MAX_POINTS] point_y;
    for (usz i = 0; i < SIDE * SIDE; i++) occupied[i] = 0;
    for (usz i = 0; i < MAX_POINTS; i++) { point_x[i] = 0; point_y[i] = 0; }
    point_x[0] = 16; point_y[0] = 16;
    usz point_count = 1;
    occupied[16 * SIDE + 16] = 1;

    for (usz attempt = 0; attempt < (usz)attempts_value; attempt++) {
        ulong state = (ulong)seed_value ^ (GOLDEN * (ulong)(attempt + 1));
        if (state == 0) state = MULTIPLIER;
        ulong side_draw = dla_next(&state);
        ulong position_draw = dla_next(&state);
        ulong launch_side = side_draw % 4;
        long position = 1 + (long)(position_draw % 31);
        long x, y;
        if (launch_side == 0) { x = position; y = 1; }
        else if (launch_side == 1) { x = 31; y = position; }
        else if (launch_side == 2) { x = position; y = 31; }
        else { x = 1; y = position; }

        usz at = (usz)(y * 33 + x);
        if (occupied[at] != 0) continue;
        if (dla_touches(&occupied[0], x, y)) {
            occupied[at] = 1;
            point_x[point_count] = x; point_y[point_count] = y; point_count++;
            continue;
        }
        for (long step = 0; step < steps_value; step++) {
            ulong direction = dla_next(&state) % 4;
            if (direction == 0) x--;
            else if (direction == 1) y--;
            else if (direction == 2) x++;
            else y++;
            if (x == 0 || x == 32 || y == 0 || y == 32) break;
            at = (usz)(y * 33 + x);
            if (dla_touches(&occupied[0], x, y)) {
                occupied[at] = 1;
                point_x[point_count] = x; point_y[point_count] = y; point_count++;
                break;
            }
        }
    }

    usz required = (1 + 2 * point_count) * 8;
    if (output == null || capacity < required) return -2;
    dla_store_i64(output, 0, (long)point_count);
    for (usz point = 0; point < point_count; point++) {
        dla_store_i64(output, (1 + 2 * point) * 8, point_x[point]);
        dla_store_i64(output, (2 + 2 * point) * 8, point_y[point]);
    }
    return (long)required;
}
