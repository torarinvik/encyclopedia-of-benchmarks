module lempel_ziv;

const usz MAX_INPUT_BITS = 128;
const usz MAX_DICTIONARY_ENTRIES = 130;
const usz MAX_KEY_LENGTH = 129;
const usz MAX_CODE_WIDTH = 8;
const usz MAX_OUTPUT_BYTES = 1032;
const usz MAX_PARSEABLE_INPUT_LENGTH = 130;

struct LexiconEntry {
    char[130] key;
    usz key_length;
    char[9] code;
    usz code_length;
}

fn void copy_entry(LexiconEntry* destination, LexiconEntry* source) {
    for (usz i = 0; i < MAX_KEY_LENGTH + 1; ++i)
        destination.key[i] = source.key[i];
    destination.key_length = source.key_length;
    for (usz i = 0; i < MAX_CODE_WIDTH + 1; ++i)
        destination.code[i] = source.code[i];
    destination.code_length = source.code_length;
}

fn usz find_entry(LexiconEntry* entries, usz entry_count,
                  char* key, usz key_length) {
    for (usz entry = 0; entry < entry_count; ++entry) {
        if (entries[entry].key_length != key_length) continue;
        bool same = true;
        for (usz i = 0; i < key_length; ++i) {
            if (entries[entry].key[i] != key[i]) {
                same = false;
                break;
            }
        }
        if (same) return entry;
    }
    return entry_count;
}

fn bool set_code(LexiconEntry* entry, char* code, usz code_length) {
    if (code_length > MAX_CODE_WIDTH) return false;
    for (usz i = 0; i < code_length; ++i) entry.code[i] = code[i];
    entry.code[code_length] = '\0';
    entry.code_length = code_length;
    return true;
}

fn bool insert_or_update(LexiconEntry* entries, usz* entry_count,
                         char* key, usz key_length,
                         char* code, usz code_length) {
    usz existing = find_entry(entries, *entry_count, key, key_length);
    if (existing != *entry_count)
        return set_code(&entries[existing], code, code_length);
    if (*entry_count >= MAX_DICTIONARY_ENTRIES || key_length > MAX_KEY_LENGTH)
        return false;
    usz entry = *entry_count;
    for (usz i = 0; i < key_length; ++i) entries[entry].key[i] = key[i];
    entries[entry].key[key_length] = '\0';
    entries[entry].key_length = key_length;
    if (!set_code(&entries[entry], code, code_length)) return false;
    *entry_count += 1;
    return true;
}

fn bool append_code(char* output, usz* output_length, LexiconEntry* entry) {
    if (*output_length + entry.code_length > MAX_OUTPUT_BYTES) return false;
    for (usz i = 0; i < entry.code_length; ++i)
        output[(*output_length)++] = entry.code[i];
    return true;
}

fn usz make_binary_code(usz value, char* code) {
    char[MAX_CODE_WIDTH] reversed;
    usz length = 0;
    do {
        if (length >= MAX_CODE_WIDTH) return 0;
        reversed[length++] = (char)('0' + (value & 1));
        value >>= 1;
    } while (value != 0);

    for (usz i = 0; i < length; ++i) code[i] = reversed[length - i - 1];
    code[length] = '\0';
    return length;
}

fn bool is_power_of_two(usz value) {
    return value != 0 && (value & (value - 1)) == 0;
}

