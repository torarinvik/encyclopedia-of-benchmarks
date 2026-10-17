#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT_BITS 128
#define MAX_DICTIONARY_ENTRIES (MAX_INPUT_BITS + 2)
#define MAX_KEY_LENGTH (MAX_INPUT_BITS + 1)
#define MAX_CODE_WIDTH 8
#define MAX_OUTPUT_BYTES 1032
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_BITS + 2)

typedef struct {
    char key[MAX_KEY_LENGTH + 1];
    size_t key_length;
    char code[MAX_CODE_WIDTH + 1];
    size_t code_length;
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

static int set_code(LexiconEntry *entry, const char *code, size_t code_length)
{
    if (code_length > MAX_CODE_WIDTH) return 0;
    memcpy(entry->code, code, code_length);
    entry->code[code_length] = '\0';
    entry->code_length = code_length;
    return 1;
}

static int insert_or_update(LexiconEntry *entries, size_t *entry_count,
                            const char *key, size_t key_length,
                            const char *code, size_t code_length)
{
    const size_t existing = find_entry(entries, *entry_count, key, key_length);
    if (existing != *entry_count)
        return set_code(&entries[existing], code, code_length);
    if (*entry_count >= MAX_DICTIONARY_ENTRIES || key_length > MAX_KEY_LENGTH)
        return 0;
    LexiconEntry *entry = &entries[*entry_count];
    memcpy(entry->key, key, key_length);
    entry->key[key_length] = '\0';
    entry->key_length = key_length;
    if (!set_code(entry, code, code_length)) return 0;
    ++*entry_count;
    return 1;
}

static int append_code(uint8_t *output, size_t *output_length,
                       const LexiconEntry *entry)
{
    if (*output_length + entry->code_length > MAX_OUTPUT_BYTES) return 0;
    for (size_t i = 0; i < entry->code_length; ++i)
        output[(*output_length)++] = (uint8_t)entry->code[i];
    return 1;
}

static size_t make_binary_code(size_t value, char *code)
{
    char reversed[MAX_CODE_WIDTH];
    size_t length = 0;
    do {
        if (length >= MAX_CODE_WIDTH) return 0;
        reversed[length++] = (char)('0' + (value & 1u));
        value >>= 1u;
    } while (value != 0);

    for (size_t i = 0; i < length; ++i)
        code[i] = reversed[length - i - 1];
    code[length] = '\0';
    return length;
}

static int is_power_of_two(size_t value)
{
    return value != 0 && (value & (value - 1)) == 0;
}

static int compress_bits(const int64_t *input, size_t bit_count,
                         uint8_t *compressed, size_t *compressed_length)
{
    LexiconEntry entries[MAX_DICTIONARY_ENTRIES];
    memset(entries, 0, sizeof(entries));
    size_t entry_count = 2;
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

    char current[MAX_KEY_LENGTH + 1];
    size_t current_length = 0;
    size_t index = entry_count;
    size_t output_length = 0;

    for (size_t bit = 0; bit < bit_count; ++bit) {
        current[current_length++] = input[bit + 1] == 48 ? '0' : '1';
        current[current_length] = '\0';
        size_t match = find_entry(entries, entry_count, current, current_length);
        if (match == entry_count) continue;

        char matched_code[MAX_CODE_WIDTH + 1];
        size_t matched_code_length = entries[match].code_length;
        memcpy(matched_code, entries[match].code, matched_code_length);
        matched_code[matched_code_length] = '\0';
        if (output_length + matched_code_length > MAX_OUTPUT_BYTES) return 0;
        memcpy(compressed + output_length, matched_code, matched_code_length);
        output_length += matched_code_length;

        for (size_t entry = match; entry + 1 < entry_count; ++entry)
            entries[entry] = entries[entry + 1];
        --entry_count;

        char child_key[MAX_KEY_LENGTH + 1];
        if (current_length + 1 > MAX_KEY_LENGTH) return 0;
        memcpy(child_key, current, current_length);
        child_key[current_length] = '0';
        child_key[current_length + 1] = '\0';
        if (!insert_or_update(entries, &entry_count, child_key,
                              current_length + 1, matched_code,
                              matched_code_length)) return 0;

        if (is_power_of_two(index)) {
            for (size_t entry = 0; entry < entry_count; ++entry) {
                if (entries[entry].code_length >= MAX_CODE_WIDTH) return 0;
                memmove(entries[entry].code + 1, entries[entry].code,
                        entries[entry].code_length);
                entries[entry].code[0] = '0';
                ++entries[entry].code_length;
                entries[entry].code[entries[entry].code_length] = '\0';
            }
        }

        char second_child[MAX_KEY_LENGTH + 1];
        memcpy(second_child, current, current_length);
        second_child[current_length] = '1';
        second_child[current_length + 1] = '\0';
        char index_code[MAX_CODE_WIDTH + 1];
        const size_t index_code_length = make_binary_code(index, index_code);
        if (index_code_length == 0 ||
            !insert_or_update(entries, &entry_count, second_child,
                              current_length + 1, index_code,
                              index_code_length)) return 0;

        ++index;
        current_length = 0;
    }

    if (current_length > 0) {
        size_t max_key_length = 0;
        for (size_t entry = 0; entry < entry_count; ++entry) {
            if (entries[entry].key_length > max_key_length)
                max_key_length = entries[entry].key_length;
        }
        for (;;) {
            const size_t match = find_entry(entries, entry_count,
                                            current, current_length);
            if (match != entry_count) {
                if (!append_code(compressed, &output_length, &entries[match])) return 0;
                break;
            }
            if (current_length >= max_key_length ||
                current_length >= MAX_KEY_LENGTH) return 0;
            current[current_length++] = '0';
            current[current_length] = '\0';
        }
    }

    *compressed_length = output_length;
    return 1;
}

int64_t lempel_ziv(const int64_t *input, size_t input_length,
                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_INPUT_BITS) return -1;
    const size_t bit_count = (size_t)input[0];
    if (input_length != 1 + bit_count) return -1;
    for (size_t bit = 0; bit < bit_count; ++bit) {
        if (input[bit + 1] != 48 && input[bit + 1] != 49) return -1;
    }

    uint8_t compressed[MAX_OUTPUT_BYTES];
    size_t compressed_length = 0;
    if (!compress_bits(input, bit_count, compressed, &compressed_length)) return -1;
    if (output == NULL || output_capacity < compressed_length) return -2;
    if (compressed_length > 0) memcpy(output, compressed, compressed_length);
    return (int64_t)compressed_length;
}
