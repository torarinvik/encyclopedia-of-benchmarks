module generate_rule_30_grid;

const usz MAX_WIDTH = 64;
const usz MAX_GENERATIONS = 64;

fn long generate_rule_30_grid(long* input, usz length, char* output, usz output_capacity)
        @export("generate_rule_30_grid") {
    if (input == null || length != 2) return -1;
    long width_value = input[0], generations_value = input[1];
    if (width_value < 1 || width_value > (long)MAX_WIDTH ||
        generations_value < 1 || generations_value > (long)MAX_GENERATIONS) return -1;
    usz width = (usz)width_value, generations = (usz)generations_value;
    usz output_count = width * generations;
    if (output_capacity < output_count || output == null) return -2;

    long[64] current = {0};
    long[64] next = {0};
    current[width / 2] = 1;
    for (usz column = 0; column < width; column++) output[column] = (char)current[column];
    for (usz generation = 1; generation < generations; generation++) {
        for (usz column = 0; column < width; column++) {
            long left = column > 0 ? current[column - 1] : 0;
            long right = column + 1 < width ? current[column + 1] : 0;
            uint pattern = (uint)(left * 4 + current[column] * 2 + right);
            next[column] = (30u >> pattern) & 1u;
        }
        for (usz column = 0; column < width; column++) {
            current[column] = next[column];
            output[generation * width + column] = (char)next[column];
        }
    }
    return (long)output_count;
}
