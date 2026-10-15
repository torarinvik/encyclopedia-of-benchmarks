/// Reverse a DNA sequence and complement each base.
const max_reverse_complement_length = 1000;

export fn reverse_complement(input: [*]const i64, length: usize,
                             output: [*]u8, output_capacity: usize) i64 {
    if (length > max_reverse_complement_length) return -1;
    for (0..length) |index| {
        const base = input[index];
        if (base != 'A' and base != 'C' and base != 'G' and base != 'T') return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        const base = input[length - 1 - index];
        const complement = if (base == 'A') 'T' else if (base == 'T') 'A' else if (base == 'C') 'G' else 'C';
        output[index] = complement;
    }
    return @intCast(length);
}
