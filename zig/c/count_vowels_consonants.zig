/// Count ASCII vowels and consonants, packing both counts into one i64.
const COUNT_BASE: i64 = 4_294_967_296;

export fn count_vowels_consonants(values: [*c]const i64, length: usize) i64 {
    if (length > 100_000 or (length != 0 and values == null)) return -1;
    var vowels: i64 = 0;
    var consonants: i64 = 0;
    for (0..length) |index| {
        const code = values[index];
        if (code < 0 or code > 127) return -1;
        if ((code >= 65 and code <= 90) or (code >= 97 and code <= 122)) {
            const letter = code | 32;
            if (letter == 97 or letter == 101 or letter == 105 or letter == 111 or letter == 117) {
                vowels += 1;
            } else {
                consonants += 1;
            }
        }
    }
    return vowels * COUNT_BASE + consonants;
}
