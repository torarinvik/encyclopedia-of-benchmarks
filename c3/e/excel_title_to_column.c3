module excel_title_to_column;

fn long excel_title_to_column(long* values, usz length) @export("excel_title_to_column") {
    if (values == null || length < 2 || length > 13) { return -1; }
    long count = values[0];
    if (count < 1 || count > 12 || length != (usz)(1 + count)) { return -1; }

    long column = 0;
    for (long index = 0; index < count; index++) {
        long letter = values[1 + index];
        if (letter >= 97 && letter <= 122) { letter -= 32; }
        if (letter < 65 || letter > 90) { return -1; }
        column = column * 26 + (letter - 65 + 1);
    }
    return column;
}
