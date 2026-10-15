fn getCheckDigit(input: i64) i64 {
    var barcode = @divTrunc(input, 10);
    var checker = false;
    var total: i64 = 0;
    while (barcode != 0) {
        const multiplier: i64 = if (checker) 1 else 3;
        total += multiplier * @mod(barcode, 10);
        barcode = @divTrunc(barcode, 10);
        checker = !checker;
    }
    return @mod(10 - @mod(total, 10), 10);
}

fn decimalLength(input: i64) usize {
    var value = input;
    var length: usize = 1;
    while (value >= 10) {
        value = @divTrunc(value, 10);
        length += 1;
    }
    return length;
}

export fn barcode_validator(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const operation = values[0];
    const barcode = values[1];
    if (operation < 0 or operation > 1 or barcode < 0) return -1;
    if (operation == 0) return getCheckDigit(barcode);
    return if (decimalLength(barcode) == 13 and getCheckDigit(barcode) == @mod(barcode, 10)) 1 else 0;
}
