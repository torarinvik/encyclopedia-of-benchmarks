module generalized_suffix_automaton_union;

const int MAX_STRINGS = 8;
const int MAX_TOTAL_BYTES = 24;
const int MAX_TRIE_NODES = 25;
const int MAX_STATES = 2 * MAX_TRIE_NODES - 1;
const int ALPHABET = 4;
const usz MAX_INPUT_LENGTH = 34;

fn long generalized_suffix_automaton_union(long* input, usz length) @export("generalized_suffix_automaton_union") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_STRINGS) return -1;
    int string_count = (int)input[0];

    long[MAX_STATES] state_length = zeroed;
    long[MAX_STATES] state_link;
    long[MAX_STATES][ALPHABET] transitions = zeroed;
    long[MAX_TRIE_NODES][ALPHABET] trie_next = zeroed;
    long[MAX_TRIE_NODES] trie_parent = zeroed;
    long[MAX_TRIE_NODES] trie_symbol = zeroed;
    for (int state = 0; state < MAX_STATES; state++) state_link[state] = -1;

    int trie_node_count = 1;
    int total_bytes = 0;
    usz cursor = 1;
    for (int string_index = 0; string_index < string_count; string_index++) {
        if (cursor >= length) return -1;
        long string_length_value = input[cursor++];
        if (string_length_value < 0 || string_length_value > 8) return -1;
        int string_length = (int)string_length_value;
        if (total_bytes + string_length > MAX_TOTAL_BYTES || (usz)string_length > length - cursor)
            return -1;
        total_bytes += string_length;

        int node = 0;
        for (int offset = 0; offset < string_length; offset++) {
            long symbol_value = input[cursor + (usz)offset];
            if (symbol_value < 0 || symbol_value >= ALPHABET) return -1;
            int symbol = (int)symbol_value;
            int child = (int)trie_next[node][symbol];
            if (child == 0) {
                child = trie_node_count++;
                trie_next[node][symbol] = child;
                transitions[node][symbol] = child;
                trie_parent[child] = node;
                trie_symbol[child] = symbol;
            }
            node = child;
        }
        cursor += (usz)string_length;
    }
    if (cursor != length) return -1;

    int state_count = trie_node_count;
    int[MAX_TRIE_NODES] queue = zeroed;
    int queue_head = 0;
    int queue_tail = 0;
    for (int symbol = 0; symbol < ALPHABET; symbol++) {
        int child = (int)trie_next[0][symbol];
        if (child != 0) queue[queue_tail++] = child;
    }

    while (queue_head < queue_tail) {
        int current = queue[queue_head++];
        int parent = (int)trie_parent[current];
        int symbol = (int)trie_symbol[current];
        state_length[current] = state_length[parent] + 1;

        int previous = (int)state_link[parent];
        while (previous != -1 && transitions[previous][symbol] == 0) {
            transitions[previous][symbol] = current;
            previous = (int)state_link[previous];
        }
        if (previous == -1) {
            state_link[current] = 0;
        } else {
            int next_state = (int)transitions[previous][symbol];
            if (state_length[previous] + 1 == state_length[next_state]) {
                state_link[current] = next_state;
            } else {
                if (state_count >= MAX_STATES) return -1;
                int clone = state_count++;
                state_length[clone] = state_length[previous] + 1;
                state_link[clone] = state_link[next_state];
                for (int character = 0; character < ALPHABET; character++) {
                    int destination = (int)transitions[next_state][character];
                    transitions[clone][character] =
                        destination != 0 && state_length[destination] > 0 ? destination : 0;
                }
                while (previous != -1 && transitions[previous][symbol] == next_state) {
                    transitions[previous][symbol] = clone;
                    previous = (int)state_link[previous];
                }
                state_link[current] = clone;
                state_link[next_state] = clone;
            }
        }

        for (int character = 0; character < ALPHABET; character++) {
            int child = (int)trie_next[current][character];
            if (child != 0) queue[queue_tail++] = child;
        }
    }

    long distinct_count = 0;
    for (int state = 1; state < state_count; state++)
        distinct_count += state_length[state] - state_length[(int)state_link[state]];
    return distinct_count;
}
