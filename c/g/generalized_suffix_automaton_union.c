#include <stddef.h>
#include <stdint.h>

#define MAX_STRINGS 8
#define MAX_TOTAL_BYTES 24
#define MAX_TRIE_NODES (MAX_TOTAL_BYTES + 1)
#define MAX_STATES (2 * MAX_TRIE_NODES - 1)
#define ALPHABET 4
#define MAX_INPUT_LENGTH 34

typedef struct {
    int length;
    int link;
    int next[ALPHABET];
} gsa_state;

int64_t generalized_suffix_automaton_union(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_STRINGS) return -1;
    const int string_count = (int)input[0];

    gsa_state states[MAX_STATES] = {0};
    int trie_next[MAX_TRIE_NODES][ALPHABET] = {{0}};
    int trie_parent[MAX_TRIE_NODES] = {0};
    int trie_symbol[MAX_TRIE_NODES] = {0};
    for (int state = 0; state < MAX_STATES; ++state) states[state].link = -1;

    int trie_node_count = 1;
    int total_bytes = 0;
    size_t cursor = 1;
    for (int string_index = 0; string_index < string_count; ++string_index) {
        if (cursor >= length) return -1;
        const int64_t string_length_value = input[cursor++];
        if (string_length_value < 0 || string_length_value > 8) return -1;
        const int string_length = (int)string_length_value;
        if (total_bytes + string_length > MAX_TOTAL_BYTES || (size_t)string_length > length - cursor)
            return -1;
        total_bytes += string_length;

        int node = 0;
        for (int offset = 0; offset < string_length; ++offset) {
            const int64_t symbol_value = input[cursor + (size_t)offset];
            if (symbol_value < 0 || symbol_value >= ALPHABET) return -1;
            const int symbol = (int)symbol_value;
            int child = trie_next[node][symbol];
            if (child == 0) {
                child = trie_node_count++;
                trie_next[node][symbol] = child;
                states[node].next[symbol] = child;
                trie_parent[child] = node;
                trie_symbol[child] = symbol;
            }
            node = child;
        }
        cursor += (size_t)string_length;
    }
    if (cursor != length) return -1;

    int state_count = trie_node_count;
    int queue[MAX_TRIE_NODES] = {0};
    int queue_head = 0;
    int queue_tail = 0;
    for (int symbol = 0; symbol < ALPHABET; ++symbol) {
        const int child = trie_next[0][symbol];
        if (child != 0) queue[queue_tail++] = child;
    }

    while (queue_head < queue_tail) {
        const int current = queue[queue_head++];
        const int parent = trie_parent[current];
        const int symbol = trie_symbol[current];
        states[current].length = states[parent].length + 1;

        int previous = states[parent].link;
        while (previous != -1 && states[previous].next[symbol] == 0) {
            states[previous].next[symbol] = current;
            previous = states[previous].link;
        }
        if (previous == -1) {
            states[current].link = 0;
        } else {
            const int next_state = states[previous].next[symbol];
            if (states[previous].length + 1 == states[next_state].length) {
                states[current].link = next_state;
            } else {
                if (state_count >= MAX_STATES) return -1;
                const int clone = state_count++;
                states[clone].length = states[previous].length + 1;
                states[clone].link = states[next_state].link;
                for (int character = 0; character < ALPHABET; ++character) {
                    const int destination = states[next_state].next[character];
                    states[clone].next[character] =
                        destination != 0 && states[destination].length > 0 ? destination : 0;
                }
                while (previous != -1 && states[previous].next[symbol] == next_state) {
                    states[previous].next[symbol] = clone;
                    previous = states[previous].link;
                }
                states[current].link = clone;
                states[next_state].link = clone;
            }
        }

        for (int character = 0; character < ALPHABET; ++character) {
            const int child = trie_next[current][character];
            if (child != 0) queue[queue_tail++] = child;
        }
    }

    int64_t distinct_count = 0;
    for (int state = 1; state < state_count; ++state)
        distinct_count += states[state].length - states[states[state].link].length;
    return distinct_count;
}
