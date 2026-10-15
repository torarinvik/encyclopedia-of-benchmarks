module count_vowels_consonants;

const usz MAX_TEXT_LENGTH = 100000;
const long COUNT_BASE = 4294967296;

fn long count_vowels_consonants(long* values, usz length) @export("count_vowels_consonants") {
    if (length > MAX_TEXT_LENGTH || (length != 0 && values == null)) return -1;
    long vowels = 0, consonants = 0;
    for (usz index = 0; index < length; index++) {
        long code = values[index];
        if (code < 0 || code > 127) return -1;
        if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
            long letter = code | 32;
            if (letter == 97 || letter == 101 || letter == 105 || letter == 111 || letter == 117)
                vowels++;
            else consonants++;
        }
    }
    return vowels * COUNT_BASE + consonants;
}
