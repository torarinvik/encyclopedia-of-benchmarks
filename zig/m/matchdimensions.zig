export fn matchdimensions(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 4) return -1;
    for (0..4) |index| {
        if (values[index] < 0 or values[index] > 65535) return -1;
    }
    return if (values[0] == values[2] and values[1] == values[3]) 1 else 0;
}
