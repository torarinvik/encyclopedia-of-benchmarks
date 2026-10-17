module sparsity;

const usz MAX_DIMENSION = 63;
const usz MAX_INPUT_VALUES = 2 + MAX_DIMENSION * MAX_DIMENSION;
const long MAX_ABS_CELL = 1000000L;
const double INVALID_RESULT = -1.0e300;

fn double sparsity(long* input, usz length) @export("sparsity") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return INVALID_RESULT;
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > (long)MAX_DIMENSION ||
        columns_value < 1 || columns_value > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz total = rows * columns;
    if (length != 2 + total) return INVALID_RESULT;

    usz zero_count = 0;
    for (usz index = 0; index < total; index++) {
        long value = input[2 + index];
        if (value < -MAX_ABS_CELL || value > MAX_ABS_CELL) return INVALID_RESULT;
        if (value == 0) zero_count++;
    }
    return (double)zero_count / (double)total;
}
