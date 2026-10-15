export fn kolakoski_sequence(index: i64) i64 {
    if (index < 0 or index > 63) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;

    var encoded: u64 = 6;
    var read_bit: u64 = 4;
    var write_bit: u64 = 8;
    const target: u64 = @intCast(index);
    var current_index: u64 = 3;
    var next_element: i64 = 1;

    while (current_index <= target) {
        const run_length: u64 = 1 + @divTrunc(encoded, read_bit) % 2;
        var emitted: u64 = 0;
        while (emitted < run_length) : (emitted += 1) {
            if (next_element == 2) encoded += write_bit;
            if (current_index == target) return next_element;
            current_index += 1;
            write_bit *= 2;
        }
        read_bit *= 2;
        next_element = 3 - next_element;
    }
    return -1;
}
