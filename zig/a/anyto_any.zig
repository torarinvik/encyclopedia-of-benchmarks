const MAX_ENCODED_VALUE: i64 = 999_999_999;

export fn anyto_any(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?[0..length];
    var encoded = values[0];
    const source_base = values[1];
    const destination_base = values[2];
    if (encoded < 0 or encoded > MAX_ENCODED_VALUE or source_base < 2 or source_base > 10 or
        destination_base < 2 or destination_base > 10) return -1;

    var decimal_value: i64 = 0;
    var source_multiplier: i64 = 1;
    while (encoded > 0) {
        const digit = @mod(encoded, 10);
        if (digit >= source_base) return -1;
        decimal_value += digit * source_multiplier;
        source_multiplier *= source_base;
        encoded = @divTrunc(encoded, 10);
    }

    var result: i64 = 0;
    var destination_multiplier: i64 = 1;
    while (decimal_value > 0) {
        const digit = @mod(decimal_value, destination_base);
        result += digit * destination_multiplier;
        decimal_value = @divTrunc(decimal_value, destination_base);
        if (decimal_value > 0) {
            if (destination_multiplier > @divTrunc(MAX_ENCODED_VALUE, 10)) return -1;
            destination_multiplier *= 10;
        }
    }
    return result;
}
