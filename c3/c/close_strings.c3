module close_strings;

fn long close_strings(long* input, usz length) @export("close_strings") {
    if (length < 2 || length > 514 || input == null) return -1;
    long first_length_value = input[0];
    long second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 256 ||
        second_length_value < 0 || second_length_value > 256 ||
        length != (usz)(2 + first_length_value + second_length_value)) return -1;
    usz first_length = (usz)first_length_value;
    usz second_length = (usz)second_length_value;
    long[26] first;
    long[26] second;
    for (usz letter = 0; letter < 26; letter++) { first[letter] = 0; second[letter] = 0; }
    for (usz index = 0; index < first_length; index++) {
        long value = input[2 + index];
        if (value < 97 || value > 122) return -1;
        first[(usz)(value - 97)]++;
    }
    usz second_start = 2 + first_length;
    for (usz index = 0; index < second_length; index++) {
        long value = input[second_start + index];
        if (value < 97 || value > 122) return -1;
        second[(usz)(value - 97)]++;
    }
    if (first_length != second_length) return 0;
    long[257] first_frequency_counts;
    long[257] second_frequency_counts;
    for (usz frequency = 0; frequency <= 256; frequency++) {
        first_frequency_counts[frequency] = 0;
        second_frequency_counts[frequency] = 0;
    }
    for (usz letter = 0; letter < 26; letter++) {
        if ((first[letter] == 0) != (second[letter] == 0)) return 0;
        first_frequency_counts[(usz)first[letter]]++;
        second_frequency_counts[(usz)second[letter]]++;
    }
    for (usz frequency = 0; frequency <= 256; frequency++) {
        if (first_frequency_counts[frequency] != second_frequency_counts[frequency]) return 0;
    }
    return 1;
}
