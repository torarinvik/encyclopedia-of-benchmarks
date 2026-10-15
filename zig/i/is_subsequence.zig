/// Check a Unicode scalar subsequence using a greedy forward scan.
const MAX_SEQUENCE_LENGTH: usize = 4096;
const MAX_PACKED_LENGTH: usize = 8194;

fn isUnicodeScalar(value: i64) bool {
    return value >= 0 and value <= 1_114_111 and !(value >= 55_296 and value <= 57_343);
}

export fn is_subsequence(raw_input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_PACKED_LENGTH) return -1;
    const input = raw_input[0..length];
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_SEQUENCE_LENGTH)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_SEQUENCE_LENGTH))) return -1;
    const main_length: usize = @intCast(input[0]);
    const subsequence_length: usize = @intCast(input[1]);
    if (length != 2 + main_length + subsequence_length) return -1;
    for (input[2..]) |value| {
        if (!isUnicodeScalar(value)) return -1;
    }

    const subsequence_start = 2 + main_length;
    var main_index: usize = 0;
    var subsequence_index: usize = 0;
    while (subsequence_index < subsequence_length and main_index < main_length) : (main_index += 1) {
        if (input[subsequence_start + subsequence_index] == input[2 + main_index]) subsequence_index += 1;
    }
    return if (subsequence_index == subsequence_length) 1 else 0;
}
