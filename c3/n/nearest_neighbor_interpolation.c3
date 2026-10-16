module nearest_neighbor_interpolation;

const long MAX_DIMENSION = 16;
const usz MAX_INPUT_LENGTH = 2 + 16 * 16;

fn long nearest_neighbor_interpolation(long* input, usz length, char* output, usz output_capacity)
    @export("nearest_neighbor_interpolation") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz input_cells = rows * columns;
    if (length != 2 + input_cells) return -1;
    for (usz index = 0; index < input_cells; index++) {
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;
    }
    usz output_rows = 3 * rows / 2;
    usz output_columns = 3 * columns / 2;
    usz output_bytes = output_rows * output_columns;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz y = 0; y < output_rows; y++) {
        usz source_y = (4 * (y + 1) + 3) / 6 - 1;
        for (usz x = 0; x < output_columns; x++) {
            usz source_x = (4 * (x + 1) + 3) / 6 - 1;
            output[y * output_columns + x] = (char)input[2 + source_y * columns + source_x];
        }
    }
    return (long)output_bytes;
}