fn bool compress_bits(long* input, usz bit_count, char* compressed,
                      usz* compressed_length) {
    LexiconEntry[MAX_DICTIONARY_ENTRIES] entries = {};
    usz entry_count = 2;
    entries[0].key[0] = '0';
    entries[0].key[1] = '\0';
    entries[0].key_length = 1;
    entries[0].code[0] = '0';
    entries[0].code[1] = '\0';
    entries[0].code_length = 1;
    entries[1].key[0] = '1';
    entries[1].key[1] = '\0';
    entries[1].key_length = 1;
    entries[1].code[0] = '1';
    entries[1].code[1] = '\0';
    entries[1].code_length = 1;

    char[MAX_KEY_LENGTH + 1] current;
    usz current_length = 0;
    usz index = entry_count;
    usz output_length = 0;

    for (usz bit = 0; bit < bit_count; ++bit) {
        current[current_length++] = input[bit + 1] == 48 ? '0' : '1';
        current[current_length] = '\0';
        usz match = find_entry(&entries[0], entry_count, &current[0], current_length);
        if (match == entry_count) continue;

        char[MAX_CODE_WIDTH + 1] matched_code;
        usz matched_code_length = entries[match].code_length;
        if (output_length + matched_code_length > MAX_OUTPUT_BYTES) return false;
        for (usz i = 0; i < matched_code_length; ++i) {
            matched_code[i] = entries[match].code[i];
            compressed[output_length + i] = matched_code[i];
        }
        matched_code[matched_code_length] = '\0';
        output_length += matched_code_length;

        for (usz entry = match; entry + 1 < entry_count; ++entry)
            copy_entry(&entries[entry], &entries[entry + 1]);
        entry_count -= 1;

        char[MAX_KEY_LENGTH + 1] child_zero;
        if (current_length + 1 > MAX_KEY_LENGTH) return false;
        for (usz i = 0; i < current_length; ++i) child_zero[i] = current[i];
        child_zero[current_length] = '0';
        child_zero[current_length + 1] = '\0';
        if (!insert_or_update(&entries[0], &entry_count, &child_zero[0],
                              current_length + 1, &matched_code[0],
                              matched_code_length)) return false;

        if (is_power_of_two(index)) {
            for (usz entry = 0; entry < entry_count; ++entry) {
                if (entries[entry].code_length >= MAX_CODE_WIDTH) return false;
                for (usz i = entries[entry].code_length; i > 0; --i)
                    entries[entry].code[i] = entries[entry].code[i - 1];
                entries[entry].code[0] = '0';
                entries[entry].code_length += 1;
                entries[entry].code[entries[entry].code_length] = '\0';
            }
        }

        char[MAX_KEY_LENGTH + 1] child_one;
        for (usz i = 0; i < current_length; ++i) child_one[i] = current[i];
        child_one[current_length] = '1';
        child_one[current_length + 1] = '\0';
        char[MAX_CODE_WIDTH + 1] index_code;
        usz index_code_length = make_binary_code(index, &index_code[0]);
        if (index_code_length == 0 ||
            !insert_or_update(&entries[0], &entry_count, &child_one[0],
                              current_length + 1, &index_code[0],
                              index_code_length)) return false;

        ++index;
        current_length = 0;
    }

    if (current_length > 0) {
        usz max_key_length = 0;
        for (usz entry = 0; entry < entry_count; ++entry) {
            if (entries[entry].key_length > max_key_length)
                max_key_length = entries[entry].key_length;
        }
        for (;;) {
            usz match = find_entry(&entries[0], entry_count,
                                  &current[0], current_length);
            if (match != entry_count) {
                if (!append_code(compressed, &output_length, &entries[match])) return false;
                break;
            }
            if (current_length >= max_key_length ||
                current_length >= MAX_KEY_LENGTH) return false;
            current[current_length++] = '0';
            current[current_length] = '\0';
        }
    }

    *compressed_length = output_length;
    return true;
}

fn long lempel_ziv(long* input, usz input_length,
                   char* output, usz output_capacity)
    @export("lempel_ziv") {
    if (input == null || input_length < 1 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INPUT_BITS) return -1;
    usz bit_count = (usz)input[0];
    if (input_length != 1 + bit_count) return -1;
    for (usz bit = 0; bit < bit_count; ++bit) {
        if (input[bit + 1] != 48 && input[bit + 1] != 49) return -1;
    }

    char[MAX_OUTPUT_BYTES] compressed;
    usz compressed_length = 0;
    if (!compress_bits(input, bit_count, &compressed[0], &compressed_length)) return -1;
    if (output == null || output_capacity < compressed_length) return -2;
    for (usz i = 0; i < compressed_length; ++i) output[i] = compressed[i];
    return (long)compressed_length;
}
