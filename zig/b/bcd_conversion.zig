const INVALID_RESULT: i64 = -1;

export fn bcd_conversion(decimal: i64) i64 {
    if (decimal < 0 or decimal > 9999) return INVALID_RESULT;
    var value = decimal;
    var bcd: i64 = 0;
    var shift: u6 = 0;
    while (value > 0) : (shift += 4) {
        const digit = @mod(value, 10);
        bcd |= digit << shift;
        value = @divTrunc(value, 10);
    }
    return bcd;
}
