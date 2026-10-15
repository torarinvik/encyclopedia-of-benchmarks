const max_value: i64 = 9_000_000_000_000_000_000;

/// Overflow-safe floor arithmetic mean using the bitwise identity.
export fn arithmeticmean(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const left = values[0];
    const right = values[1];
    if (left < 0 or left > max_value or right < 0 or right > max_value) return -1;
    return ((left ^ right) >> 1) + (left & right);
}
