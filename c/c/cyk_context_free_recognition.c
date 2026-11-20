/* Bounded CYK membership for epsilon-free Chomsky-normal grammars. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NONTERMINALS 4
#define MAX_TERMINALS 2
#define MAX_WORD_LENGTH 8
#define MAX_PRODUCTIONS 12
#define MAX_PARSEABLE_INPUT_LENGTH 62

int64_t cyk_context_free_recognition(const int64_t *input, size_t length)
{
    if (input == NULL || length < 5 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_variables = input[0], raw_alphabet = input[1];
    const int64_t raw_word_length = input[2], raw_rule_count = input[3], raw_start = input[4];
    if (raw_variables < 1 || raw_variables > MAX_NONTERMINALS ||
        raw_alphabet < 1 || raw_alphabet > MAX_TERMINALS ||
        raw_word_length < 1 || raw_word_length > MAX_WORD_LENGTH ||
        raw_rule_count < 0 || raw_rule_count > MAX_PRODUCTIONS ||
        raw_start < 0 || raw_start >= raw_variables) return -1;
    const size_t word_length = (size_t)raw_word_length;
    const size_t rule_count = (size_t)raw_rule_count;
    if (length != 5 + word_length + 4 * rule_count) return -1;

    for (size_t position = 0; position < word_length; ++position)
        if (input[5 + position] < 0 || input[5 + position] >= raw_alphabet) return -1;
    const size_t rules = 5 + word_length;
    for (size_t rule = 0; rule < rule_count; ++rule) {
        const size_t offset = rules + 4 * rule;
        const int64_t kind = input[offset], lhs = input[offset + 1];
        const int64_t first = input[offset + 2], second = input[offset + 3];
        if (lhs < 0 || lhs >= raw_variables) return -1;
        if (kind == 0) {
            if (first < 0 || first >= raw_alphabet || second != 0) return -1;
        } else if (kind == 1) {
            if (first < 0 || first >= raw_variables || second < 0 || second >= raw_variables)
                return -1;
        } else return -1;
    }

    bool chart[MAX_NONTERMINALS][MAX_WORD_LENGTH][MAX_WORD_LENGTH + 1] = {{{false}}};
    for (size_t position = 0; position < word_length; ++position) {
        const int64_t token = input[5 + position];
        for (size_t rule = 0; rule < rule_count; ++rule) {
            const size_t offset = rules + 4 * rule;
            if (input[offset] == 0 && input[offset + 2] == token)
                chart[input[offset + 1]][position][1] = true;
        }
    }
    for (size_t width = 2; width <= word_length; ++width) {
        for (size_t left = 0; left + width <= word_length; ++left) {
            for (size_t rule = 0; rule < rule_count; ++rule) {
                const size_t offset = rules + 4 * rule;
                if (input[offset] != 1) continue;
                const size_t lhs = (size_t)input[offset + 1];
                const size_t first = (size_t)input[offset + 2];
                const size_t second = (size_t)input[offset + 3];
                for (size_t split = 1; split < width; ++split) {
                    if (chart[first][left][split] && chart[second][left + split][width - split]) {
                        chart[lhs][left][width] = true;
                        break;
                    }
                }
            }
        }
    }
    return chart[(size_t)raw_start][0][word_length] ? 1 : 0;
}
