module zigzag_conversion;

const MAX_INPUT_LENGTH = 1025;
const MAX_ROWS = 1024;

fn bool is_ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long zigzag_conversion(long* values, usz length, char* output, usz output_capacity)
        @export("zigzag_conversion") {
    if (length == 0 || length > MAX_INPUT_LENGTH || values == null) return -1;
    rows := values[0];
    if (rows < 1 || rows > MAX_ROWS) return -1;
    row_count := (usz)rows;
    text_length := length - 1;
    for (usz index = 0; index < text_length; index++) {
        if (!is_ascii_letter(values[index + 1])) return -1;
    }
    if (output_capacity < text_length || (text_length != 0 && output == null)) return -2;
    if (text_length == 0) return 0;
    if (row_count == 1 || row_count >= text_length) {
        for (usz index = 0; index < text_length; index++) output[index] = (char)values[index + 1];
        return (long)text_length;
    }
    cycle := 2 * (row_count - 1);
    written := 0;
    for (usz row = 0; row < row_count; row++) {
        index := row;
        step := row == 0 || row + 1 == row_count ? cycle : cycle - 2 * row;
        while (index < text_length) {
            output[written++] = (char)values[index + 1];
            index += (usz)step;
            if (row > 0 && row + 1 < row_count) step = cycle - step;
        }
    }
    return (long)written;
}
