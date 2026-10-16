#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 4096
#define MAX_CODES 4352
#define MAX_OUTPUT 65536
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define HASH_MASK UINT64_C(0x7fffffffffffffff)

static uint64_t hash_i64(uint64_t hash, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) {
        hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    }
    return hash;
}

static int expand_code(int code, int dictionary_size, const int32_t *prefix,
                       const uint8_t *suffix, uint8_t *phrase,
                       size_t phrase_capacity, size_t *phrase_length) {
    size_t length = 0;
    int current = code;
    while (current >= 256) {
        if (current >= dictionary_size || length >= phrase_capacity) return 0;
        phrase[length++] = suffix[current];
        current = prefix[current];
        if (current < 0) return 0;
    }
    if (current < 0 || current > 255 || length >= phrase_capacity) return 0;
    phrase[length++] = (uint8_t)current;
    for (size_t left = 0, right = length - 1; left < right; ++left, --right) {
        const uint8_t byte = phrase[left];
        phrase[left] = phrase[right];
        phrase[right] = byte;
    }
    *phrase_length = length;
    return 1;
}

static int64_t hash_record(int64_t mode, size_t result_length,
                           const int64_t *result_values) {
    uint64_t hash = hash_i64(FNV_OFFSET, mode);
    hash = hash_i64(hash, (int64_t)result_length);
    for (size_t i = 0; i < result_length; ++i) {
        hash = hash_i64(hash, result_values[i]);
    }
    return (int64_t)(hash & HASH_MASK);
}

int64_t lzw(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_ITEMS + 2) return -1;
    const int64_t mode = input[0];
    const int64_t count64 = input[1];
    if ((mode != 0 && mode != 1) || count64 < 0 || count64 > MAX_ITEMS ||
        length != (size_t)count64 + 2) {
        return -1;
    }
    const size_t count = (size_t)count64;

    int32_t prefix[MAX_CODES];
    int32_t next_sibling[MAX_CODES];
    int32_t first_child[MAX_CODES];
    uint8_t suffix[MAX_CODES];
    uint8_t first_symbol[MAX_CODES];
    for (size_t i = 0; i < MAX_CODES; ++i) {
        prefix[i] = -1;
        next_sibling[i] = -1;
        first_child[i] = -1;
        suffix[i] = 0;
        first_symbol[i] = 0;
    }
    for (int code = 0; code < 256; ++code) {
        suffix[code] = (uint8_t)code;
        first_symbol[code] = (uint8_t)code;
    }

    if (mode == 0) {
        for (size_t i = 0; i < count; ++i) {
            if (input[2 + i] < 0 || input[2 + i] > 127) return -1;
        }
        int64_t codes[MAX_ITEMS];
        size_t code_count = 0;
        if (count > 0) {
            int dictionary_size = 256;
            int current = (int)input[2];
            for (size_t i = 1; i < count; ++i) {
                const int byte = (int)input[2 + i];
                int match = first_child[current];
                while (match >= 0 && suffix[match] != (uint8_t)byte) {
                    match = next_sibling[match];
                }
                if (match >= 0) {
                    current = match;
                } else {
                    codes[code_count++] = current;
                    if (dictionary_size >= MAX_CODES) return -1;
                    prefix[dictionary_size] = current;
                    suffix[dictionary_size] = (uint8_t)byte;
                    first_symbol[dictionary_size] = first_symbol[current];
                    next_sibling[dictionary_size] = first_child[current];
                    first_child[current] = dictionary_size;
                    ++dictionary_size;
                    current = byte;
                }
            }
            codes[code_count++] = current;
        }
        return hash_record(0, code_count, codes);
    }

    for (size_t i = 0; i < count; ++i) {
        if (input[2 + i] < 0 || input[2 + i] >= MAX_CODES) return -1;
    }
    if (count == 0) return hash_record(1, 0, NULL);
    const int first_code = (int)input[2];
    if (first_code > 127) return -1;

    uint8_t decoded[MAX_OUTPUT];
    uint8_t phrase[MAX_CODES];
    size_t decoded_length = 1;
    decoded[0] = (uint8_t)first_code;
    int dictionary_size = 256;
    int previous = first_code;

    for (size_t i = 1; i < count; ++i) {
        const int code = (int)input[2 + i];
        size_t phrase_length = 0;
        if (code < dictionary_size) {
            if (!expand_code(code, dictionary_size, prefix, suffix, phrase,
                             MAX_CODES, &phrase_length)) {
                return -1;
            }
        } else if (code == dictionary_size) {
            if (!expand_code(previous, dictionary_size, prefix, suffix, phrase,
                             MAX_CODES, &phrase_length) || phrase_length >= MAX_CODES) {
                return -1;
            }
            phrase[phrase_length++] = first_symbol[previous];
        } else {
            return -1;
        }

        if (decoded_length > MAX_OUTPUT - phrase_length) return -1;
        for (size_t j = 0; j < phrase_length; ++j) {
            if (phrase[j] > 127) return -1;
        }
        for (size_t j = 0; j < phrase_length; ++j) {
            decoded[decoded_length++] = phrase[j];
        }

        if (dictionary_size >= MAX_CODES) return -1;
        const uint8_t next_byte = code == dictionary_size
                                      ? first_symbol[previous]
                                      : first_symbol[code];
        prefix[dictionary_size] = previous;
        suffix[dictionary_size] = next_byte;
        first_symbol[dictionary_size] = first_symbol[previous];
        ++dictionary_size;
        previous = code;
    }

    uint64_t hash = hash_i64(FNV_OFFSET, 1);
    hash = hash_i64(hash, (int64_t)decoded_length);
    for (size_t i = 0; i < decoded_length; ++i) {
        hash = hash_i64(hash, decoded[i]);
    }
    return (int64_t)(hash & HASH_MASK);
}
