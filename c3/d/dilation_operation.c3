module dilation_operation;

const long INVALID_RESULT = -9223372036854775807L - 1L;
const long MAX_DIMENSION = 16;
const usz MAX_INPUT_LENGTH = 2 + 16 * 16 + 9;

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long dilation_operation(long* input, usz length, char* output, usz output_capacity)
    @export("dilation_operation") {
    if (input == null || length < 12 || length > MAX_INPUT_LENGTH) return -1;
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz cells = rows * columns;
    if (length != 2 + cells + 9) return -1;
    for (usz i = 0; i < cells + 9; i++) if (input[2 + i] < 0 || input[2 + i] > 1) return -1;
    if (output == null || output_capacity < cells * 4) return -2;
    for (usz y = 0; y < rows; y++) {
        for (usz x = 0; x < columns; x++) {
            int sum = 0;
            for (usz ky = 0; ky < 3; ky++) {
                for (usz kx = 0; kx < 3; kx++) {
                    long image_y = (long)y + (long)ky - 1;
                    long image_x = (long)x + (long)kx - 1;
                    if (image_y >= 0 && image_y < (long)rows && image_x >= 0 && image_x < (long)columns)
                        sum += (int)(input[2 + (usz)image_y * columns + (usz)image_x] * input[2 + cells + ky * 3 + kx]);
                }
            }
            put_i32_le(output, (y * columns + x) * 4, sum > 0 ? 1 : 0);
        }
    }
    return (long)cells;
}
