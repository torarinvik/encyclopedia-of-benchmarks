/// Count ASCII vowels in a bounded string represented by byte values.
const MAX_LENGTH: usize = 4096;

export fn count_vowels(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return -2;
    if (length == 1 and values[0] == 48) return -2;
    var count: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 127 or value == 44) return -2;
        if (value == 97 or value == 101 or value == 105 or value == 111 or value == 117 or
            value == 65 or value == 69 or value == 73 or value == 79 or value == 85) count += 1;
    }
    return count;
}
