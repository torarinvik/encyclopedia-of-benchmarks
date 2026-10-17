#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT_BITS 128
#define MAX_DICTIONARY_ENTRIES (MAX_INPUT_BITS + 2)
#define MAX_KEY_LENGTH 16
#define MAX_VALUE_LENGTH (MAX_INPUT_BITS + 1)
#define MAX_OUTPUT_BYTES (MAX_INPUT_BITS * (MAX_INPUT_BITS + 1) / 2)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_BITS + 2)

typedef struct {
    char key[MAX_KEY_LENGTH + 1];
    size_t key_length;
    char value[MAX_VALUE_LENGTH + 1];
    size_t value_length;
} LexiconEntry;

static size_t find_entry(const LexiconEntry *entries, size_t entry_count,
                         const char *key, size_t key_length)
{
    for (size_t i = 0; i < entry_count; ++i) {
        if (entries[i].key_length != key_length) continue;
        if (memcmp(entries[i].key, key, key_length) == 0) return i;
    }
    return entry_count;
}

static int set_value_with_suffix(LexiconEntry *entry, const char *value,
                                 size_t value_length, char suffix)
{
    if (value_length > MAX_VALUE_LENGTH - 1) return 0;
    memcpy(entry->value, value, value_length);
    entry->value[value_length] = suffix;
    entry->value[value_length + 1] = '\0';
    entry->value_length = value_length + 1;
    return 1;
}

static size_t make_binary_key(size_t value, char *key)
{
    char reversed[MAX_KEY_LENGTH];
    size_t length = 0;
    do {
        if (length >= MAX_KEY_LENGTH) return 0;
        reversed[length++] = (char)('0' + (value & 1u));
        value >>= 1u;
    } while (value != 0);

    for (size_t i = 0; i < length; ++i)
        key[i] = reversed[length - i - 1];
    key[length] = '\0';
    return length;
}

static int is_power_of_two(size_t value)
{
    return value != 0 && (value & (value - 1)) == 0;
}

static int decode_bits(const int64_t *input, size_t bit_count,
                       uint8_t *decoded, size_t *decoded_length)
{
    LexiconEntry entries[MAX_DICTIONARY_ENTRIES];
    size_t entry_count = 2;
    memset(entries, 0, sizeof(entries));
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

    char current[MAX_INPUT_BITS + 1];
    size_t current_length = 0;
    size_t index = entry_count;
    size_t output_length = 0;

    for (size_t bit = 0; bit < bit_count; ++bit) {
        current[current_length++] = input[bit + 1] == 48 ? '0' : '1';
        current[current_length] = '\0';
        const size_t match = find_entry(entries, entry_count, current, current_length);
        if (match == entry_count) continue;

        char last_match[MAX_VALUE_LENGTH + 1];
        const size_t last_match_length = entries[match].value_length;
        if (output_length + last_match_length > MAX_OUTPUT_BYTES) return 0;
        memcpy(last_match, entries[match].value, last_match_length);
        last_match[last_match_length] = '\0';
        memcpy(decoded + output_length, last_match, last_match_length);
        output_length += last_match_length;

        if (!set_value_with_suffix(&entries[match], last_match,
                                   last_match_length, '0')) return 0;

        if (is_power_of_two(index)) {
            for (size_t entry = 0; entry < entry_count; ++entry) {
                if (entries[entry].key_length >= MAX_KEY_LENGTH) return 0;
                memmove(entries[entry].key + 1, entries[entry].key,
                        entries[entry].key_length);
                entries[entry].key[0] = '0';
                ++entries[entry].key_length;
                entries[entry].key[entries[entry].key_length] = '\0';
            }
        }

        char index_key[MAX_KEY_LENGTH + 1];
        const size_t index_key_length = make_binary_key(index, index_key);
        if (index_key_length == 0) return 0;
        const size_t existing = find_entry(entries, entry_count,
                                            index_key, index_key_length);
        if (existing == entry_count) {
            if (entry_count >= MAX_DICTIONARY_ENTRIES) return 0;
            entries[entry_count].key_length = index_key_length;
            memcpy(entries[entry_count].key, index_key, index_key_length + 1);
            if (!set_value_with_suffix(&entries[entry_count], last_match,
                                       last_match_length, '1')) return 0;
            ++entry_count;
        } else if (!set_value_with_suffix(&entries[existing], last_match,
                                          last_match_length, '1')) {
            return 0;
        }

        ++index;
        current_length = 0;
    }

    *decoded_length = output_length;
    return 1;
}

int64_t lempel_ziv_decompress(const int64_t *input, size_t input_length,
                              uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_INPUT_BITS) return -1;
    const size_t bit_count = (size_t)input[0];
    if (input_length != 1 + bit_count) return -1;
    for (size_t i = 0; i < bit_count; ++i) {
        if (input[i + 1] != 48 && input[i + 1] != 49) return -1;
    }

    uint8_t decoded[MAX_OUTPUT_BYTES];
    size_t decoded_length = 0;
    if (!decode_bits(input, bit_count, decoded, &decoded_length)) return -1;
    if (output == NULL || output_capacity < decoded_length) return -2;
    if (decoded_length > 0) memcpy(output, decoded, decoded_length);
    return (int64_t)decoded_length;
}
