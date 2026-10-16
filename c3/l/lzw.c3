module lzw;

const usz MAX_ITEMS = 4096;
const usz MAX_CODES = 4352;
const usz MAX_OUTPUT = 65536;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_i64(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint shift = 0; shift < 64; shift += 8) {
        hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    }
    return hash;
}

fn long hash_record(long mode, usz count, long* values) {
    ulong hash = hash_i64(FNV_OFFSET, mode);
    hash = hash_i64(hash, (long)count);
    for (usz i = 0; i < count; i++) hash = hash_i64(hash, values[i]);
    return (long)(hash & 0x7fffffffffffffff);
}

fn bool expand_code(int code, int dictionary_size, int32* prefix, uint8* suffix,
                    uint8* phrase, usz capacity, usz* phrase_length) {
    usz length = 0;
    int current = code;
    while (current >= 256) {
        if (current >= dictionary_size || length >= capacity) return false;
        phrase[length++] = suffix[current];
        current = prefix[current];
        if (current < 0) return false;
    }
    if (current < 0 || current > 255 || length >= capacity) return false;
    phrase[length++] = (uint8)current;
    usz left = 0;
    usz right = length - 1;
    while (left < right) {
        uint8 byte = phrase[left];
        phrase[left] = phrase[right];
        phrase[right] = byte;
        left++;
        right--;
    }
    *phrase_length = length;
    return true;
}

fn long lzw(long* input, usz length) @export("lzw") {
    if (input == null || length < 2 || length > MAX_ITEMS + 2) return -1;
    long mode = input[0];
    long count64 = input[1];
    if ((mode != 0 && mode != 1) || count64 < 0 || count64 > (long)MAX_ITEMS || length != (usz)count64 + 2) return -1;
    usz count = (usz)count64;

    int32[MAX_CODES] prefix;
    int32[MAX_CODES] next_sibling;
    int32[MAX_CODES] first_child;
    uint8[MAX_CODES] suffix;
    uint8[MAX_CODES] first_symbol;
    for (usz i = 0; i < MAX_CODES; i++) {
        prefix[i] = -1;
        next_sibling[i] = -1;
        first_child[i] = -1;
        suffix[i] = 0;
        first_symbol[i] = 0;
    }
    for (int code = 0; code < 256; code++) {
        suffix[code] = (uint8)code;
        first_symbol[code] = (uint8)code;
    }

    if (mode == 0) {
        for (usz i = 0; i < count; i++) if (input[2 + i] < 0 || input[2 + i] > 127) return -1;
        long[MAX_ITEMS] codes;
        usz code_count = 0;
        if (count > 0) {
            int dictionary_size = 256;
            int current = (int)input[2];
            for (usz i = 1; i < count; i++) {
                int byte = (int)input[2 + i];
                int match = first_child[current];
                while (match >= 0 && suffix[match] != (uint8)byte) match = next_sibling[match];
                if (match >= 0) current = match;
                else {
                    codes[code_count++] = current;
                    if (dictionary_size >= (int)MAX_CODES) return -1;
                    prefix[dictionary_size] = current;
                    suffix[dictionary_size] = (uint8)byte;
                    first_symbol[dictionary_size] = first_symbol[current];
                    next_sibling[dictionary_size] = first_child[current];
                    first_child[current] = dictionary_size;
                    dictionary_size++;
                    current = byte;
                }
            }
            codes[code_count++] = current;
        }
        return hash_record(0, code_count, &codes[0]);
    }

    for (usz i = 0; i < count; i++) if (input[2 + i] < 0 || input[2 + i] >= (long)MAX_CODES) return -1;
    if (count == 0) return hash_record(1, 0, null);
    int first_code = (int)input[2];
    if (first_code > 127) return -1;
    uint8[MAX_OUTPUT] decoded;
    uint8[MAX_CODES] phrase;
    usz decoded_length = 1;
    decoded[0] = (uint8)first_code;
    int dictionary_size = 256;
    int previous = first_code;
    for (usz i = 1; i < count; i++) {
        int code = (int)input[2 + i];
        usz phrase_length = 0;
        if (code < dictionary_size) {
            if (!expand_code(code, dictionary_size, &prefix[0], &suffix[0], &phrase[0], MAX_CODES, &phrase_length)) return -1;
        } else if (code == dictionary_size) {
            if (!expand_code(previous, dictionary_size, &prefix[0], &suffix[0], &phrase[0], MAX_CODES, &phrase_length) || phrase_length >= MAX_CODES) return -1;
            phrase[phrase_length++] = first_symbol[previous];
        } else return -1;
        if (decoded_length > MAX_OUTPUT - phrase_length) return -1;
        for (usz j = 0; j < phrase_length; j++) if (phrase[j] > 127) return -1;
        for (usz j = 0; j < phrase_length; j++) decoded[decoded_length++] = phrase[j];
        if (dictionary_size >= (int)MAX_CODES) return -1;
        uint8 next_byte = (uint8)(code == dictionary_size ? first_symbol[previous] : first_symbol[code]);
        prefix[dictionary_size] = previous;
        suffix[dictionary_size] = next_byte;
        first_symbol[dictionary_size] = first_symbol[previous];
        dictionary_size++;
        previous = code;
    }
    ulong hash = hash_i64(FNV_OFFSET, 1);
    hash = hash_i64(hash, (long)decoded_length);
    for (usz i = 0; i < decoded_length; i++) hash = hash_i64(hash, decoded[i]);
    return (long)(hash & 0x7fffffffffffffff);
}
