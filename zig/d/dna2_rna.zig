export fn dna2_rna(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 1001 or values[0] != 0) return -1;
    const count = length - 1;
    for (1..length) |index| {
        if (values[index] < 'A' or values[index] > 'Z') return -1;
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| {
        const base = values[index + 1];
        output[index] = if (base == 'T') 'U' else @intCast(base);
    }
    return @intCast(count);
}
