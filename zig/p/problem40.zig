fn digitAtPosition(position_input: i64) i64 {
    var position = position_input;
    var digits: i64 = 1;
    var block_count: i64 = 9;
    var first_number: i64 = 1;
    while (position > digits * block_count) {
        position -= digits * block_count;
        digits += 1;
        block_count *= 10;
        first_number *= 10;
    }
    const number = first_number + @divTrunc(position - 1, digits);
    const offset = @mod(position - 1, digits);
    var divisor: i64 = 1;
    var power: i64 = 0;
    while (power < digits - offset - 1) : (power += 1) divisor *= 10;
    return @mod(@divTrunc(number, divisor), 10);
}

pub export fn problem40(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var product = digitAtPosition(1);
    product *= digitAtPosition(10);
    product *= digitAtPosition(100);
    product *= digitAtPosition(1_000);
    product *= digitAtPosition(10_000);
    product *= digitAtPosition(100_000);
    product *= digitAtPosition(1_000_000);
    return product;
}
