const MAX_PARSEABLE_INPUT_LENGTH: usize = 2020;
const MAX_OUTPUT_BYTES: usize = 4096;
const DRAW_SCALE: i64 = 1 << 53;
const MIN_PROBABILITY_UNITS: i64 = -(1 << 53);
const MAX_PROBABILITY_UNITS: i64 = 1 << 54;

export fn random_graph_generator(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > 64 or (input[1] != 0 and input[1] != 1) or
        input[2] < MIN_PROBABILITY_UNITS or input[2] > MAX_PROBABILITY_UNITS) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const directed = input[1];
    const probability_units = input[2];
    const pair_count: usize = if (vertex_count < 2) 0 else vertex_count * (vertex_count - 1) / 2;
    const draw_count: usize = if (probability_units > 0 and probability_units < DRAW_SCALE) pair_count else 0;
    if (input_length != 3 + draw_count) return -1;
    for (0..draw_count) |index| {
        const draw = input[3 + index];
        if (draw < 0 or draw >= DRAW_SCALE) return -1;
    }

    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    if (probability_units >= DRAW_SCALE) {
        for (0..vertex_count) |source| {
            for (0..vertex_count) |target| {
                if (source != target) staged[source * vertex_count + target] = 1;
            }
        }
    } else if (probability_units > 0) {
        var draw_index: usize = 0;
        for (0..vertex_count) |source| {
            var target = source + 1;
            while (target < vertex_count) : (target += 1) {
                if (input[3 + draw_index] < probability_units) {
                    staged[source * vertex_count + target] = 1;
                    if (directed == 0) staged[target * vertex_count + source] = 1;
                }
                draw_index += 1;
            }
        }
    }

    const output_bytes = vertex_count * vertex_count;
    if (output == null or capacity < output_bytes) return -2;
    if (output_bytes > 0) @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
