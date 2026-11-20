module markov_normal_string_rewriting;

const usz MAX_RULES = 8;
const usz MAX_INPUT = 204;
const usz MAX_WORD = 64;
const usz MAX_SIDE = 8;

struct Rule { long kind; usz left_len; usz right_len; long[8] left; long[8] right; }

fn long markov_normal_string_rewriting(long* input, usz length, char* output, usz capacity)
    @export("markov_normal_string_rewriting") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 32 || input[2] < 0 || input[2] > 48) return -1;
    usz count = (usz)input[0];
    usz budget = (usz)input[1];
    usz word_len = (usz)input[2];
    if (length < 3 + word_len) return -1;
    long[MAX_WORD] word = {0};
    usz cursor = 3;
    for (usz i = 0; i < word_len; i += 1) {
        if (input[cursor] < 0 || input[cursor] > 25) return -1;
        word[i] = input[cursor]; cursor += 1;
    }
    Rule[MAX_RULES] rules = {};
    for (usz r = 0; r < count; r += 1) {
        if (cursor + 3 > length) return -1;
        long kind = input[cursor]; long left_value = input[cursor + 1]; long right_value = input[cursor + 2]; cursor += 3;
        if ((kind != 0 && kind != 1) || left_value < 1 || left_value > 8 || right_value < 0 || right_value > 8) return -1;
        Rule* rule = &rules[r]; rule.kind = kind; rule.left_len = (usz)left_value; rule.right_len = (usz)right_value;
        if (cursor + rule.left_len + rule.right_len > length) return -1;
        for (usz i = 0; i < rule.left_len; i += 1) {
            if (input[cursor] < 0 || input[cursor] > 25) return -1;
            rule.left[i] = input[cursor]; cursor += 1;
        }
        for (usz i = 0; i < rule.right_len; i += 1) {
            if (input[cursor] < 0 || input[cursor] > 25) return -1;
            rule.right[i] = input[cursor]; cursor += 1;
        }
    }
    if (cursor != length) return -1;

    usz rewrites = 0; char halt = 0;
    while (true) {
        usz chosen = count; usz offset = 0;
        for (usz r = 0; r < count && chosen == count; r += 1) {
            Rule* rule = &rules[r];
            if (rule.left_len > word_len) continue;
            for (usz at = 0; at + rule.left_len <= word_len; at += 1) {
                bool equal = true;
                for (usz j = 0; j < rule.left_len; j += 1) if (word[at + j] != rule.left[j]) { equal = false; break; }
                if (equal) { chosen = r; offset = at; break; }
            }
        }
        if (chosen == count) { halt = 0; break; }
        if (rewrites == budget) { halt = 2; break; }
        Rule* rule = &rules[chosen];
        usz next_len = word_len - rule.left_len + rule.right_len;
        if (next_len > MAX_WORD) return -3;
        long[MAX_WORD] next = {0}; usz out = 0;
        for (usz i = 0; i < offset; i += 1) { next[out] = word[i]; out += 1; }
        for (usz i = 0; i < rule.right_len; i += 1) { next[out] = rule.right[i]; out += 1; }
        for (usz i = offset + rule.left_len; i < word_len; i += 1) { next[out] = word[i]; out += 1; }
        for (usz i = 0; i < next_len; i += 1) word[i] = next[i];
        word_len = next_len; rewrites += 1;
        if (rule.kind == 1) { halt = 1; break; }
    }
    usz required = 3 + word_len;
    if (output == null || capacity < required) return -2;
    output[0] = halt; output[1] = (char)rewrites; output[2] = (char)word_len;
    for (usz i = 0; i < word_len; i += 1) output[3 + i] = (char)word[i];
    return (long)required;
}
