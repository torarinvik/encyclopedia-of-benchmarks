#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_TEXT 32
#define MAX_INPUT 34
#define MAX_OUTPUT (16 * MAX_TEXT)
#define MAX_DICT (MAX_TEXT + 1)

static void put_u64(uint8_t *out, size_t word, uint64_t value) {
    for (size_t i = 0; i < 8; ++i) out[word * 8 + i] = (uint8_t)(value >> (8 * i));
}

static bool word_matches(const uint8_t words[MAX_DICT][MAX_TEXT], const size_t lengths[MAX_DICT],
                         size_t id, const uint8_t *text, size_t n, size_t position) {
    const size_t length = lengths[id];
    return position + length <= n && memcmp(words[id], text + position, length) == 0;
}

static size_t find_word(const uint8_t words[MAX_DICT][MAX_TEXT], const size_t lengths[MAX_DICT],
                        size_t count, const uint8_t *word, size_t length) {
    for (size_t id = 1; id < count; ++id)
        if (lengths[id] == length && memcmp(words[id], word, length) == 0) return id;
    return count;
}

static size_t longest_match(const uint8_t words[MAX_DICT][MAX_TEXT], const size_t lengths[MAX_DICT],
                            size_t count, const uint8_t *extra, size_t extra_length,
                            bool has_extra, const uint8_t *text, size_t n, size_t position) {
    size_t best = 0;
    for (size_t id = 1; id < count; ++id)
        if (lengths[id] > best && word_matches(words, lengths, id, text, n, position)) best = lengths[id];
    if (has_extra && extra_length > best && position + extra_length <= n &&
        memcmp(extra, text + position, extra_length) == 0) best = extra_length;
    return best;
}

int64_t lz78_flexible_parsing(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0];
    if (n0 < 0 || n0 > MAX_TEXT || length != (size_t)n0 + 1) return -1;
    const size_t n = (size_t)n0;
    uint8_t text[MAX_TEXT] = {0};
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
        text[i] = (uint8_t)input[i + 1];
    }

    uint8_t words[MAX_DICT][MAX_TEXT] = {{0}};
    size_t word_lengths[MAX_DICT] = {0};
    int64_t token_parent[MAX_TEXT] = {0}, token_symbol[MAX_TEXT] = {0};
    size_t dictionary_count = 1, token_count = 0, position = 0;
    while (position < n) {
        size_t final_id = dictionary_count;
        for (size_t id = 1; id < dictionary_count; ++id) {
            if (word_lengths[id] == n - position &&
                memcmp(words[id], text + position, n - position) == 0) { final_id = id; break; }
        }
        if (final_id != dictionary_count) {
            token_parent[token_count] = (int64_t)final_id;
            token_symbol[token_count++] = 0;
            position = n;
            break;
        }

        bool have_best = false;
        size_t best_parent = 0, best_length = 0, best_next = 0;
        uint8_t best_word[MAX_TEXT] = {0};
        uint8_t best_symbol = 0;
        bool best_is_new = false;
        for (size_t parent = 0; parent < dictionary_count; ++parent) {
            if (!word_matches(words, word_lengths, parent, text, n, position)) continue;
            const size_t prefix_length = word_lengths[parent];
            const size_t symbol_position = position + prefix_length;
            if (symbol_position >= n) continue;
            const size_t phrase_length = prefix_length + 1;
            uint8_t phrase[MAX_TEXT] = {0};
            if (prefix_length) memcpy(phrase, words[parent], prefix_length);
            phrase[prefix_length] = text[symbol_position];
            const bool is_new = find_word(words, word_lengths, dictionary_count, phrase, phrase_length) == dictionary_count;
            const size_t next_position = position + phrase_length;
            const size_t next_match = longest_match(words, word_lengths, dictionary_count,
                phrase, phrase_length, is_new, text, n, next_position);
            const size_t advancement = phrase_length + next_match;
            if (!have_best || advancement > best_next ||
                (advancement == best_next && phrase_length > best_length) ||
                (advancement == best_next && phrase_length == best_length && parent < best_parent)) {
                have_best = true;
                best_parent = parent;
                best_length = phrase_length;
                best_next = advancement;
                best_symbol = text[symbol_position];
                best_is_new = is_new;
                memcpy(best_word, phrase, phrase_length);
            }
        }
        if (!have_best) return -1;
        token_parent[token_count] = (int64_t)best_parent;
        token_symbol[token_count++] = (int64_t)best_symbol;
        if (best_is_new) {
            memcpy(words[dictionary_count], best_word, best_length);
            word_lengths[dictionary_count++] = best_length;
        }
        position += best_length;
    }

    const size_t output_bytes = token_count * 16;
    if (!output || capacity < output_bytes) return -2;
    for (size_t i = 0; i < token_count; ++i) {
        put_u64(output, 2 * i, (uint64_t)token_parent[i]);
        put_u64(output, 2 * i + 1, (uint64_t)token_symbol[i]);
    }
    return (int64_t)output_bytes;
}
