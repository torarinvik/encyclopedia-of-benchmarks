module rail_fence;

fn usz rail_for_position(usz position, usz rails) {
    usz period = 2 * (rails - 1);
    usz phase = position % period;
    return phase < rails ? phase : period - phase;
}

fn long rail_fence(long* input, usz length, char* output, usz output_capacity) @export("rail_fence") {
    if (input == null || length < 3 || length > 260) return -1;
    if (input[0] < 0 || input[0] > 1 || input[1] < 2 || input[1] > 8) return -1;
    if (input[2] < 0 || input[2] > 256) return -1;
    usz mode = (usz)input[0];
    usz rails = (usz)input[1];
    usz n = (usz)input[2];
    if (length != n + 3) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 3] < 0 || input[i + 3] > 127) return -1;
    if (output == null || output_capacity < n) return -2;

    if (mode == 0) {
        usz out = 0;
        for (usz rail = 0; rail < rails; rail++) {
            for (usz position = 0; position < n; position++) {
                if (rail_for_position(position, rails) == rail) {
                    output[out++] = (char)input[position + 3];
                }
            }
        }
    } else {
        usz counts[8] = {0,0,0,0,0,0,0,0};
        usz starts[8] = {0,0,0,0,0,0,0,0};
        usz used[8] = {0,0,0,0,0,0,0,0};
        for (usz position = 0; position < n; position++) counts[rail_for_position(position, rails)]++;
        for (usz rail = 1; rail < rails; rail++) starts[rail] = starts[rail - 1] + counts[rail - 1];
        for (usz position = 0; position < n; position++) {
            usz rail = rail_for_position(position, rails);
            output[position] = (char)input[3 + starts[rail] + used[rail]];
            used[rail]++;
        }
    }
    return (long)n;
}
