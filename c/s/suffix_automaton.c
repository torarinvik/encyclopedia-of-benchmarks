#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 256
#define MAX_QUERIES 128
#define MAX_STATES (2 * MAX_TEXT)
#define MAX_INPUT_LENGTH 33283
#define MAX_VALID_INPUT_LENGTH 33282
#define ALPHABET 128

typedef struct {
    int length;
    int link;
    int next[ALPHABET];
} sam_state;

static void initialize_state(sam_state *states, int index)
{
    states[index].length = 0;
    states[index].link = -1;
    for (int symbol = 0; symbol < ALPHABET; ++symbol) states[index].next[symbol] = -1;
}

static int build_automaton(sam_state *states, const int *text, int text_length)
{
    initialize_state(states, 0);
    int state_count = 1;
    int last = 0;
    for (int position = 0; position < text_length; ++position) {
        int symbol = text[position];
        int current = state_count++;
        initialize_state(states, current);
        states[current].length = states[last].length + 1;
        int previous = last;
        while (previous != -1 && states[previous].next[symbol] == -1) {
            states[previous].next[symbol] = current;
            previous = states[previous].link;
        }
        if (previous == -1) {
            states[current].link = 0;
        } else {
            int next_state = states[previous].next[symbol];
            if (states[previous].length + 1 == states[next_state].length) {
                states[current].link = next_state;
            } else {
                int clone = state_count++;
                initialize_state(states, clone);
                states[clone].length = states[previous].length + 1;
                states[clone].link = states[next_state].link;
                for (int c = 0; c < ALPHABET; ++c) states[clone].next[c] = states[next_state].next[c];
                while (previous != -1 && states[previous].next[symbol] == next_state) {
                    states[previous].next[symbol] = clone;
                    previous = states[previous].link;
                }
                states[next_state].link = clone;
                states[current].link = clone;
            }
        }
        last = current;
    }
    return state_count;
}

static int contains_pattern(const sam_state *states, const int *pattern, int length)
{
    int current = 0;
    for (int i = 0; i < length; ++i) {
        current = states[current].next[pattern[i]];
        if (current == -1) return 0;
    }
    return 1;
}

static int64_t count_occurrences(const sam_state *states, int state_count,
                                 const int *text, int text_length,
                                 const int *pattern, int pattern_length)
{
    int current = 0;
    for (int i = 0; i < pattern_length; ++i) {
        current = states[current].next[pattern[i]];
        if (current == -1) return 0;
    }
    int occurrences[MAX_STATES] = {0};
    int by_length[MAX_TEXT + 1] = {0};
    int order[MAX_STATES];
    for (int state = 0; state < state_count; ++state) ++by_length[states[state].length];
    for (int length = 1; length <= text_length; ++length) by_length[length] += by_length[length - 1];
    for (int state = state_count - 1; state >= 0; --state) order[--by_length[states[state].length]] = state;
    int last = 0;
    for (int i = 0; i < text_length; ++i) {
        last = states[last].next[text[i]];
        occurrences[last] = 1;
    }
    for (int i = state_count - 1; i >= 0; --i) {
        int state = order[i];
        if (states[state].link != -1) occurrences[states[state].link] += occurrences[state];
    }
    return occurrences[current];
}

static int64_t count_distinct_substrings(const sam_state *states, int state_count)
{
    int64_t total = 0;
    for (int state = 1; state < state_count; ++state)
        total += states[state].length - states[states[state].link].length;
    return total;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t suffix_automaton(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_TEXT) return -1;
    int text_length = (int)input[0];
    size_t query_count_index = (size_t)text_length + 1;
    if (length <= query_count_index || input[query_count_index] < 0 || input[query_count_index] > MAX_QUERIES)
        return -1;
    int query_count = (int)input[query_count_index];
    if (length > MAX_VALID_INPUT_LENGTH) return -1;
    int text[MAX_TEXT];
    for (int i = 0; i < text_length; ++i) {
        int64_t symbol = input[(size_t)i + 1];
        if (symbol < 0 || symbol >= ALPHABET) return -1;
        text[i] = (int)symbol;
    }

    sam_state states[MAX_STATES];
    int state_count = build_automaton(states, text, text_length);
    int64_t results[MAX_QUERIES];
    uint8_t opcodes[MAX_QUERIES];
    size_t cursor = query_count_index + 1;
    for (int query = 0; query < query_count; ++query) {
        if (cursor + 1 >= length) return -1;
        int64_t opcode_value = input[cursor++];
        int64_t pattern_length_value = input[cursor++];
        if (opcode_value < 0 || opcode_value > 2 || pattern_length_value < 0 || pattern_length_value > MAX_TEXT)
            return -1;
        int opcode = (int)opcode_value;
        int pattern_length = (int)pattern_length_value;
        if (opcode == 2 && pattern_length != 0) return -1;
        if ((size_t)pattern_length > length - cursor) return -1;
        int pattern[MAX_TEXT];
        for (int i = 0; i < pattern_length; ++i) {
            int64_t symbol = input[cursor++];
            if (symbol < 0 || symbol >= ALPHABET) return -1;
            pattern[i] = (int)symbol;
        }
        opcodes[query] = (uint8_t)opcode;
        if (opcode == 0) results[query] = contains_pattern(states, pattern, pattern_length);
        else if (opcode == 1) results[query] = count_occurrences(states, state_count, text, text_length, pattern, pattern_length);
        else results[query] = count_distinct_substrings(states, state_count);
    }
    if (cursor != length) return -1;
    size_t output_bytes = (size_t)query_count * 9;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int query = 0; query < query_count; ++query) {
        output[(size_t)query * 9] = opcodes[query];
        store_i64_le(output, (size_t)query * 9 + 1, results[query]);
    }
    return (int64_t)output_bytes;
}
