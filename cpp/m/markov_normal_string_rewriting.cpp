#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t RULE_LIMIT = 8, STEP_LIMIT = 32, WORD_LIMIT = 64, SIDE_LIMIT = 8;
struct Rule {
    std::int64_t kind = 0;
    std::size_t left_size = 0, right_size = 0;
    std::array<std::int64_t, SIDE_LIMIT> left{}, right{};
};
}

extern "C" std::int64_t markov_normal_string_rewriting(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 204) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(RULE_LIMIT) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(STEP_LIMIT) ||
        input[2] < 0 || input[2] > 48) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    const std::size_t budget = static_cast<std::size_t>(input[1]);
    std::array<std::int64_t, WORD_LIMIT> word{};
    std::size_t word_size = static_cast<std::size_t>(input[2]);
    if (length < 3 + word_size) return -1;
    std::size_t cursor = 3;
    for (std::size_t i = 0; i < word_size; ++i) {
        if (input[cursor] < 0 || input[cursor] > 25) return -1;
        word[i] = input[cursor++];
    }
    std::array<Rule, RULE_LIMIT> rules{};
    for (std::size_t r = 0; r < count; ++r) {
        if (cursor + 3 > length) return -1;
        Rule& rule = rules[r];
        rule.kind = input[cursor++];
        const auto left_count = input[cursor++], right_count = input[cursor++];
        if ((rule.kind != 0 && rule.kind != 1) || left_count < 1 || left_count > 8 ||
            right_count < 0 || right_count > 8) return -1;
        rule.left_size = static_cast<std::size_t>(left_count);
        rule.right_size = static_cast<std::size_t>(right_count);
        if (cursor + rule.left_size + rule.right_size > length) return -1;
        for (std::size_t i = 0; i < rule.left_size; ++i) {
            if (input[cursor] < 0 || input[cursor] > 25) return -1;
            rule.left[i] = input[cursor++];
        }
        for (std::size_t i = 0; i < rule.right_size; ++i) {
            if (input[cursor] < 0 || input[cursor] > 25) return -1;
            rule.right[i] = input[cursor++];
        }
    }
    if (cursor != length) return -1;

    std::size_t rewrites = 0;
    std::uint8_t halt = 0;
    for (;;) {
        std::size_t chosen = count, offset = 0;
        for (std::size_t r = 0; r < count && chosen == count; ++r) {
            const Rule& rule = rules[r];
            if (rule.left_size > word_size) continue;
            for (std::size_t at = 0; at + rule.left_size <= word_size; ++at) {
                bool same = true;
                for (std::size_t j = 0; j < rule.left_size; ++j)
                    if (word[at + j] != rule.left[j]) { same = false; break; }
                if (same) { chosen = r; offset = at; break; }
            }
        }
        if (chosen == count) { halt = 0; break; }
        if (rewrites == budget) { halt = 2; break; }
        const Rule& rule = rules[chosen];
        const std::size_t new_size = word_size - rule.left_size + rule.right_size;
        if (new_size > WORD_LIMIT) return -3;
        std::array<std::int64_t, WORD_LIMIT> next{};
        std::size_t out = 0;
        for (std::size_t i = 0; i < offset; ++i) next[out++] = word[i];
        for (std::size_t i = 0; i < rule.right_size; ++i) next[out++] = rule.right[i];
        for (std::size_t i = offset + rule.left_size; i < word_size; ++i) next[out++] = word[i];
        word = next;
        word_size = new_size;
        ++rewrites;
        if (rule.kind == 1) { halt = 1; break; }
    }
    const std::size_t needed = 3 + word_size;
    if (output == nullptr || capacity < needed) return -2;
    output[0] = halt;
    output[1] = static_cast<std::uint8_t>(rewrites);
    output[2] = static_cast<std::uint8_t>(word_size);
    for (std::size_t i = 0; i < word_size; ++i) output[i + 3] = static_cast<std::uint8_t>(word[i]);
    return static_cast<std::int64_t>(needed);
}
