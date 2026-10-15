export fn halves_are_alike(letters: [*]const i64, length: usize) i64 {
    if (length > 256 or length % 2 != 0) return -1;
    const half = length / 2;
    var first: i64 = 0;
    var second: i64 = 0;
    for (0..length) |index| {
        const value = letters[index];
        if (!((value >= 65 and value <= 90) or (value >= 97 and value <= 122))) return -1;
        const is_vowel = value == 65 or value == 69 or value == 73 or value == 79 or value == 85
            or value == 97 or value == 101 or value == 105 or value == 111 or value == 117;
        if (is_vowel) {
            if (index < half) first += 1 else second += 1;
        }
    }
    return if (first == second) 1 else 0;
}
