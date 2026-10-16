module matrix_copy;

const usz MAX_DIMENSION = 32;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long matrix_copy(long* values, usz length, char* output, usz output_capacity)
    @export("matrix_copy") {
    if (values == null || length < 2 || length > 2 + MAX_DIMENSION * MAX_DIMENSION) return -1;
    long rows_value = values[0];
    long columns_value = values[1];
    if (rows_value < 0 || rows_value > (long)MAX_DIMENSION ||
        columns_value < 0 || columns_value > (long)MAX_DIMENSION) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz element_count = rows * columns;
    if (length != 2 + element_count) return -1;
    for (usz index = 0; index < element_count; index++) {
        if (values[2 + index] < -2147483648 || values[2 + index] > 2147483647) return -1;
    }
    usz result_rows = rows == 0 || columns == 0 ? 0 : rows;
    usz result_columns = rows == 0 || columns == 0 ? 0 : columns;
    usz result_count = result_rows * result_columns;
    usz output_bytes = (2 + result_count) * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, (long)result_rows);
    store_i64_le(output, 8, (long)result_columns);
    for (usz index = 0; index < result_count; index++) {
        store_i64_le(output, 16 + index * 8, values[2 + index]);
    }
    return (long)output_bytes;
}
