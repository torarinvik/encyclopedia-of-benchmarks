module transposition_cipher;

const int MAX_TEXT = 256;
const int MAX_INPUT = 259;

fn long transposition_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("transposition_cipher") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    long mode = input[0], key64 = input[1], n64 = input[2];
    if ((mode != 0 && mode != 1) || n64 < 3 || n64 > MAX_TEXT || key64 < 2 || key64 >= n64) return -1;
    usz n = (usz)n64, key = (usz)key64;
    if (length != 3 + n) return -1;
    for (usz i = 0; i < n; i++) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    if (output == null || output_capacity < n) return -2;
    char[MAX_TEXT] transformed;
    if (mode == 0) {
        usz written = 0;
        for (usz column = 0; column < key; column++)
            for (usz index = column; index < n; index += key)
                transformed[written++] = (char)input[3 + index];
    } else {
        usz columns = (n + key - 1) / key;
        usz shaded = columns * key - n;
        usz final_column_rows = key - shaded;
        usz[MAX_TEXT] offsets;
        usz[MAX_TEXT] seen;
        usz total = 0;
        for (usz column = 0; column < columns; column++) {
            offsets[column] = total;
            total += column + 1 == columns ? final_column_rows : key;
        }
        usz row = 0, column = 0;
        for (usz i = 0; i < n; i++) {
            transformed[offsets[column] + seen[column]++] = (char)input[3 + i];
            column++;
            if (column == columns || (column == columns - 1 && row >= final_column_rows)) {
                column = 0;
                row++;
            }
        }
    }
    for (usz i = 0; i < n; i++) output[i] = transformed[i];
    return (long)n;
}
