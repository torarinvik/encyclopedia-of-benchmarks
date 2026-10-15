export fn minimum_deletions_to_make_string_balanced(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    var a_state: i64 = 0;
    var b_state: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 1) return -1;
        const next_a = a_state + @as(i64, if (value == 1) 1 else 0);
        const b_with_a = b_state + @as(i64, if (value == 0) 1 else 0);
        const next_b = @min(a_state, b_with_a);
        a_state = next_a;
        b_state = next_b;
    }
    return @min(a_state, b_state);
}
