/* Bounded CYK membership for epsilon-free Chomsky-normal grammars. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_nonterminals = 4;
constexpr std::int64_t max_terminals = 2;
constexpr std::int64_t max_word_length = 8;
constexpr std::int64_t max_productions = 12;
constexpr std::size_t max_input_length = 62;
}

extern "C" std::int64_t cyk_context_free_recognition(const std::int64_t* input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length < 5 || length > max_input_length) return -1;
    const auto variables_value = input[0], alphabet_value = input[1];
    const auto word_value = input[2], rule_value = input[3], start_value = input[4];
    if (variables_value < 1 || variables_value > max_nonterminals ||
        alphabet_value < 1 || alphabet_value > max_terminals ||
        word_value < 1 || word_value > max_word_length ||
        rule_value < 0 || rule_value > max_productions ||
        start_value < 0 || start_value >= variables_value) return -1;
    const auto word_length = static_cast<std::size_t>(word_value);
    const auto rule_count = static_cast<std::size_t>(rule_value);
    if (length != 5 + word_length + 4 * rule_count) return -1;
    for (std::size_t position = 0; position < word_length; ++position)
        if (input[5 + position] < 0 || input[5 + position] >= alphabet_value) return -1;
    const std::size_t rules = 5 + word_length;
    for (std::size_t rule = 0; rule < rule_count; ++rule) {
        const std::size_t offset = rules + 4 * rule;
        const auto kind = input[offset], lhs = input[offset + 1];
        const auto first = input[offset + 2], second = input[offset + 3];
        if (lhs < 0 || lhs >= variables_value) return -1;
        if (kind == 0) {
            if (first < 0 || first >= alphabet_value || second != 0) return -1;
        } else if (kind == 1) {
            if (first < 0 || first >= variables_value || second < 0 || second >= variables_value)
                return -1;
        } else return -1;
    }

    std::array<std::array<std::array<bool, 9>, 8>, 4> chart{};
    for (std::size_t position = 0; position < word_length; ++position) {
        const auto token = input[5 + position];
        for (std::size_t rule = 0; rule < rule_count; ++rule) {
            const auto offset = rules + 4 * rule;
            if (input[offset] == 0 && input[offset + 2] == token)
                chart[static_cast<std::size_t>(input[offset + 1])][position][1] = true;
        }
    }
    for (std::size_t width = 2; width <= word_length; ++width) {
        for (std::size_t left = 0; left + width <= word_length; ++left) {
            for (std::size_t rule = 0; rule < rule_count; ++rule) {
                const auto offset = rules + 4 * rule;
                if (input[offset] != 1) continue;
                const auto lhs = static_cast<std::size_t>(input[offset + 1]);
                const auto first = static_cast<std::size_t>(input[offset + 2]);
                const auto second = static_cast<std::size_t>(input[offset + 3]);
                for (std::size_t split = 1; split < width; ++split) {
                    if (chart[first][left][split] && chart[second][left + split][width - split]) {
                        chart[lhs][left][width] = true;
                        break;
                    }
                }
            }
        }
    }
    return chart[static_cast<std::size_t>(start_value)][0][word_length] ? 1 : 0;
}
