module submatrix;

fn ulong feed(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        hash = (hash ^ ((bits >> (byte * 8)) & 255)) * 0x100000001B3;
    }
    return hash;
}

long submatrix(long* values, usz length) @export("submatrix") {
    if (values == null || length < 6 || length > 70) return -1;
    long rows = values[0], cols = values[1], row_start = values[2], col_start = values[3];
    long out_rows = values[4], out_cols = values[5];
    if (rows < 1 || rows > 8 || cols < 1 || cols > 8 || rows * cols > 64 || length != 6 + (usz)(rows * cols)) return -1;
    if (row_start < 0 || row_start > rows || col_start < 0 || col_start > cols ||
        out_rows < 0 || out_rows > rows || out_cols < 0 || out_cols > cols ||
        row_start + out_rows > rows || col_start + out_cols > cols) return -1;
    for (usz i = 6; i < length; i++) if (values[i] < -2147483648 || values[i] > 2147483647) return -1;
    ulong hash = feed(0xCBF29CE484222325, out_rows);
    hash = feed(hash, out_cols);
    for (long r = 0; r < out_rows; r++) {
        for (long c = 0; c < out_cols; c++) {
            usz index = 6 + (usz)(row_start + r) * (usz)cols + (usz)(col_start + c);
            hash = feed(hash, values[index]);
        }
    }
    return (long)hash;
}
