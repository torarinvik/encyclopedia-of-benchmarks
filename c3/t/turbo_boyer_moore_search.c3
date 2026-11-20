module turbo_boyer_moore_search;

const usz TB_MAX_TEXT = 255;
const usz TB_MAX_PATTERN = 64;
const usz TB_MAX_FRAME = 322;
const usz TB_ALPHABET = 128;

fn void tb_store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void tb_good_suffix(long* pattern, usz length, usz* shifts) {
    usz[64] suffix = zeroed;
    suffix[length - 1] = length;
    isz g = (isz)length - 1;
    isz f = 0;
    for (isz index = (isz)length - 2; index >= 0; index--) {
        if (index > g && suffix[(usz)(index + (isz)length - 1 - f)] < (usz)(index - g)) {
            suffix[(usz)index] = suffix[(usz)(index + (isz)length - 1 - f)];
        } else {
            if (index < g) g = index;
            f = index;
            while (g >= 0 && pattern[(usz)g] == pattern[(usz)(g + (isz)length - 1 - f)]) g--;
            suffix[(usz)index] = (usz)(f - g);
        }
    }
    for (usz index = 0; index < length; index++) shifts[index] = length;
    usz border = 0;
    for (isz index = (isz)length - 1; index >= 0; index--) {
        if (suffix[(usz)index] == (usz)index + 1) {
            while (border < length - 1 - (usz)index) {
                if (shifts[border] == length) shifts[border] = length - 1 - (usz)index;
                border++;
            }
        }
    }
    for (usz index = 0; index + 1 < length; index++)
        shifts[length - 1 - suffix[index]] = length - 1 - index;
}

fn long turbo_boyer_moore_search(long* input, usz length, char* output, usz output_capacity)
        @export("turbo_boyer_moore_search") {
    if (input == null || length < 2 || length > TB_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > (long)TB_MAX_TEXT ||
        input[1] < 1 || input[1] > (long)TB_MAX_PATTERN) return -1;
    usz text_length = (usz)input[0];
    usz pattern_length = (usz)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++)
        if (input[2 + index] < 0 || input[2 + index] >= (long)TB_ALPHABET) return -1;

    long* text = input + 2;
    long* pattern = text + text_length;
    long[255] positions = zeroed;
    usz match_count = 0;
    if (pattern_length <= text_length) {
        usz[128] bad_character = zeroed;
        usz[64] good_suffix = zeroed;
        for (usz byte = 0; byte < TB_ALPHABET; byte++) bad_character[byte] = pattern_length;
        for (usz index = 0; index + 1 < pattern_length; index++)
            bad_character[(usz)pattern[index]] = pattern_length - index - 1;
        tb_good_suffix(pattern, pattern_length, &good_suffix[0]);

        usz alignment = 0, remembered = 0, shift = pattern_length;
        while (alignment <= text_length - pattern_length) {
            isz index = (isz)pattern_length - 1;
            while (index >= 0 && pattern[(usz)index] == text[alignment + (usz)index]) {
                index--;
                if (remembered != 0 && index == (isz)pattern_length - 1 - (isz)shift)
                    index -= (isz)remembered;
            }
            if (index < 0) {
                positions[match_count++] = (long)alignment;
                shift = good_suffix[0];
                remembered = pattern_length - shift;
            } else {
                usz matched_suffix = pattern_length - 1 - (usz)index;
                isz turbo_shift = (isz)remembered - (isz)matched_suffix;
                isz bad_shift = (isz)bad_character[(usz)text[alignment + (usz)index]]
                    - (isz)pattern_length + 1 + index;
                usz gs = good_suffix[(usz)index];
                isz chosen = turbo_shift;
                if (bad_shift > chosen) chosen = bad_shift;
                if ((isz)gs > chosen) chosen = (isz)gs;
                shift = (usz)chosen;
                if (shift == gs) {
                    remembered = pattern_length - shift < matched_suffix
                        ? pattern_length - shift : matched_suffix;
                } else {
                    if (turbo_shift < bad_shift && shift < remembered + 1) shift = remembered + 1;
                    remembered = 0;
                }
            }
            alignment += shift;
        }
    }
    usz output_bytes = match_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < match_count; index++) tb_store_i64_le(output, index * 8, positions[index]);
    return (long)output_bytes;
}
