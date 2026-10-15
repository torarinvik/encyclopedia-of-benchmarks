module barcode_validator;

fn long get_check_digit(long barcode) {
    barcode /= 10;
    bool checker = false;
    long sum = 0;
    while (barcode != 0) {
        long multiplier = checker ? 1 : 3;
        sum += multiplier * (barcode % 10);
        barcode /= 10;
        checker = !checker;
    }
    return (10 - sum % 10) % 10;
}

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn long barcode_validator(long* values, usz length) @export("barcode_validator") {
    if (values == null || length != 2 || values[0] < 0 || values[0] > 1 || values[1] < 0) return -1;
    long barcode = values[1];
    if (values[0] == 0) return get_check_digit(barcode);
    if (decimal_length(barcode) == 13 && get_check_digit(barcode) == barcode % 10) return 1;
    return 0;
}
