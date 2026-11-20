#include <stddef.h>
#include <stdint.h>

enum { MAX_ALPHABET = 16, MAX_PATTERN = 32, MAX_CODES = 32,
       MAX_DICTIONARY = 47, MAX_EXPANDED = 528, MAX_INPUT = 67,
       MAX_OUTPUT_BYTES = 4232 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t lzw_compressed_shift_and_matching(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const int64_t alphabet_raw = input[0], pattern_raw = input[1], code_count_raw = input[2];
    if (alphabet_raw < 1 || alphabet_raw > MAX_ALPHABET || pattern_raw < 1 || pattern_raw > MAX_PATTERN
            || code_count_raw < 0 || code_count_raw > MAX_CODES) return -1;
    const size_t alphabet_size = (size_t)alphabet_raw, pattern_length = (size_t)pattern_raw;
    const size_t code_count = (size_t)code_count_raw;
    if (length != 3 + pattern_length + code_count) return -1;
    const int64_t *pattern = input + 3, *codes = pattern + pattern_length;
    uint32_t symbol_mask[MAX_ALPHABET] = {};
    for (size_t i = 0; i < pattern_length; ++i) {
        if (pattern[i] < 0 || pattern[i] >= alphabet_raw) return -1;
        symbol_mask[pattern[i]] |= UINT32_C(1) << i;
    }
    if (code_count && (codes[0] < 0 || codes[0] >= alphabet_raw)) return -1;
    size_t phrase_length[MAX_DICTIONARY] = {};
    uint8_t first_symbol[MAX_DICTIONARY] = {};
    uint32_t phrase_mask[MAX_DICTIONARY] = {}, crossing_mask[MAX_DICTIONARY] = {};
    uint8_t ends_match[MAX_DICTIONARY] = {};
    int previous_match[MAX_DICTIONARY] = {};
    const uint32_t top_bit = UINT32_C(1) << (pattern_length - 1);
    for (size_t symbol = 0; symbol < alphabet_size; ++symbol) {
        phrase_length[symbol] = 1; first_symbol[symbol] = (uint8_t)symbol;
        phrase_mask[symbol] = symbol_mask[symbol];
        if (pattern_length > 1 && (phrase_mask[symbol] & top_bit)) crossing_mask[symbol] = UINT32_C(1) << (pattern_length - 2);
        ends_match[symbol] = (uint8_t)(pattern_length == 1 && (phrase_mask[symbol] & top_bit));
        previous_match[symbol] = -1;
    }
    int64_t words[1 + MAX_EXPANDED] = {};
    size_t occurrence_count = 0, node_count = alphabet_size, text_offset = 0;
    uint32_t state = 0; int previous_code = -1;
    for (size_t token = 0; token < code_count; ++token) {
        const int64_t code_raw = codes[token]; int current_code;
        if (previous_code < 0) current_code = (int)code_raw;
        else {
            if (code_raw < 0 || code_raw > (int64_t)node_count) return -1;
            uint8_t appended;
            if (code_raw == (int64_t)node_count) { appended = first_symbol[previous_code]; current_code = (int)node_count; }
            else { current_code = (int)code_raw; appended = first_symbol[current_code]; }
            if (node_count >= MAX_DICTIONARY) return -1;
            const int node = (int)node_count++;
            phrase_length[node] = phrase_length[previous_code] + 1;
            first_symbol[node] = first_symbol[previous_code];
            phrase_mask[node] = ((phrase_mask[previous_code] << 1) | 1u) & symbol_mask[appended];
            crossing_mask[node] = crossing_mask[previous_code];
            if (phrase_length[node] < pattern_length && (phrase_mask[node] & top_bit))
                crossing_mask[node] |= UINT32_C(1) << (pattern_length - phrase_length[node] - 1);
            ends_match[node] = (uint8_t)(phrase_length[node] >= pattern_length && (phrase_mask[node] & top_bit));
            previous_match[node] = ends_match[previous_code] ? previous_code : previous_match[previous_code];
        }
        uint32_t crossing = state & crossing_mask[current_code];
        while (crossing) {
            size_t highest = 0; for (uint32_t bits = crossing; (bits >>= 1) != 0;) ++highest;
            words[1 + occurrence_count++] = (int64_t)text_offset - (int64_t)(highest + 1);
            crossing &= ~(UINT32_C(1) << highest);
        }
        int internal_nodes[MAX_DICTIONARY] = {}; size_t internal_count = 0;
        int node = ends_match[current_code] ? current_code : previous_match[current_code];
        while (node >= 0) { internal_nodes[internal_count++] = node; node = previous_match[node]; }
        while (internal_count) {
            node = internal_nodes[--internal_count];
            words[1 + occurrence_count++] = (int64_t)text_offset + (int64_t)phrase_length[node] - (int64_t)pattern_length;
        }
        const size_t current_length = phrase_length[current_code];
        const uint32_t shifted = current_length >= pattern_length ? 0 : state << current_length;
        const uint32_t fresh = current_length >= pattern_length
                ? (pattern_length == 32 ? UINT32_MAX : (UINT32_C(1) << pattern_length) - 1)
                : (UINT32_C(1) << current_length) - 1;
        state = (shifted | fresh) & phrase_mask[current_code];
        text_offset += current_length; previous_code = current_code;
    }
    words[0] = (int64_t)occurrence_count;
    const size_t output_bytes = 8 * (1 + occurrence_count);
    if (output == nullptr || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {};
    for (size_t word = 0; word < 1 + occurrence_count; ++word) store_i64_le(staged, 8 * word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
