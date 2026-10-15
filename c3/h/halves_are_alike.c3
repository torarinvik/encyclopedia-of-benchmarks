module halves_are_alike;

fn bool halves_is_vowel(long value) {
    return value == 97 || value == 101 || value == 105 || value == 111 || value == 117 ||
        value == 65 || value == 69 || value == 73 || value == 79 || value == 85;
}

fn long halves_are_alike(long* letters, usz length) @export("halves_are_alike") {
    if (length > 256 || length % 2 != 0 || (length != 0 && letters == null)) return -1;
    usz half = length / 2;
    long first = 0;
    long second = 0;
    for (usz index = 0; index < length; index++) {
        long value = letters[index];
        if (!((value >= 97 && value <= 122) || (value >= 65 && value <= 90))) return -1;
        if (halves_is_vowel(value)) {
            if (index < half) { first++; }
            else { second++; }
        }
    }
    return first == second ? 1 : 0;
}
