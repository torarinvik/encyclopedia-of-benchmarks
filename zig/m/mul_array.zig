export fn mul_array(values: ?[*]const i64, length: usize) i64 {
    if (length > 9) return -1;
    if (length == 0) return 1;
    if (values == null) return -1;

    const items = values.?;
    var product: i64 = 1;
    for (0..length) |index| {
        const value = items[index];
        if (value < 0 or value > 99) return -1;
        product *= value;
    }
    return product;
}
