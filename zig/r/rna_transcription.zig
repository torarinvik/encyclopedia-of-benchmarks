const MAX_INPUT_VALUES: usize = 1001;

export fn rna_transcription(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_INPUT_VALUES or values[0] != 0) return -1;
    const count = length - 1;
    for (1..length) |index| {
        const base = values[index];
        if (base != 'A' and base != 'C' and base != 'G' and base != 'T') return -1;
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| {
        output[index] = switch (values[index + 1]) {
            'A' => 'U',
            'C' => 'G',
            'G' => 'C',
            else => 'A',
        };
    }
    return @intCast(count);
}
