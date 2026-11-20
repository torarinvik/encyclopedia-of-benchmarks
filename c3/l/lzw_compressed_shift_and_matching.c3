module lzw_compressed_shift_and_matching;

const usz MAX_ALPHABET = 16;
const usz MAX_PATTERN = 32;
const usz MAX_CODES = 32;
const usz MAX_DICTIONARY = 47;
const usz MAX_EXPANDED = 528;
const usz MAX_INPUT = 67;
const usz MAX_OUTPUT_BYTES = 4232;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long lzw_compressed_shift_and_matching(long* input, usz length, char* output, usz capacity)
        @export("lzw_compressed_shift_and_matching") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long alphabet_raw = input[0]; long pattern_raw = input[1]; long code_count_raw = input[2];
    if (alphabet_raw < 1 || alphabet_raw > (long)MAX_ALPHABET || pattern_raw < 1 || pattern_raw > (long)MAX_PATTERN
            || code_count_raw < 0 || code_count_raw > (long)MAX_CODES) return -1;
    usz alphabet_size = (usz)alphabet_raw; usz pattern_length = (usz)pattern_raw; usz code_count = (usz)code_count_raw;
    if (length != 3 + pattern_length + code_count) return -1;
    long* pattern = &input[3]; long* codes = &input[3 + pattern_length];
    uint[MAX_ALPHABET] symbol_mask = zeroed;
    for (usz i = 0; i < pattern_length; i += 1) {
        if (pattern[i] < 0 || pattern[i] >= alphabet_raw) return -1;
        symbol_mask[(usz)pattern[i]] |= (uint)1 << i;
    }
    if (code_count > 0 && (codes[0] < 0 || codes[0] >= alphabet_raw)) return -1;

    usz[MAX_DICTIONARY] phrase_length = zeroed;
    u8[MAX_DICTIONARY] first_symbol = zeroed;
    uint[MAX_DICTIONARY] phrase_mask = zeroed;
    uint[MAX_DICTIONARY] crossing_mask = zeroed;
    bool[MAX_DICTIONARY] ends_match = zeroed;
    int[MAX_DICTIONARY] previous_match = zeroed;
    uint top_bit = (uint)1 << (pattern_length - 1);
    for (usz symbol = 0; symbol < alphabet_size; symbol += 1) {
        phrase_length[symbol] = 1; first_symbol[symbol] = (u8)symbol;
        phrase_mask[symbol] = symbol_mask[symbol];
        if (pattern_length > 1 && (phrase_mask[symbol] & top_bit) != 0) crossing_mask[symbol] = (uint)1 << (pattern_length - 2);
        ends_match[symbol] = pattern_length == 1 && (phrase_mask[symbol] & top_bit) != 0;
        previous_match[symbol] = -1;
    }

    long[1 + MAX_EXPANDED] words = zeroed;
    usz occurrence_count = 0; usz node_count = alphabet_size; usz text_offset = 0;
    uint state = 0; int previous_code = -1;
    for (usz token = 0; token < code_count; token += 1) {
        long code_raw = codes[token]; int current_code;
        if (previous_code < 0) current_code = (int)code_raw;
        else {
            if (code_raw < 0 || code_raw > (long)node_count) return -1;
            u8 appended;
            if (code_raw == (long)node_count) { appended = first_symbol[(usz)previous_code]; current_code = (int)node_count; }
            else { current_code = (int)code_raw; appended = first_symbol[(usz)current_code]; }
            if (node_count >= MAX_DICTIONARY) return -1;
            usz node = node_count; node_count += 1;
            phrase_length[node] = phrase_length[(usz)previous_code] + 1;
            first_symbol[node] = first_symbol[(usz)previous_code];
            phrase_mask[node] = ((phrase_mask[(usz)previous_code] << 1) | 1) & symbol_mask[appended];
            crossing_mask[node] = crossing_mask[(usz)previous_code];
            if (phrase_length[node] < pattern_length && (phrase_mask[node] & top_bit) != 0)
                crossing_mask[node] |= (uint)1 << (pattern_length - phrase_length[node] - 1);
            ends_match[node] = phrase_length[node] >= pattern_length && (phrase_mask[node] & top_bit) != 0;
            previous_match[node] = ends_match[(usz)previous_code] ? previous_code : previous_match[(usz)previous_code];
        }
        uint crossing = state & crossing_mask[(usz)current_code];
        while (crossing != 0) {
            usz highest = 0; for (uint bits = crossing; (bits >>= 1) != 0;) highest += 1;
            words[1 + occurrence_count] = (long)text_offset - (long)(highest + 1); occurrence_count += 1;
            crossing &= ~((uint)1 << highest);
        }
        int[MAX_DICTIONARY] internal_nodes = zeroed; usz internal_count = 0;
        int node = ends_match[(usz)current_code] ? current_code : previous_match[(usz)current_code];
        while (node >= 0) { internal_nodes[internal_count] = node; internal_count += 1; node = previous_match[(usz)node]; }
        while (internal_count > 0) {
            internal_count -= 1; node = internal_nodes[internal_count];
            words[1 + occurrence_count] = (long)text_offset + (long)phrase_length[(usz)node] - (long)pattern_length;
            occurrence_count += 1;
        }
        usz current_length = phrase_length[(usz)current_code];
        uint shifted = current_length >= pattern_length ? 0 : state << current_length;
        uint fresh = current_length >= pattern_length
                ? (pattern_length == 32 ? 0xFFFFFFFF : ((uint)1 << pattern_length) - 1)
                : ((uint)1 << current_length) - 1;
        state = (shifted | fresh) & phrase_mask[(usz)current_code];
        text_offset += current_length; previous_code = current_code;
    }
    words[0] = (long)occurrence_count;
    usz output_bytes = 8 * (1 + occurrence_count);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz word = 0; word < 1 + occurrence_count; word += 1) store_i64_le(&staged[0], 8 * word, words[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
