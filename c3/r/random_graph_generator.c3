module random_graph_generator;

const usz MAX_VERTICES = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 2020;
const usz MAX_OUTPUT_BYTES = 4096;
const long DRAW_SCALE = 9007199254740992L;
const long MIN_PROBABILITY_UNITS = -DRAW_SCALE;
const long MAX_PROBABILITY_UNITS = 18014398509481984L;

fn long random_graph_generator(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("random_graph_generator") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < 0 || input[0] > (long)MAX_VERTICES ||
        (input[1] != 0 && input[1] != 1) ||
        input[2] < MIN_PROBABILITY_UNITS || input[2] > MAX_PROBABILITY_UNITS) return -1L;

    usz vertex_count = (usz)input[0];
    long directed = input[1];
    long probability_units = input[2];
    usz pair_count = vertex_count < 2 ? 0 : vertex_count * (vertex_count - 1) / 2;
    usz draw_count = probability_units > 0 && probability_units < DRAW_SCALE ? pair_count : 0;
    if (input_length != 3 + draw_count) return -1L;
    for (usz index = 0; index < draw_count; index++)
        if (input[3 + index] < 0 || input[3 + index] >= DRAW_SCALE) return -1L;

    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    if (probability_units >= DRAW_SCALE) {
        for (usz source = 0; source < vertex_count; source++)
            for (usz target = 0; target < vertex_count; target++)
                if (source != target) staged[source * vertex_count + target] = 1;
    } else if (probability_units > 0) {
        usz draw_index = 0;
        for (usz source = 0; source < vertex_count; source++) {
            for (usz target = source + 1; target < vertex_count; target++) {
                if (input[3 + draw_index] < probability_units) {
                    staged[source * vertex_count + target] = 1;
                    if (directed == 0) staged[target * vertex_count + source] = 1;
                }
                draw_index++;
            }
        }
    }

    usz output_bytes = vertex_count * vertex_count;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < output_bytes; index++) output[index] = staged[index];
    return (long)output_bytes;
}
