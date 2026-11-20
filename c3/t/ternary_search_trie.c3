module ternary_search_trie;

const usz MAX_OPERATIONS = 64;
const usz MAX_KEY_LENGTH = 6;
const usz RECORD_WIDTH = 9;
const usz MAX_INPUT_VALUES = 577;
const usz MAX_PARSEABLE_INPUT_VALUES = 578;
const usz MAX_NODES = 384;

struct Node {
    long character;
    long left;
    long middle;
    long right;
    long value;
    bool present;
}

fn long put_node(Node* nodes, long node_id, long* key, long length,
                 long depth, long value, long* old_value, long* size,
                 long* node_count) {
    if (node_id == 0) {
        *node_count += 1;
        node_id = *node_count;
        nodes[node_id].character = key[depth];
    }
    if (key[depth] < nodes[node_id].character) {
        nodes[node_id].left = put_node(nodes, nodes[node_id].left, key, length,
                                       depth, value, old_value, size, node_count);
    } else if (key[depth] > nodes[node_id].character) {
        nodes[node_id].right = put_node(nodes, nodes[node_id].right, key, length,
                                        depth, value, old_value, size, node_count);
    } else if (depth + 1 < length) {
        nodes[node_id].middle = put_node(nodes, nodes[node_id].middle, key, length,
                                         depth + 1, value, old_value, size, node_count);
    } else {
        *old_value = nodes[node_id].present ? nodes[node_id].value : 0;
        if (!nodes[node_id].present) *size += 1;
        nodes[node_id].value = value;
        nodes[node_id].present = true;
    }
    node_id
}

fn long find_node(Node* nodes, long node_id, long* key, long length) {
    long depth = 0;
    while (node_id != 0) {
        if (key[depth] < nodes[node_id].character) node_id = nodes[node_id].left;
        else if (key[depth] > nodes[node_id].character) node_id = nodes[node_id].right;
        else if (depth + 1 == length) return node_id;
        else { node_id = nodes[node_id].middle; depth += 1; }
    }
    0
}

fn long delete_node(Node* nodes, long node_id, long* key, long length,
                    long depth, long* removed, long* size) {
    if (node_id == 0) return 0;
    if (key[depth] < nodes[node_id].character) {
        nodes[node_id].left = delete_node(nodes, nodes[node_id].left, key, length,
                                          depth, removed, size);
    } else if (key[depth] > nodes[node_id].character) {
        nodes[node_id].right = delete_node(nodes, nodes[node_id].right, key, length,
                                           depth, removed, size);
    } else if (depth + 1 < length) {
        nodes[node_id].middle = delete_node(nodes, nodes[node_id].middle, key, length,
                                            depth + 1, removed, size);
    } else if (nodes[node_id].present) {
        *removed = nodes[node_id].value;
        nodes[node_id].value = 0;
        nodes[node_id].present = false;
        *size -= 1;
    }
    if (!nodes[node_id].present && nodes[node_id].left == 0 &&
        nodes[node_id].middle == 0 && nodes[node_id].right == 0) return 0;
    node_id
}

fn long count_nodes(Node* nodes, long node_id) {
    if (node_id == 0) return 0;
    (nodes[node_id].present ? 1 : 0) +
        count_nodes(nodes, nodes[node_id].left) +
        count_nodes(nodes, nodes[node_id].middle) +
        count_nodes(nodes, nodes[node_id].right)
}

fn long count_matches(Node* nodes, long node_id, long* pattern,
                      long length, long depth) {
    if (node_id == 0) return 0;
    long token = pattern[depth];
    if (token == '.') {
        long here = depth + 1 == length ?
            (nodes[node_id].present ? 1 : 0) :
            count_matches(nodes, nodes[node_id].middle, pattern, length, depth + 1);
        return count_matches(nodes, nodes[node_id].left, pattern, length, depth) +
               here + count_matches(nodes, nodes[node_id].right, pattern, length, depth);
    }
    if (token < nodes[node_id].character)
        return count_matches(nodes, nodes[node_id].left, pattern, length, depth);
    if (token > nodes[node_id].character)
        return count_matches(nodes, nodes[node_id].right, pattern, length, depth);
    if (depth + 1 == length) return nodes[node_id].present ? 1 : 0;
    count_matches(nodes, nodes[node_id].middle, pattern, length, depth + 1)
}

fn bool valid_input(long* input, usz length, long* operation_count) {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_VALUES) return false;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS.long()) return false;
    *operation_count = input[0];
    if (length != 1 + operation_count.usz() * RECORD_WIDTH) return false;
    for (long operation = 0; operation < *operation_count; operation++) {
        usz base = 1 + operation.usz() * RECORD_WIDTH;
        long opcode = input[base], key_length = input[base + 1];
        if (opcode < 0 || opcode > 6 || key_length < 0 || key_length > MAX_KEY_LENGTH.long())
            return false;
        if ((opcode <= 2 && key_length == 0) || (opcode == 6 && key_length != 0))
            return false;
        for (long index = 0; index < MAX_KEY_LENGTH.long(); index++) {
            long character = input[base + 2 + index.usz()];
            if (index < key_length) {
                if ((character < 'a' || character > 'z') &&
                    !(opcode == 5 && character == '.')) return false;
            } else if (character != 0) return false;
        }
        long value = input[base + RECORD_WIDTH - 1];
        if (opcode == 0) {
            if (value < 1 || value > 65535) return false;
        } else if (value != 0) return false;
    }
    true
}

fn long ternary_search_trie(long* input, usz length) @export("ternary_search_trie") {
    long operation_count = 0;
    if (!valid_input(input, length, &operation_count)) return -1;
    Node[MAX_NODES + 1] nodes;
    for (usz i = 0; i <= MAX_NODES; i++) {
        nodes[i].character = 0; nodes[i].left = 0; nodes[i].middle = 0;
        nodes[i].right = 0; nodes[i].value = 0; nodes[i].present = false;
    }
    long node_count = 0, root = 0, size = 0, total = 0;
    for (long operation = 0; operation < operation_count; operation++) {
        usz base = 1 + operation.usz() * RECORD_WIDTH;
        long opcode = input[base], key_length = input[base + 1];
        long* key = input + base + 2;
        long value = input[base + RECORD_WIDTH - 1], observed = 0;
        if (opcode == 0) {
            root = put_node(nodes, root, key, key_length, 0, value, &observed,
                            &size, &node_count);
        } else if (opcode == 1) {
            long found = find_node(nodes, root, key, key_length);
            if (found != 0 && nodes[found].present) observed = nodes[found].value;
        } else if (opcode == 2) {
            root = delete_node(nodes, root, key, key_length, 0, &observed, &size);
        } else if (opcode == 3) {
            long node_id = root, depth = 0;
            while (node_id != 0 && depth < key_length) {
                if (key[depth] < nodes[node_id].character) node_id = nodes[node_id].left;
                else if (key[depth] > nodes[node_id].character) node_id = nodes[node_id].right;
                else {
                    depth += 1;
                    if (nodes[node_id].present) observed = depth;
                    node_id = nodes[node_id].middle;
                }
            }
        } else if (opcode == 4) {
            if (key_length == 0) observed = size;
            else {
                long found = find_node(nodes, root, key, key_length);
                if (found != 0)
                    observed = (nodes[found].present ? 1 : 0) +
                               count_nodes(nodes, nodes[found].middle);
            }
        } else if (opcode == 5 && key_length != 0) {
            observed = count_matches(nodes, root, key, key_length, 0);
        } else if (opcode == 6) observed = size;
        total += (operation + 1) * observed;
    }
    total
}
