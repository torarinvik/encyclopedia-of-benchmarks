module raita_search;

const usz RAITA_MAX_TEXT = 255;
const usz RAITA_MAX_PATTERN = 64;
const usz RAITA_MAX_FRAME = 322;
const usz RAITA_ALPHABET = 128;

fn void raita_store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long raita_search(long* input, usz length, char* output, usz output_capacity)
        @export("raita_search") {
    if (input == null || length < 2 || length > RAITA_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > (long)RAITA_MAX_TEXT ||
        input[1] < 1 || input[1] > (long)RAITA_MAX_PATTERN) return -1;
    usz text_length = (usz)input[0];
    usz pattern_length = (usz)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++)
        if (input[2 + index] < 0 || input[2 + index] >= (long)RAITA_ALPHABET) return -1;

    long* text = input + 2;
    long* pattern = text + text_length;
    long[255] positions = zeroed;
    usz match_count = 0;
    if (pattern_length <= text_length) {
        usz[128] shifts = zeroed;
        for (usz byte = 0; byte < RAITA_ALPHABET; byte++) shifts[byte] = pattern_length;
        for (usz index = 0; index + 1 < pattern_length; index++)
            shifts[(usz)pattern[index]] = pattern_length - index - 1;
        usz middle = pattern_length / 2;
        usz alignment = 0;
        while (alignment <= text_length - pattern_length) {
            usz last = (usz)text[alignment + pattern_length - 1];
            bool matches = pattern[pattern_length - 1] == (long)last;
            if (matches) matches = pattern[0] == text[alignment];
            if (matches) matches = pattern[middle] == text[alignment + middle];
            if (matches) {
                for (usz index = 1; index + 1 < pattern_length; index++) {
                    if (pattern[index] != text[alignment + index]) { matches = false; break; }
                }
                if (matches) positions[match_count++] = (long)alignment;
            }
            alignment += shifts[last];
        }
    }
    usz output_bytes = match_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < match_count; index++)
        raita_store_i64_le(output, index * 8, positions[index]);
    return (long)output_bytes;
}
