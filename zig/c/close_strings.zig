export fn close_strings(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 514) return -1;
    const first_length_value = input[0];
    const second_length_value = input[1];
    if (first_length_value < 0 or first_length_value > 256
        or second_length_value < 0 or second_length_value > 256) return -1;
    const first_length: usize = @intCast(first_length_value);
    const second_length: usize = @intCast(second_length_value);
    if (length != 2 + first_length + second_length) return -1;
    var first: [26]i64 = @splat(0);
    var second: [26]i64 = @splat(0);
    for (0..first_length) |index| {
        const value = input[2 + index];
        if (value < 97 or value > 122) return -1;
        first[@intCast(value - 97)] += 1;
    }
    const second_start = 2 + first_length;
    for (0..second_length) |index| {
        const value = input[second_start + index];
        if (value < 97 or value > 122) return -1;
        second[@intCast(value - 97)] += 1;
    }
    if (first_length != second_length) return 0;
    var first_frequencies: [257]i64 = @splat(0);
    var second_frequencies: [257]i64 = @splat(0);
    for (0..26) |letter| {
        if ((first[letter] == 0) != (second[letter] == 0)) return 0;
        first_frequencies[@intCast(first[letter])] += 1;
        second_frequencies[@intCast(second[letter])] += 1;
    }
    for (0..257) |frequency| {
        if (first_frequencies[frequency] != second_frequencies[frequency]) return 0;
    }
    return 1;
}
