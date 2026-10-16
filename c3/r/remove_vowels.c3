module remove_vowels;
const usz MAX_INPUT_LENGTH = 4096;
fn bool vowel(usz c) { return c == 97 || c == 101 || c == 105 || c == 111 || c == 117; }
fn usz lower(usz c) { return c >= 65 && c <= 90 ? c + 32 : c; }
fn long remove_vowels(long* values, usz length, char* output, usz capacity) @export("remove_vowels") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > (long)MAX_INPUT_LENGTH || length != 1 + (usz)values[0]) return -1;
    usz n = (usz)values[0], result = 0;
    for (usz i = 0; i < n; i++) { if (values[i+1] < 0 || values[i+1] > 127) return -1; if (!vowel(lower((usz)values[i+1]))) result++; }
    if (result > capacity || (result > 0 && output == null)) return -2;
    usz j = 0;
    for (usz i = 0; i < n; i++) { usz c = lower((usz)values[i+1]); if (!vowel(c)) output[j++] = (char)c; }
    return (long)j;
}
