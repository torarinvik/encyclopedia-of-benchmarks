#include <stddef.h>
#include <stdint.h>

enum { MAX_RULES = 8, MAX_STEPS = 32, MAX_WORD = 64, MAX_SIDE = 8, MAX_INPUT = 204 };

typedef struct {
    int kind;
    int lhs_length;
    int rhs_length;
    int lhs[MAX_SIDE];
    int rhs[MAX_SIDE];
} Rule;

int64_t markov_normal_string_rewriting(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t rule_word = input[0], step_word = input[1], initial_word = input[2];
    if (rule_word < 0 || rule_word > MAX_RULES || step_word < 0 || step_word > MAX_STEPS ||
        initial_word < 0 || initial_word > 48 || length < 3 + (size_t)initial_word) return -1;
    const size_t rule_count = (size_t)rule_word;
    const size_t step_limit = (size_t)step_word;
    int word[MAX_WORD] = {0};
    size_t word_length = (size_t)initial_word;
    size_t cursor = 3;
    for (size_t i = 0; i < word_length; ++i) {
        if (input[cursor] < 0 || input[cursor] > 25) return -1;
        word[i] = (int)input[cursor++];
    }
    Rule rules[MAX_RULES] = {0};
    for (size_t r = 0; r < rule_count; ++r) {
        if (cursor + 3 > length) return -1;
        const int64_t kind = input[cursor++];
        const int64_t lhs_value = input[cursor++];
        const int64_t rhs_value = input[cursor++];
        if ((kind != 0 && kind != 1) || lhs_value < 1 || lhs_value > MAX_SIDE ||
            rhs_value < 0 || rhs_value > MAX_SIDE) return -1;
        Rule *rule = &rules[r];
        rule->kind = (int)kind;
        rule->lhs_length = (int)lhs_value;
        rule->rhs_length = (int)rhs_value;
        if (cursor + (size_t)rule->lhs_length + (size_t)rule->rhs_length > length) return -1;
        for (int i = 0; i < rule->lhs_length; ++i) {
            if (input[cursor] < 0 || input[cursor] > 25) return -1;
            rule->lhs[i] = (int)input[cursor++];
        }
        for (int i = 0; i < rule->rhs_length; ++i) {
            if (input[cursor] < 0 || input[cursor] > 25) return -1;
            rule->rhs[i] = (int)input[cursor++];
        }
    }
    if (cursor != length) return -1;

    size_t steps = 0;
    int halt = 0;
    for (;;) {
        size_t selected_rule = rule_count, selected_start = 0;
        for (size_t r = 0; r < rule_count && selected_rule == rule_count; ++r) {
            const Rule *rule = &rules[r];
            if ((size_t)rule->lhs_length > word_length) continue;
            for (size_t start = 0; start + (size_t)rule->lhs_length <= word_length; ++start) {
                int equal = 1;
                for (int k = 0; k < rule->lhs_length; ++k)
                    if (word[start + (size_t)k] != rule->lhs[k]) { equal = 0; break; }
                if (equal) { selected_rule = r; selected_start = start; break; }
            }
        }
        if (selected_rule == rule_count) { halt = 0; break; }
        if (steps == step_limit) { halt = 2; break; }
        Rule *rule = &rules[selected_rule];
        const size_t new_length = word_length - (size_t)rule->lhs_length + (size_t)rule->rhs_length;
        if (new_length > MAX_WORD) return -3;
        int next[MAX_WORD] = {0};
        size_t out = 0;
        for (size_t i = 0; i < selected_start; ++i) next[out++] = word[i];
        for (int i = 0; i < rule->rhs_length; ++i) next[out++] = rule->rhs[i];
        for (size_t i = selected_start + (size_t)rule->lhs_length; i < word_length; ++i) next[out++] = word[i];
        for (size_t i = 0; i < new_length; ++i) word[i] = next[i];
        word_length = new_length;
        ++steps;
        if (rule->kind == 1) { halt = 1; break; }
    }

    const size_t required = 3 + word_length;
    if (output == NULL || capacity < required) return -2;
    output[0] = (uint8_t)halt;
    output[1] = (uint8_t)steps;
    output[2] = (uint8_t)word_length;
    for (size_t i = 0; i < word_length; ++i) output[3 + i] = (uint8_t)word[i];
    return (int64_t)required;
}
