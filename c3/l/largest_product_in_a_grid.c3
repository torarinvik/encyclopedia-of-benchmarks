module largest_product_in_a_grid;

const usz MAX_INPUT_LENGTH = 3971;
const long MAX_DIMENSION = 63;
const long MAX_CELL_VALUE = 1000;

fn long largest_product_in_a_grid(long* values, usz length) @export("largest_product_in_a_grid") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long rows = values[0];
    long cols = values[1];
    if (rows < 0 || rows > MAX_DIMENSION || cols < 0 || cols > MAX_DIMENSION) return -1;

    usz expected_length = 2 + (usz)rows * (usz)cols;
    if (length != expected_length) return -1;
    for (usz index = 2; index < length; index++) {
        if (values[index] < 0 || values[index] > MAX_CELL_VALUE) return -1;
    }

    long best = 0;
    for (usz row = 0; row < (usz)rows; row++) {
        for (usz col = 0; col < (usz)cols; col++) {
            for (usz direction = 0; direction < 4; direction++) {
                long row_step = 0;
                long col_step = 1;
                if (direction == 1) {
                    row_step = 1;
                    col_step = 0;
                } else if (direction == 2) {
                    row_step = 1;
                    col_step = 1;
                } else if (direction == 3) {
                    row_step = 1;
                    col_step = -1;
                }

                long product = 1;
                for (long offset = 0; offset < 4; offset++) {
                    long next_row = (long)row + offset * row_step;
                    long next_col = (long)col + offset * col_step;
                    if (next_row < 0 || next_row >= rows || next_col < 0 || next_col >= cols) {
                        product = 0;
                        break;
                    }
                    usz index = 2 + (usz)next_row * (usz)cols + (usz)next_col;
                    product *= values[index];
                }
                if (product > best) best = product;
            }
        }
    }
    return best;
}
