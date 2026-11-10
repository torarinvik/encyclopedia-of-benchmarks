export fn minimum_deletions_to_make_string_balanced(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    var a_state: i64 = 0;
    var b_state: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 1) return -1;
        b_state += @intFromBool(value == 0 and b_state < a_state);
        a_state += value;
    }
    return b_state;
}
