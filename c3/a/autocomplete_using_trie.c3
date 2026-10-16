module autocomplete_using_trie;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const usz MAX_WORDS = 32;
const usz MAX_LEN = 16;
const usz MAX_QUERIES = 16;
const usz MAX_NODES = 513;
const usz MAX_OUTPUT_WORDS = 8721;

struct Node {
    int[26] child;
    bool terminal;
}

fn void init_node(Node* node) {
    for (usz c = 0; c < 26; c++) node.child[c] = -1;
    node.terminal = false;
}

fn void collect(Node* nodes, int node, int* path, int depth, long* output,
                usz* used, usz* count) {
    if (nodes[node].terminal) {
        output[*used] = depth;
        *used += 1;
        for (int index = 0; index < depth; index++) {
            output[*used] = (long)('a' + path[index]);
            *used += 1;
        }
        *count += 1;
    }
    for (int character = 0; character < 26; character++) {
        int child = nodes[node].child[character];
        if (child >= 0) {
            path[depth] = character;
            collect(nodes, child, path, depth + 1, output, used, count);
        }
    }
}

fn void put_i64(char* output, usz index, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[index * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long autocomplete_using_trie(long* input, usz length, char* output,
                                usz capacity) @export("autocomplete_using_trie") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_WORDS) return -1;

    Node[MAX_NODES] nodes;
    init_node(&nodes[0]);
    int node_count = 1;
    usz position = 1;
    for (usz word = 0; word < (usz)input[0]; word++) {
        if (position >= length) return -1;
        long word_length = input[position];
        position += 1;
        if (word_length < 1 || word_length > (long)MAX_LEN ||
            position + (usz)word_length > length) return -1;
        int node = 0;
        for (usz index = 0; index < (usz)word_length; index++) {
            long character = input[position];
            position += 1;
            if (character < 'a' || character > 'z') return -1;
            int child_index = (int)(character - 'a');
            if (nodes[node].child[child_index] < 0) {
                if ((usz)node_count >= MAX_NODES) return -1;
                init_node(&nodes[node_count]);
                nodes[node].child[child_index] = node_count;
                node_count += 1;
            }
            node = nodes[node].child[child_index];
        }
        nodes[node].terminal = true;
    }

    if (position >= length) return -1;
    long query_count_value = input[position];
    position += 1;
    if (query_count_value < 0 || query_count_value > (long)MAX_QUERIES) return -1;
    usz query_count = (usz)query_count_value;
    usz[MAX_QUERIES] query_positions;
    usz[MAX_QUERIES] query_lengths;
    for (usz query = 0; query < query_count; query++) {
        if (position >= length) return -1;
        long prefix_length = input[position];
        position += 1;
        if (prefix_length < 0 || prefix_length > (long)MAX_LEN ||
            position + (usz)prefix_length > length) return -1;
        query_positions[query] = position;
        query_lengths[query] = (usz)prefix_length;
        for (usz index = 0; index < (usz)prefix_length; index++) {
            long character = input[position + index];
            if (character < 'a' || character > 'z') return -1;
        }
        position += (usz)prefix_length;
    }
    if (position != length) return -1;

    long* values = (long*)malloc(MAX_OUTPUT_WORDS * 8);
    if (values == null) return -3;
    defer free(values);
    usz used = 0;
    values[used] = (long)query_count;
    used += 1;
    for (usz query = 0; query < query_count; query++) {
        int node = 0;
        int[MAX_LEN] path;
        bool found = true;
        for (usz index = 0; index < query_lengths[query]; index++) {
            int child_index = (int)(input[query_positions[query] + index] - 'a');
            path[index] = child_index;
            if (nodes[node].child[child_index] < 0) {
                found = false;
                break;
            }
            node = nodes[node].child[child_index];
        }
        usz count_position = used;
        used += 1;
        usz completion_count = 0;
        if (found) {
            collect(&nodes[0], node, &path[0], (int)query_lengths[query],
                    &values[0], &used, &completion_count);
        }
        values[count_position] = (long)completion_count;
    }

    usz required = used * 8;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < used; index++) put_i64(output, index, values[index]);
    return (long)required;
}
