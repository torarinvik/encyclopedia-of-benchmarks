module palindromes_in_deque;

const usz MAX_QUERIES = 32;
const usz MAX_TEXT = 32;
const usz MAX_NODES = MAX_TEXT + 2;
const usz ALPHABET = 26;

struct EertreeNode { int length; int link; int[ALPHABET] next; }

fn int extendable(EertreeNode* nodes, int* text, int position, int node) {
    while (true) {
        int preceding = position - nodes[node].length - 1;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].link;
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long palindromes_in_deque(long* input, usz length, char* output, usz capacity)
    @export("palindromes_in_deque") {
    if (input == null || length < 1 || length > 1 + 2 * MAX_QUERIES) return -1;
    long query_value = input[0];
    if (query_value < 1 || query_value > (long)MAX_QUERIES) return -1;
    usz queries = (usz)query_value;
    if (length != 1 + 2 * queries) return -1;

    int size = 0;
    for (usz query = 0; query < queries; query += 1) {
        long operation = input[1 + 2 * query];
        long letter = input[2 + 2 * query];
        if (operation == 0 || operation == 1) {
            if (letter < 0 || letter >= (long)ALPHABET) return -1;
            size += 1;
        } else if (operation == 2 || operation == 3) {
            if (letter != 0 || size == 0) return -1;
            size -= 1;
        } else {
            return -1;
        }
    }
    if (output == null || capacity < 24 * queries) return -2;

    int[MAX_TEXT] text;
    size = 0;
    for (usz query = 0; query < queries; query += 1) {
        int operation = (int)input[1 + 2 * query];
        int letter = (int)input[2 + 2 * query];
        if (operation == 0) {
            for (int index = size; index > 0; index -= 1) text[index] = text[index - 1];
            text[0] = letter;
            size += 1;
        } else if (operation == 1) {
            text[size] = letter;
            size += 1;
        } else if (operation == 2) {
            for (int index = 1; index < size; index += 1) text[index - 1] = text[index];
            size -= 1;
        } else {
            size -= 1;
        }

        EertreeNode[MAX_NODES] nodes;
        for (int node = 0; node < (int)MAX_NODES; node += 1) {
            nodes[node].length = 0;
            nodes[node].link = 0;
            for (int letter_index = 0; letter_index < (int)ALPHABET; letter_index += 1)
                nodes[node].next[letter_index] = -1;
        }
        nodes[0].length = -1;
        int node_count = 2;
        int last = 1;
        long longest_prefix = 0;
        for (int position = 0; position < size; position += 1) {
            int character = text[position];
            int parent = extendable(&nodes[0], &text[0], position, last);
            int next = nodes[parent].next[character];
            if (next < 0) {
                next = node_count;
                node_count += 1;
                nodes[next].length = nodes[parent].length + 2;
                if (nodes[next].length == 1) {
                    nodes[next].link = 1;
                } else {
                    int suffix_parent = extendable(&nodes[0], &text[0], position,
                                                   nodes[parent].link);
                    nodes[next].link = nodes[suffix_parent].next[character];
                }
                nodes[parent].next[character] = next;
            }
            last = next;
            if (nodes[last].length == position + 1) longest_prefix = position + 1;
        }
        usz offset = 24 * query;
        store_i64_le(output, offset, (long)(node_count - 2));
        store_i64_le(output, offset + 8, longest_prefix);
        store_i64_le(output, offset + 16, (long)nodes[last].length);
    }
    return (long)(24 * queries);
}
