export fn polygonal_numbers(packed: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const num = packed[0];
    const sides = packed[1];
    if (num < 0 or num > 100_000_000 or sides < 3 or sides > 64) return -1;
    const square = num * num;
    const leading = (sides - 2) * square;
    const trailing = (sides - 4) * num;
    return @divTrunc(leading - trailing, 2);
}
