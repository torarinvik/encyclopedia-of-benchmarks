module transposition;

const usz MAX_KEY = 32;
const usz MAX_TEXT = 512;
const usz MAX_INPUT = 3 + MAX_KEY + MAX_TEXT;
const usz MAX_PADDED = MAX_TEXT + MAX_KEY;

fn bool ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long hash_output(ubyte* text, usz length) {
    ulong hash = 14695981039346656037;
    for (usz byte = 0; byte < 8; byte++) {
        hash = (hash ^ ((ulong)length >> (byte * 8) & 255)) * 1099511628211;
    }
    for (usz index = 0; index < length; index++) {
        uint codepoint = text[index];
        for (usz byte = 0; byte < 4; byte++) {
            hash = (hash ^ ((ulong)codepoint >> (byte * 8) & 255)) * 1099511628211;
        }
    }
    return (long)(hash & 0x7FFFFFFFFFFFFFFF);
}

fn long transposition(long* input, usz length) @export("transposition") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long mode = input[0], key_length_value = input[1];
    if ((mode != 0 && mode != 1) || key_length_value < 1 || key_length_value > (long)MAX_KEY) return -1;
    usz key_length = (usz)key_length_value;
    usz text_length_index = 2 + key_length;
    if (length <= text_length_index) return -1;
    long text_length_value = input[text_length_index];
    if (text_length_value < 1 || text_length_value > (long)MAX_TEXT) return -1;
    usz text_length = (usz)text_length_value;
    if (length != text_length_index + 1 + text_length) return -1;

    ubyte[MAX_KEY] key, sorted;
    for (usz index = 0; index < key_length; index++) {
        long value = input[2 + index];
        if (!ascii_letter(value)) return -1;
        ubyte ch = (ubyte)value;
        if (ch >= 'A' && ch <= 'Z') ch += 'a' - 'A';
        key[index] = ch;
        sorted[index] = ch;
    }
    for (usz index = 1; index < key_length; index++) {
        ubyte value = sorted[index];
        usz cursor = index;
        while (cursor > 0 && sorted[cursor - 1] > value) {
            sorted[cursor] = sorted[cursor - 1];
            cursor--;
        }
        sorted[cursor] = value;
    }
    usz[MAX_KEY] ranks;
    for (usz index = 0; index < key_length; index++) {
        usz first = 0, duplicate = 0;
        while (first < key_length && sorted[first] != key[index]) first++;
        for (usz prior = 0; prior < index; prior++) if (key[prior] == key[index]) duplicate++;
        ranks[index] = first + duplicate + 1;
    }

    ubyte[MAX_PADDED] text, result;
    for (usz index = 0; index < text_length; index++) {
        long value = input[text_length_index + 1 + index];
        if (value < 32 || value > 126) return -1;
        text[index] = (ubyte)value;
    }
    if (mode == 0 && text[text_length - 1] == ' ') return -1;
    usz padding = key_length - text_length % key_length;
    usz padded_length = text_length + padding;
    for (usz index = text_length; index < padded_length; index++) text[index] = ' ';

    usz result_length = 0;
    if (mode == 0) {
        for (usz start = 0; start < padded_length; start += key_length) {
            ubyte[MAX_KEY] block;
            for (usz offset = 0; offset < key_length; offset++) block[ranks[offset] - 1] = text[start + offset];
            for (usz offset = 0; offset < key_length; offset++) result[result_length++] = block[offset];
        }
    } else {
        for (usz start = 0; start < text_length; start += key_length) {
            for (usz offset = 0; offset < key_length; offset++) result[result_length++] = text[start + ranks[offset] - 1];
        }
        while (result_length > 0 && result[result_length - 1] == ' ') result_length--;
    }
    return hash_output(&result[0], result_length);
}
