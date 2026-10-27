module lz78_flexible_parsing;

const usz MAX_TEXT = 32;
const usz MAX_DICT = 33;
const usz MAX_OUTPUT = 512;

fn void store_u64(uint8* output, usz offset, ulong value) {
    for (usz i = 0; i < 8; i++) { output[offset + i] = (uint8)(value & 255); value >>= 8; }
}

fn long lz78_flexible_parsing(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("lz78_flexible_parsing") {
    if (input == null || input_length < 1 || input_length > 34) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT || input_length != 1 + (usz)input[0]) return -1;
    usz n = (usz)input[0];
    uint8[MAX_TEXT] text = zeroed;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
        text[i] = (uint8)input[i + 1];
    }
    uint8[MAX_DICT][MAX_TEXT] words = zeroed;
    usz[MAX_DICT] word_lengths = zeroed;
    long[MAX_TEXT] token_parent = zeroed, token_symbol = zeroed;
    usz dictionary_count = 1, token_count = 0, position = 0;
    while (position < n) {
        usz final_id = dictionary_count;
        for (usz id = 1; id < dictionary_count; id++) {
            if (word_lengths[id] == n - position) {
                bool same = true;
                for (usz i = 0; i < n - position; i++) if (words[id][i] != text[position + i]) same = false;
                if (same) { final_id = id; break; }
            }
        }
        if (final_id != dictionary_count) {
            token_parent[token_count] = (long)final_id; token_symbol[token_count] = 0;
            token_count++; position = n; break;
        }
        bool have_best = false, best_new = false;
        usz best_parent = 0, best_length = 0, best_next = 0;
        uint8 best_symbol = 0;
        uint8[MAX_TEXT] best_word = zeroed;
        for (usz parent = 0; parent < dictionary_count; parent++) {
            usz prefix_length = word_lengths[parent];
            if (position + prefix_length > n) continue;
            bool prefix_matches = true;
            for (usz i = 0; i < prefix_length; i++) if (words[parent][i] != text[position + i]) prefix_matches = false;
            if (!prefix_matches) continue;
            usz symbol_position = position + prefix_length;
            if (symbol_position >= n) continue;
            usz phrase_length = prefix_length + 1;
            uint8[MAX_TEXT] phrase = zeroed;
            for (usz i = 0; i < prefix_length; i++) phrase[i] = words[parent][i];
            phrase[prefix_length] = text[symbol_position];
            usz phrase_id = dictionary_count;
            for (usz id = 1; id < dictionary_count; id++) {
                if (word_lengths[id] != phrase_length) continue;
                bool same = true;
                for (usz i = 0; i < phrase_length; i++) if (words[id][i] != phrase[i]) same = false;
                if (same) { phrase_id = id; break; }
            }
            bool is_new = phrase_id == dictionary_count;
            usz next_position = position + phrase_length, next_match = 0;
            for (usz id = 1; id < dictionary_count; id++) {
                usz candidate_length = word_lengths[id];
                if (candidate_length <= next_match || next_position + candidate_length > n) continue;
                bool same = true;
                for (usz i = 0; i < candidate_length; i++) if (words[id][i] != text[next_position + i]) same = false;
                if (same) next_match = candidate_length;
            }
            if (is_new && phrase_length > next_match && next_position + phrase_length <= n) {
                bool same = true;
                for (usz i = 0; i < phrase_length; i++) if (phrase[i] != text[next_position + i]) same = false;
                if (same) next_match = phrase_length;
            }
            usz advancement = phrase_length + next_match;
            if (!have_best || advancement > best_next ||
                (advancement == best_next && phrase_length > best_length) ||
                (advancement == best_next && phrase_length == best_length && parent < best_parent)) {
                have_best = true; best_parent = parent; best_length = phrase_length; best_next = advancement;
                best_symbol = text[symbol_position]; best_new = is_new; best_word = phrase;
            }
        }
        if (!have_best) return -1;
        token_parent[token_count] = (long)best_parent; token_symbol[token_count] = (long)best_symbol; token_count++;
        if (best_new) { words[dictionary_count] = best_word; word_lengths[dictionary_count] = best_length; dictionary_count++; }
        position += best_length;
    }
    usz output_bytes = 16 * token_count;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz i = 0; i < token_count; i++) {
        store_u64(output, 16 * i, (ulong)token_parent[i]);
        store_u64(output, 16 * i + 8, (ulong)token_symbol[i]);
    }
    return (long)output_bytes;
}
