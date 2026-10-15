module convert_number_to_words;
const char[258] WORD_BYTES = {122, 101, 114, 111, 111, 110, 101, 116, 119, 111, 116, 104, 114, 101, 101, 102, 111, 117, 114, 102, 105, 118, 101, 115, 105, 120, 115, 101, 118, 101, 110, 101, 105, 103, 104, 116, 110, 105, 110, 101, 116, 101, 110, 101, 108, 101, 118, 101, 110, 116, 119, 101, 108, 118, 101, 116, 104, 105, 114, 116, 101, 101, 110, 102, 111, 117, 114, 116, 101, 101, 110, 102, 105, 102, 116, 101, 101, 110, 115, 105, 120, 116, 101, 101, 110, 115, 101, 118, 101, 110, 116, 101, 101, 110, 101, 105, 103, 104, 116, 101, 101, 110, 110, 105, 110, 101, 116, 101, 101, 110, 116, 119, 101, 110, 116, 121, 116, 104, 105, 114, 116, 121, 102, 111, 114, 116, 121, 102, 105, 102, 116, 121, 115, 105, 120, 116, 121, 115, 101, 118, 101, 110, 116, 121, 101, 105, 103, 104, 116, 121, 110, 105, 110, 101, 116, 121, 113, 117, 97, 100, 114, 105, 108, 108, 105, 111, 110, 116, 114, 105, 108, 108, 105, 111, 110, 98, 105, 108, 108, 105, 111, 110, 109, 105, 108, 108, 105, 111, 110, 116, 104, 111, 117, 115, 97, 110, 100, 104, 117, 110, 100, 114, 101, 100, 98, 105, 108, 108, 105, 97, 114, 100, 109, 105, 108, 108, 105, 97, 114, 100, 99, 114, 111, 114, 101, 32, 99, 114, 111, 114, 101, 108, 97, 107, 104, 32, 99, 114, 111, 114, 101, 99, 114, 111, 114, 101, 108, 97, 107, 104, 110, 101, 103, 97, 116, 105, 118, 101};
const usz[41] WORD_OFFSETS = {0, 4, 7, 10, 15, 19, 23, 26, 31, 36, 40, 43, 49, 55, 63, 71, 78, 85, 94, 102, 110, 116, 122, 127, 132, 137, 144, 150, 156, 167, 175, 182, 189, 197, 204, 212, 220, 231, 241, 246, 250};
const usz[41] WORD_LENGTHS = {4, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8, 6, 6, 5, 5, 5, 7, 6, 6, 11, 8, 7, 7, 8, 7, 8, 8, 11, 10, 5, 4, 8};
fn usz append_word(char* output, usz length, usz id, bool separate) {
    if (separate && length > 0) output[length++] = ' ';
    for (usz i = 0; i < WORD_LENGTHS[id]; i++) output[length + i] = WORD_BYTES[WORD_OFFSETS[id] + i];
    return length + WORD_LENGTHS[id];
}
fn usz append_small(ulong n, char* output, usz length) {
    if (n < 10) return append_word(output, length, (usz)n, true);
    if (n < 20) return append_word(output, length, (usz)n + 10, true);
    length = append_word(output, length, (usz)(n / 10) + 18, true);
    if (n % 10 != 0) { output[length++] = '-'; length = append_word(output, length, (usz)(n % 10), false); }
    return length;
}
fn usz scale_count(int system) { return system == 1 ? 5 : 6; }
fn ulong scale_power(int system, usz index) {
    if (system == 0) { ulong values[6] = {1000000000000000,1000000000000,1000000000,1000000,1000,100}; return values[index]; }
    if (system == 1) { ulong values[5] = {1000000000000000,1000000000,1000000,1000,100}; return values[index]; }
    ulong values[6] = {100000000000000,1000000000000,10000000,100000,1000,100}; return values[index];
}
fn usz scale_word(int system, usz index) {
    if (system == 0) { usz ids[6] = {28,29,30,31,32,33}; return ids[index]; }
    if (system == 1) { usz ids[5] = {34,35,31,32,33}; return ids[index]; }
    usz ids[6] = {36,37,38,39,32,33}; return ids[index];
}
fn usz append_number(ulong n, int system, char* output, usz length, int depth) {
    if (depth > 8) return length;
    usz initial_length = length;
    for (usz i = 0; i < scale_count(system); i++) {
        ulong power = scale_power(system, i), group = n / power;
        n %= power;
        if (group == 0) continue;
        if (group >= 100) length = append_number(group, system, output, length, depth + 1);
        else length = append_small(group, output, length);
        length = append_word(output, length, scale_word(system, i), true);
    }
    if (n > 0 || length == initial_length) length = append_small(n, output, length);
    return length;
}
fn long convert_number_to_words(long* input, usz length, char* output, usz capacity) @export("convert_number_to_words") {
    if (input == null || length != 2 || input[1] < 0 || input[1] > 2) return -1;
    int system = (int)input[1]; long number = input[0];
    long limit = system == 0 ? 999999999999999999 : 9000000000000000000;
    if (number < -limit || number > limit) return -1;
    ulong magnitude = (ulong)(number < 0 ? -number : number);
    char words[512] = {}; usz count = 0;
    if (number < 0) count = append_word(words, count, 40, true);
    count = append_number(magnitude, system, words, count, 0);
    if (capacity < count || output == null) return -2;
    for (usz i = 0; i < count; i++) output[i] = words[i];
    return (long)count;
}
