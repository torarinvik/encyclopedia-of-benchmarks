module anagram_dictionary_search;

const long MAX_WORDS = 16;
const long MAX_WORD_LENGTH = 16;

fn bool is_anagram(long* input, usz query_length, usz word_offset, usz word_length) {
    if (query_length != word_length) return false;
    long[26] counts = {0};
    for (usz i = 0; i < query_length; i++) { counts[input[2 + i] - 97]++; counts[input[word_offset + i] - 97]--; }
    for (usz i = 0; i < 26; i++) if (counts[i] != 0) return false;
    return true;
}

fn bool put_byte(char* output, usz capacity, usz* length, char value) {
    if (*length >= capacity) return false;
    output[*length] = value; *length += 1; return true;
}

fn long anagram_dictionary_search(long* input, usz length, char* output, usz capacity) @export("anagram_dictionary_search") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > MAX_WORDS || input[1] < 0 || input[1] > MAX_WORD_LENGTH) return -1;
    usz word_count = (usz)input[0], query_length = (usz)input[1];
    if (2 + query_length > length) return -1;
    for (usz i = 0; i < query_length; i++) if (input[2 + i] < 97 || input[2 + i] > 122) return -1;
    if (output == null) return -2;
    usz offset = 2 + query_length, output_length = 0;
    for (usz item = 0; item < word_count; item++) {
        if (offset >= length || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH) return -1;
        usz word_length = (usz)input[offset]; offset += 1;
        if (offset + word_length > length) return -1;
        for (usz i = 0; i < word_length; i++) if (input[offset + i] < 97 || input[offset + i] > 122) return -1;
        if (is_anagram(input, query_length, offset, word_length)) {
            for (usz i = 0; i < word_length; i++) if (!put_byte(output, capacity, &output_length, (char)input[offset + i])) return -2;
            if (!put_byte(output, capacity, &output_length, '\n')) return -2;
        }
        offset += word_length;
    }
    if (offset != length) return -1;
    if (!put_byte(output, capacity, &output_length, 0)) return -2;
    return output_length.long();
}
