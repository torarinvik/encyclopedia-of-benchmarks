/// Can lowercase ASCII letters be rearranged into a palindrome?
export fn can_string_be_rearranged_as_palindrome(text: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 4096) return -1;
    var counts: [26]usize = @splat(0);
    var odd_count: usize = 0;
    for (0..length) |index| {
        const value = text[index];
        if (value < 97 or value > 122) return -1;
        const letter: usize = @intCast(value - 97);
        if (counts[letter] % 2 == 0) odd_count += 1 else odd_count -= 1;
        counts[letter] += 1;
    }
    return if (odd_count <= 1) 1 else 0;
}
