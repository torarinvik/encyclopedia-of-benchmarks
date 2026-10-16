module turkish_to_latin_conversion;

const usz MAX_TEXT_BYTES = 1024;

fn bool continuation(uint value) { return value >= 0x80 && value <= 0xBF; }

fn bool decode_utf8(uint* payload, usz length, usz index, uint* codepoint, usz* width) {
    uint first = payload[index];
    if (first <= 0x7F) { *codepoint = first; *width = 1; return true; }
    if (first >= 0xC2 && first <= 0xDF) {
        if (index + 1 >= length || !continuation(payload[index + 1])) return false;
        *codepoint = ((first & 0x1F) << 6) | (payload[index + 1] & 0x3F);
        *width = 2;
        return true;
    }
    if (first >= 0xE0 && first <= 0xEF) {
        if (index + 2 >= length) return false;
        uint second = payload[index + 1];
        uint third = payload[index + 2];
        if (!continuation(second) || !continuation(third) ||
            (first == 0xE0 && second < 0xA0) || (first == 0xED && second >= 0xA0)) return false;
        *codepoint = ((first & 0x0F) << 12) | ((second & 0x3F) << 6) | (third & 0x3F);
        *width = 3;
        return true;
    }
    if (first >= 0xF0 && first <= 0xF4) {
        if (index + 3 >= length) return false;
        uint second = payload[index + 1];
        uint third = payload[index + 2];
        uint fourth = payload[index + 3];
        if (!continuation(second) || !continuation(third) || !continuation(fourth) ||
            (first == 0xF0 && second < 0x90) || (first == 0xF4 && second > 0x8F)) return false;
        *codepoint = ((first & 0x07) << 18) | ((second & 0x3F) << 12) |
                     ((third & 0x3F) << 6) | (fourth & 0x3F);
        *width = 4;
        return true;
    }
    return false;
}

fn uint map_turkish(uint codepoint) {
    switch (codepoint) {
        case 0x0131: return 'i'; case 0x0130: return 'I';
        case 0x00FC: return 'u'; case 0x00DC: return 'U';
        case 0x00F6: return 'o'; case 0x00D6: return 'O';
        case 0x015F: return 's'; case 0x015E: return 'S';
        case 0x00E7: return 'c'; case 0x00C7: return 'C';
        case 0x011F: return 'g'; case 0x011E: return 'G';
        default: return 0;
    }
}

fn long turkish_to_latin_conversion(long* input, usz length, char* output, usz output_capacity)
    @export("turkish_to_latin_conversion") {
    if (input == null || length < 1 || length > MAX_TEXT_BYTES + 1 ||
        input[0] < 0 || input[0] > (long)MAX_TEXT_BYTES || length != (usz)input[0] + 1) return -1;
    usz text_length = (usz)input[0];
    uint[MAX_TEXT_BYTES] payload;
    for (usz index = 0; index < text_length; index++) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
        payload[index] = (uint)input[index + 1];
    }
    usz result_length = 0;
    for (usz index = 0; index < text_length;) {
        uint codepoint;
        usz width;
        if (!decode_utf8(&payload[0], text_length, index, &codepoint, &width)) return -1;
        result_length += map_turkish(codepoint) != 0 ? 1 : width;
        index += width;
    }
    if (result_length > output_capacity || (result_length > 0 && output == null)) return -2;
    usz written = 0;
    for (usz index = 0; index < text_length;) {
        uint codepoint;
        usz width;
        decode_utf8(&payload[0], text_length, index, &codepoint, &width);
        uint mapped = map_turkish(codepoint);
        if (mapped != 0) { output[written++] = (char)mapped; }
        else { for (usz octet_index = 0; octet_index < width; octet_index++) output[written++] = (char)payload[index + octet_index]; }
        index += width;
    }
    return (long)result_length;
}
