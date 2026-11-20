module cyk_context_free_recognition;

const int MAX_NONTERMINALS = 4;
const int MAX_TERMINALS = 2;
const int MAX_WORD_LENGTH = 8;
const int MAX_PRODUCTIONS = 12;
const usz MAX_INPUT_LENGTH = 62;

fn long cyk_context_free_recognition(long* input, usz length) @export("cyk_context_free_recognition") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long variables_value = input[0], alphabet_value = input[1];
    long word_value = input[2], rule_value = input[3], start_value = input[4];
    if (variables_value < 1 || variables_value > MAX_NONTERMINALS ||
        alphabet_value < 1 || alphabet_value > MAX_TERMINALS ||
        word_value < 1 || word_value > MAX_WORD_LENGTH ||
        rule_value < 0 || rule_value > MAX_PRODUCTIONS ||
        start_value < 0 || start_value >= variables_value) return -1;
    usz word_length = (usz)word_value;
    usz rule_count = (usz)rule_value;
    if (length != 5 + word_length + 4 * rule_count) return -1;

    for (usz position = 0; position < word_length; position += 1)
        if (input[5 + position] < 0 || input[5 + position] >= alphabet_value) return -1;
    usz rules = 5 + word_length;
    for (usz rule = 0; rule < rule_count; rule += 1) {
        usz offset = rules + 4 * rule;
        long kind = input[offset], lhs = input[offset + 1];
        long first = input[offset + 2], second = input[offset + 3];
        if (lhs < 0 || lhs >= variables_value) return -1;
        if (kind == 0) {
            if (first < 0 || first >= alphabet_value || second != 0) return -1;
        } else if (kind == 1) {
            if (first < 0 || first >= variables_value || second < 0 || second >= variables_value)
                return -1;
        } else return -1;
    }

    bool[4 * 8 * 9] chart = zeroed;
    for (usz position = 0; position < word_length; position += 1) {
        long token = input[5 + position];
        for (usz rule = 0; rule < rule_count; rule += 1) {
            usz offset = rules + 4 * rule;
            if (input[offset] == 0 && input[offset + 2] == token)
                chart[(usz)input[offset + 1] * 72 + position * 9 + 1] = true;
        }
    }
    for (usz width = 2; width <= word_length; width += 1) {
        for (usz left = 0; left + width <= word_length; left += 1) {
            for (usz rule = 0; rule < rule_count; rule += 1) {
                usz offset = rules + 4 * rule;
                if (input[offset] != 1) continue;
                usz lhs = (usz)input[offset + 1], first = (usz)input[offset + 2];
                usz second = (usz)input[offset + 3];
                for (usz split = 1; split < width; split += 1) {
                    if (chart[first * 72 + left * 9 + split] &&
                        chart[second * 72 + (left + split) * 9 + width - split]) {
                        chart[lhs * 72 + left * 9 + width] = true;
                        break;
                    }
                }
            }
        }
    }
    return chart[(usz)start_value * 72 + word_length] ? 1 : 0;
}
