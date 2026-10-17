module affine_image_rotation;

const usz MAX_DIMENSION = 8;
const usz MAX_CELLS = 64;
const usz MAX_INPUT_LENGTH = 79;

struct AxisSolution { long first; long second; long translation; bool valid; }

fn bool solve_axis(long* x, long* y, long* target,
                   long* first_out, long* second_out, long* translation_out) {
    long determinant = x[0] * (y[1] - y[2]) + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1]);
    if (determinant == 0) return false;
    long first = target[0] * (y[1] - y[2]) + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1]);
    long second = x[0] * (target[1] - target[2]) + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1]);
    long translation = x[0] * (y[1] * target[2] - y[2] * target[1])
        + x[1] * (y[2] * target[0] - y[0] * target[2]) + x[2] * (y[0] * target[1] - y[1] * target[0]);
    if (first % determinant != 0 || second % determinant != 0 || translation % determinant != 0) return false;
    *first_out = first / determinant;
    *second_out = second / determinant;
    *translation_out = translation / determinant;
    return true;
}

fn long affine_image_rotation(int* input, usz length, char* output, usz capacity)
    @export("affine_image_rotation") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long rows_value = input[0], cols_value = input[1];
    if (rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8) return -1;
    usz rows = (usz)rows_value, cols = (usz)cols_value;
    usz cells = rows * cols;
    if (length != 14 + cells) return -1;
    uint8[MAX_CELLS] pixels = zeroed;
    for (usz i = 0; i < cells; i += 1) {
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
        pixels[i] = (uint8)input[2 + i];
    }
    usz point_offset = 2 + cells;
    long[3] source_x = zeroed, source_y = zeroed, destination_x = zeroed, destination_y = zeroed;
    for (usz i = 0; i < 3; i += 1) {
        source_x[i] = input[point_offset + 2 * i];
        source_y[i] = input[point_offset + 2 * i + 1];
        destination_x[i] = input[point_offset + 6 + 2 * i];
        destination_y[i] = input[point_offset + 7 + 2 * i];
        if (source_x[i] < -16 || source_x[i] > 16 || source_y[i] < -16 || source_y[i] > 16 ||
            destination_x[i] < -16 || destination_x[i] > 16 || destination_y[i] < -16 || destination_y[i] > 16) return -1;
    }
    long a, b, tx, c, d, ty;
    if (!solve_axis(&source_x[0], &source_y[0], &destination_x[0], &a, &b, &tx) ||
        !solve_axis(&source_x[0], &source_y[0], &destination_y[0], &c, &d, &ty)) return -1;
    if (a < -2 || a > 2 || b < -2 || b > 2 || c < -2 || c > 2 || d < -2 || d > 2 ||
        tx < -16 || tx > 16 || ty < -16 || ty > 16) return -1;
    long determinant = a * d - b * c;
    if (determinant != -1 && determinant != 1) return -1;
    for (usz i = 0; i < 3; i += 1)
        if (destination_x[i] != a * source_x[i] + b * source_y[i] + tx ||
            destination_y[i] != c * source_x[i] + d * source_y[i] + ty) return -1;
    if (output == null || capacity < cells) return -2;
    usz written = 0;
    for (long y = 0; y < (long)cols; y += 1) {
        for (long x = 0; x < (long)rows; x += 1) {
            long px = x - tx, py = y - ty;
            long source_column = (d * px - b * py) / determinant;
            long source_row = (-c * px + a * py) / determinant;
            if (source_column >= 0 && source_column < (long)cols && source_row >= 0 && source_row < (long)rows)
                output[written] = (char)pixels[(usz)source_row * cols + (usz)source_column];
            else output[written] = 0;
            written += 1;
        }
    }
    return (long)cells;
}
