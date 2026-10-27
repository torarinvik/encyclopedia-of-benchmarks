#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_TEXT = 32, MAX_DICT = MAX_TEXT + 1, MAX_INPUT = 34;
void put_u64(std::uint8_t *out, std::size_t word, std::uint64_t value) {
    for (std::size_t i = 0; i < 8; ++i) out[word * 8 + i] = static_cast<std::uint8_t>(value >> (8 * i));
}
bool word_matches(const std::uint8_t words[MAX_DICT][MAX_TEXT], const std::size_t lengths[MAX_DICT],
                  std::size_t id, const std::uint8_t *text, std::size_t n, std::size_t pos) {
    return pos + lengths[id] <= n && std::memcmp(words[id], text + pos, lengths[id]) == 0;
}
std::size_t find_word(const std::uint8_t words[MAX_DICT][MAX_TEXT], const std::size_t lengths[MAX_DICT],
                      std::size_t count, const std::uint8_t *word, std::size_t len) {
    for (std::size_t i = 1; i < count; ++i)
        if (lengths[i] == len && std::memcmp(words[i], word, len) == 0) return i;
    return count;
}
std::size_t longest_match(const std::uint8_t words[MAX_DICT][MAX_TEXT], const std::size_t lengths[MAX_DICT],
                          std::size_t count, const std::uint8_t *extra, std::size_t extra_len,
                          bool has_extra, const std::uint8_t *text, std::size_t n, std::size_t pos) {
    std::size_t best = 0;
    for (std::size_t i = 1; i < count; ++i)
        if (lengths[i] > best && word_matches(words, lengths, i, text, n, pos)) best = lengths[i];
    if (has_extra && extra_len > best && pos + extra_len <= n && std::memcmp(extra, text + pos, extra_len) == 0)
        best = extra_len;
    return best;
}
}

extern "C" std::int64_t lz78_flexible_parsing(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 1 || length > MAX_INPUT) return -1;
    const auto n0 = input[0];
    if (n0 < 0 || n0 > static_cast<std::int64_t>(MAX_TEXT) || length != static_cast<std::size_t>(n0) + 1) return -1;
    const auto n = static_cast<std::size_t>(n0);
    std::uint8_t text[MAX_TEXT] = {};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
        text[i] = static_cast<std::uint8_t>(input[i + 1]);
    }
    std::uint8_t words[MAX_DICT][MAX_TEXT] = {};
    std::size_t lengths[MAX_DICT] = {};
    std::int64_t parents[MAX_TEXT] = {}, symbols[MAX_TEXT] = {};
    std::size_t dict_count = 1, token_count = 0, pos = 0;
    while (pos < n) {
        auto final_id = dict_count;
        for (std::size_t id = 1; id < dict_count; ++id)
            if (lengths[id] == n - pos && std::memcmp(words[id], text + pos, n - pos) == 0) { final_id = id; break; }
        if (final_id != dict_count) {
            parents[token_count] = static_cast<std::int64_t>(final_id); symbols[token_count++] = 0; pos = n; break;
        }
        bool have = false, best_new = false;
        std::size_t best_parent = 0, best_len = 0, best_next = 0;
        std::uint8_t best_word[MAX_TEXT] = {}, best_symbol = 0;
        for (std::size_t parent = 0; parent < dict_count; ++parent) {
            if (!word_matches(words, lengths, parent, text, n, pos)) continue;
            const auto prefix_len = lengths[parent], symbol_pos = pos + prefix_len;
            if (symbol_pos >= n) continue;
            const auto phrase_len = prefix_len + 1;
            std::uint8_t phrase[MAX_TEXT] = {};
            if (prefix_len) std::memcpy(phrase, words[parent], prefix_len);
            phrase[prefix_len] = text[symbol_pos];
            const bool is_new = find_word(words, lengths, dict_count, phrase, phrase_len) == dict_count;
            const auto next_pos = pos + phrase_len;
            const auto next_match = longest_match(words, lengths, dict_count, phrase, phrase_len, is_new, text, n, next_pos);
            const auto advancement = phrase_len + next_match;
            if (!have || advancement > best_next || (advancement == best_next && phrase_len > best_len) ||
                (advancement == best_next && phrase_len == best_len && parent < best_parent)) {
                have = true; best_parent = parent; best_len = phrase_len; best_next = advancement;
                best_symbol = text[symbol_pos]; best_new = is_new; std::memcpy(best_word, phrase, phrase_len);
            }
        }
        if (!have) return -1;
        parents[token_count] = static_cast<std::int64_t>(best_parent); symbols[token_count++] = best_symbol;
        if (best_new) { std::memcpy(words[dict_count], best_word, best_len); lengths[dict_count++] = best_len; }
        pos += best_len;
    }
    const auto bytes = token_count * 16;
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < token_count; ++i) {
        put_u64(output, 2 * i, static_cast<std::uint64_t>(parents[i]));
        put_u64(output, 2 * i + 1, static_cast<std::uint64_t>(symbols[i]));
    }
    return static_cast<std::int64_t>(bytes);
}
