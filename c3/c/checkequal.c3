module checkequal;

const usz MAX_DIMENSION = 32;
const usz MAX_INPUT_LENGTH = 2053;

fn long checkequal(long* values, usz length) @export("checkequal") {
    if (values == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;

    long rows_a = values[0];
    long columns_a = values[1];
    long rows_b = values[2];
    long columns_b = values[3];
    if (rows_a < 0 || rows_a > (long)MAX_DIMENSION || columns_a < 0 || columns_a > (long)MAX_DIMENSION ||
        rows_b < 0 || rows_b > (long)MAX_DIMENSION || columns_b < 0 || columns_b > (long)MAX_DIMENSION) return -1;

    usz count_a = (usz)rows_a * (usz)columns_a;
    usz count_b = (usz)rows_b * (usz)columns_b;
    if (length != 4 + count_a + count_b) return -1;
    if (rows_a != rows_b || columns_a != columns_b) return 0;
    for (usz index = 0; index < count_a; index++) {
        if (values[4 + index] != values[4 + count_a + index]) return 0;
    }
    return 1;
}
