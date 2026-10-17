module mixed_keyword_cypher;

const usz MAX_KEYWORD_LENGTH = 64;
const usz MAX_PLAINTEXT_LENGTH = 512;
const usz MAX_INPUT_LENGTH = 578;

long mixed_keyword_cypher(long* input, usz length, char* output, usz capacity)
        @export("mixed_keyword_cypher") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    long raw_keyword_length = input[0];
    if (raw_keyword_length < 1 || raw_keyword_length > 64) return -1;
    usz keyword_length = (usz)raw_keyword_length;
    usz plaintext_length_index = 1 + keyword_length;
    if (plaintext_length_index >= length) return -1;

    long raw_plaintext_length = input[plaintext_length_index];
    if (raw_plaintext_length < 0 || raw_plaintext_length > 512) return -1;
    usz plaintext_length = (usz)raw_plaintext_length;
    if (length != plaintext_length_index + 1 + plaintext_length) return -1;

    char unique_letters[26];
    bool seen[26];
    for (usz index = 0; index < 26; index += 1) seen[index] = false;
    usz unique_count = 0;
    for (usz index = 0; index < keyword_length; index += 1) {
        long raw = input[1 + index];
        if (raw < 0 || raw > 127) return -1;
        long letter = raw;
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' && letter <= 'Z') {
            usz alphabet_index = (usz)(letter - 'A');
            if (!seen[alphabet_index]) {
                seen[alphabet_index] = true;
                unique_letters[unique_count] = (char)letter;
                unique_count += 1;
            }
        }
    }
    if (unique_count == 0) return -1;

    for (usz index = 0; index < plaintext_length; index += 1) {
        long raw = input[plaintext_length_index + 1 + index];
        if (raw < 0 || raw > 127) return -1;
    }

    char shifted[26];
    for (usz index = 0; index < unique_count; index += 1)
        shifted[index] = unique_letters[index];
    usz shifted_count = unique_count;
    for (usz index = 0; index < 26; index += 1) {
        if (!seen[index]) {
            shifted[shifted_count] = (char)('A' + index);
            shifted_count += 1;
        }
    }

    char mapping[26];
    usz alphabet_index = 0;
    for (usz column = 0; column < unique_count; column += 1) {
        for (usz row_start = 0; row_start < 26; row_start += unique_count) {
            usz shifted_index = row_start + column;
            if (shifted_index >= 26) break;
            mapping[alphabet_index] = shifted[shifted_index];
            alphabet_index += 1;
        }
    }

    char buffer[512];
    for (usz index = 0; index < plaintext_length; index += 1) {
        long letter = input[plaintext_length_index + 1 + index];
        if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' && letter <= 'Z')
            buffer[index] = mapping[(usz)(letter - 'A')];
        else
            buffer[index] = (char)letter;
    }

    if (output == null || capacity < plaintext_length) return -2;
    for (usz index = 0; index < plaintext_length; index += 1) output[index] = buffer[index];
    return (long)plaintext_length;
}
