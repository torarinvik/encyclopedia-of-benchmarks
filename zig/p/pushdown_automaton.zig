/// Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter.
pub export fn pushdown_automaton(values: [*]const i64, length: usize) i64 {
    const max_byte_length: i64 = 256;
    const max_input_length: usize = 257;
    if (length < 1 or length > max_input_length) return -1;
    const byte_length = values[0];
    if (byte_length < 0 or byte_length > max_byte_length) return -1;
    const count: usize = @intCast(byte_length);
    if (length != count + 1) return -1;

    for (0..count) |index| {
        if (values[index + 1] < 48 or values[index + 1] > 50) return -1;
    }
    if (count == 0 or count % 2 != 0) return 0;

    const half = count / 2;
    for (0..half) |index| {
        if (values[index + 1] != 49 and values[index + 1] != 50) return 0;
    }
    for (half..count) |index| {
        if (values[index + 1] != 48) return 0;
    }
    return 1;
}
