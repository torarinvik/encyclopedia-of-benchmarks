module lempel_ziv_decompress;

const usz MAX_INPUT_BITS = 128;
const usz MAX_PARSEABLE_INPUT_LENGTH = 130;
const usz MAX_DICTIONARY_ENTRIES = 130;
const usz MAX_KEY_LENGTH = 16;
const usz MAX_VALUE_LENGTH = 129;
const usz MAX_OUTPUT_BYTES = 8256;

struct LexiconEntry {
    char[17] key;
    usz key_length;
    char[130] value;
    usz value_length;
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

fn bool set_value_with_suffix(LexiconEntry* entry, char* value,
                              usz value_length, char suffix) {
    if (value_length >= MAX_VALUE_LENGTH) return false;
    for (usz i = 0; i < value_length; ++i) entry.value[i] = value[i];
    entry.value[value_length] = suffix;
    entry.value[value_length + 1] = '\0';
    entry.value_length = value_length + 1;
    return true;
}

fn usz make_binary_key(usz value, char* key) {
    char[MAX_KEY_LENGTH] reversed;
    usz length = 0;
    do {
        if (length >= MAX_KEY_LENGTH) return 0;
        reversed[length++] = (char)('0' + (value & 1));
        value >>= 1;
    } while (value != 0);

    for (usz i = 0; i < length; ++i) key[i] = reversed[length - i - 1];
    key[length] = '\0';
    return length;
}

fn bool is_power_of_two(usz value) {
    return value != 0 && (value & (value - 1)) == 0;
}

fn bool decode_bits(long* input, usz bit_count, char* decoded,
                    usz* decoded_length) {
    LexiconEntry[MAX_DICTIONARY_ENTRIES] entries;
    usz entry_count = 2;
    entries[0].key[0] = '0';
    entries[0].key[1] = '\0';
    entries[0].key_length = 1;
    entries[0].value[0] = '0';
    entries[0].value[1] = '\0';
    entries[0].value_length = 1;
    entries[1].key[0] = '1';
    entries[1].key[1] = '\0';
    entries[1].key_length = 1;
    entries[1].value[0] = '1';
    entries[1].value[1] = '\0';
    entries[1].value_length = 1;

    char[MAX_INPUT_BITS + 1] current;
    usz current_length = 0;
    usz index = entry_count;
    usz output_length = 0;

    for (usz bit = 0; bit < bit_count; ++bit) {
        current[current_length++] = input[bit + 1] == 48 ? '0' : '1';
        current[current_length] = '\0';
        usz match = find_entry(&entries[0], entry_count, &current[0], current_length);
        if (match == entry_count) continue;

        char[MAX_VALUE_LENGTH + 1] last_match;
        usz last_match_length = entries[match].value_length;
        if (output_length + last_match_length > MAX_OUTPUT_BYTES) return false;
        for (usz i = 0; i < last_match_length; ++i) {
            last_match[i] = entries[match].value[i];
            decoded[output_length + i] = last_match[i];
        }
        last_match[last_match_length] = '\0';
        output_length += last_match_length;
        if (!set_value_with_suffix(&entries[match], &last_match[0],
                                   last_match_length, '0')) return false;

        if (is_power_of_two(index)) {
            for (usz entry = 0; entry < entry_count; ++entry) {
                if (entries[entry].key_length >= MAX_KEY_LENGTH) return false;
                for (usz i = entries[entry].key_length; i > 0; --i)
                    entries[entry].key[i] = entries[entry].key[i - 1];
                entries[entry].key[0] = '0';
                ++entries[entry].key_length;
                entries[entry].key[entries[entry].key_length] = '\0';
            }
        }

        char[MAX_KEY_LENGTH + 1] index_key;
        usz index_key_length = make_binary_key(index, &index_key[0]);
        if (index_key_length == 0) return false;
        usz existing = find_entry(&entries[0], entry_count,
                                  &index_key[0], index_key_length);
        if (existing == entry_count) {
            if (entry_count >= MAX_DICTIONARY_ENTRIES) return false;
            entries[entry_count].key_length = index_key_length;
            for (usz i = 0; i <= index_key_length; ++i)
                entries[entry_count].key[i] = index_key[i];
            if (!set_value_with_suffix(&entries[entry_count], &last_match[0],
                                       last_match_length, '1')) return false;
            ++entry_count;
        } else if (!set_value_with_suffix(&entries[existing], &last_match[0],
                                          last_match_length, '1')) {
            return false;
        }

        ++index;
        current_length = 0;
    }

    *decoded_length = output_length;
    return true;
}

fn long lempel_ziv_decompress(long* input, usz input_length,
                              char* output, usz output_capacity)
    @export("lempel_ziv_decompress") {
    if (input == null || input_length < 1 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INPUT_BITS) return -1;
    usz bit_count = (usz)input[0];
    if (input_length != 1 + bit_count) return -1;
    for (usz i = 0; i < bit_count; ++i) {
        if (input[i + 1] != 48 && input[i + 1] != 49) return -1;
    }

    char[MAX_OUTPUT_BYTES] decoded;
    usz decoded_length = 0;
    if (!decode_bits(input, bit_count, &decoded[0], &decoded_length)) return -1;
    if (output == null || output_capacity < decoded_length) return -2;
    for (usz i = 0; i < decoded_length; ++i) output[i] = decoded[i];
    return (long)decoded_length;
}
