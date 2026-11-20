#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_OPERATIONS = 64;
constexpr int MAX_KEY_LENGTH = 6;
constexpr int RECORD_WIDTH = 9;
constexpr std::size_t MAX_INPUT_VALUES = 577;
constexpr std::size_t MAX_PARSEABLE_INPUT_VALUES = 578;
constexpr int MAX_NODES = 384;

struct Node {
    int character = 0;
    int left = 0;
    int middle = 0;
    int right = 0;
    std::int64_t value = 0;
    bool present = false;
};

int put_node(Node* nodes, int node_id, const std::int64_t* key, int length,
             int depth, std::int64_t value, std::int64_t& old_value,
             int& size, int& node_count) {
    if (node_id == 0) {
        node_id = ++node_count;
        nodes[node_id].character = static_cast<int>(key[depth]);
    }
    Node& node = nodes[node_id];
    if (key[depth] < node.character) {
        node.left = put_node(nodes, node.left, key, length, depth, value,
                             old_value, size, node_count);
    } else if (key[depth] > node.character) {
        node.right = put_node(nodes, node.right, key, length, depth, value,
                              old_value, size, node_count);
    } else if (depth + 1 < length) {
        node.middle = put_node(nodes, node.middle, key, length, depth + 1,
                               value, old_value, size, node_count);
    } else {
        old_value = node.present ? node.value : 0;
        if (!node.present) ++size;
        node.value = value;
        node.present = true;
    }
    return node_id;
}

int find_node(const Node* nodes, int node_id, const std::int64_t* key, int length) {
    int depth = 0;
    while (node_id != 0) {
        const Node& node = nodes[node_id];
        if (key[depth] < node.character) node_id = node.left;
        else if (key[depth] > node.character) node_id = node.right;
        else if (depth + 1 == length) return node_id;
        else { node_id = node.middle; ++depth; }
    }
    return 0;
}

int delete_node(Node* nodes, int node_id, const std::int64_t* key, int length,
                int depth, std::int64_t& removed, int& size) {
    if (node_id == 0) return 0;
    Node& node = nodes[node_id];
    if (key[depth] < node.character) {
        node.left = delete_node(nodes, node.left, key, length, depth, removed, size);
    } else if (key[depth] > node.character) {
        node.right = delete_node(nodes, node.right, key, length, depth, removed, size);
    } else if (depth + 1 < length) {
        node.middle = delete_node(nodes, node.middle, key, length, depth + 1,
                                  removed, size);
    } else if (node.present) {
        removed = node.value;
        node.value = 0;
        node.present = false;
        --size;
    }
    if (!node.present && node.left == 0 && node.middle == 0 && node.right == 0)
        return 0;
    return node_id;
}

int count_nodes(const Node* nodes, int node_id) {
    if (node_id == 0) return 0;
    const Node& node = nodes[node_id];
    return static_cast<int>(node.present) + count_nodes(nodes, node.left) +
           count_nodes(nodes, node.middle) + count_nodes(nodes, node.right);
}

int count_matches(const Node* nodes, int node_id, const std::int64_t* pattern,
                  int length, int depth) {
    if (node_id == 0) return 0;
    const Node& node = nodes[node_id];
    const int token = static_cast<int>(pattern[depth]);
    if (token == '.') {
        const int here = depth + 1 == length ? static_cast<int>(node.present) :
                         count_matches(nodes, node.middle, pattern, length, depth + 1);
        return count_matches(nodes, node.left, pattern, length, depth) + here +
               count_matches(nodes, node.right, pattern, length, depth);
    }
    if (token < node.character)
        return count_matches(nodes, node.left, pattern, length, depth);
    if (token > node.character)
        return count_matches(nodes, node.right, pattern, length, depth);
    if (depth + 1 == length) return static_cast<int>(node.present);
    return count_matches(nodes, node.middle, pattern, length, depth + 1);
}

bool valid_input(const std::int64_t* input, std::size_t length, int& operation_count) {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_INPUT_VALUES) return false;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return false;
    operation_count = static_cast<int>(input[0]);
    if (length != 1 + static_cast<std::size_t>(operation_count) * RECORD_WIDTH)
        return false;
    for (int operation = 0; operation < operation_count; ++operation) {
        const std::size_t base = 1 + static_cast<std::size_t>(operation) * RECORD_WIDTH;
        const std::int64_t opcode = input[base];
        const std::int64_t key_length = input[base + 1];
        if (opcode < 0 || opcode > 6 || key_length < 0 ||
            key_length > MAX_KEY_LENGTH) return false;
        if ((opcode <= 2 && key_length == 0) || (opcode == 6 && key_length != 0))
            return false;
        for (int index = 0; index < MAX_KEY_LENGTH; ++index) {
            const std::int64_t character = input[base + 2 + index];
            if (index < key_length) {
                if ((character < 'a' || character > 'z') &&
                    !(opcode == 5 && character == '.')) return false;
            } else if (character != 0) return false;
        }
        const std::int64_t value = input[base + RECORD_WIDTH - 1];
        if (opcode == 0) {
            if (value < 1 || value > 65535) return false;
        } else if (value != 0) return false;
    }
    return true;
}
} // namespace

extern "C" std::int64_t ternary_search_trie(const std::int64_t* input,
                                             std::size_t length) {
    int operation_count = 0;
    if (!valid_input(input, length, operation_count)) return -1;
    Node nodes[MAX_NODES + 1]{};
    int node_count = 0;
    int root = 0;
    int size = 0;
    std::int64_t total = 0;

    for (int operation = 0; operation < operation_count; ++operation) {
        const std::size_t base = 1 + static_cast<std::size_t>(operation) * RECORD_WIDTH;
        const int opcode = static_cast<int>(input[base]);
        const int key_length = static_cast<int>(input[base + 1]);
        const std::int64_t* key = input + base + 2;
        const std::int64_t value = input[base + RECORD_WIDTH - 1];
        std::int64_t observed = 0;

        if (opcode == 0) {
            root = put_node(nodes, root, key, key_length, 0, value, observed,
                            size, node_count);
        } else if (opcode == 1) {
            const int found = find_node(nodes, root, key, key_length);
            if (found != 0 && nodes[found].present) observed = nodes[found].value;
        } else if (opcode == 2) {
            root = delete_node(nodes, root, key, key_length, 0, observed, size);
        } else if (opcode == 3) {
            int node_id = root;
            int depth = 0;
            while (node_id != 0 && depth < key_length) {
                const Node& node = nodes[node_id];
                if (key[depth] < node.character) node_id = node.left;
                else if (key[depth] > node.character) node_id = node.right;
                else {
                    ++depth;
                    if (node.present) observed = depth;
                    node_id = node.middle;
                }
            }
        } else if (opcode == 4) {
            if (key_length == 0) observed = size;
            else {
                const int found = find_node(nodes, root, key, key_length);
                if (found != 0)
                    observed = static_cast<int>(nodes[found].present) +
                               count_nodes(nodes, nodes[found].middle);
            }
        } else if (opcode == 5 && key_length != 0) {
            observed = count_matches(nodes, root, key, key_length, 0);
        } else if (opcode == 6) {
            observed = size;
        }
        total += static_cast<std::int64_t>(operation + 1) * observed;
    }
    return total;
}
