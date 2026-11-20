#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_strings = 16;
constexpr int max_string_length = 8;
constexpr int max_nodes = 129;
constexpr int threshold = 3;
constexpr std::size_t max_input_length = 145;

struct BurstNode {
    int depth = 0;
    bool burst = false;
    int leaf_count = 0;
    int terminal_count = 0;
    int children[4] = {-1, -1, -1, -1};
    int leaf_items[threshold]{};
    int terminal_items[max_strings]{};
};

int new_node(BurstNode *nodes, int &used, int depth) noexcept {
    if (used >= max_nodes) return -1;
    const int id = used++;
    nodes[id] = BurstNode{};
    nodes[id].depth = depth;
    return id;
}

bool insert(BurstNode *nodes, int &used, int node_id, int depth, int item,
            const int *string_lengths, const int *string_bytes) noexcept {
    if (string_lengths[item] == depth) {
        if (nodes[node_id].terminal_count >= max_strings) return false;
        nodes[node_id].terminal_items[nodes[node_id].terminal_count++] = item;
        return true;
    }

    if (!nodes[node_id].burst && nodes[node_id].leaf_count < threshold) {
        nodes[node_id].leaf_items[nodes[node_id].leaf_count++] = item;
        return true;
    }

    if (!nodes[node_id].burst) {
        int saved[threshold];
        const int saved_count = nodes[node_id].leaf_count;
        for (int i = 0; i < saved_count; ++i) saved[i] = nodes[node_id].leaf_items[i];
        nodes[node_id].leaf_count = 0;
        nodes[node_id].burst = true;
        for (int i = 0; i < saved_count; ++i) {
            if (!insert(nodes, used, node_id, depth, saved[i], string_lengths,
                        string_bytes)) return false;
        }
    }

    const int key = string_bytes[item * max_string_length + depth];
    if (nodes[node_id].children[key] < 0) {
        const int child = new_node(nodes, used, depth + 1);
        if (child < 0) return false;
        nodes[node_id].children[key] = child;
    }
    return insert(nodes, used, nodes[node_id].children[key], depth + 1,
                  item, string_lengths, string_bytes);
}

bool string_less(int left, int right, const int *string_lengths,
                 const int *string_bytes) noexcept {
    const int left_length = string_lengths[left];
    const int right_length = string_lengths[right];
    const int common = left_length < right_length ? left_length : right_length;
    for (int i = 0; i < common; ++i) {
        const int a = string_bytes[left * max_string_length + i];
        const int b = string_bytes[right * max_string_length + i];
        if (a != b) return a < b;
    }
    return left_length < right_length;
}

void emit(const BurstNode *nodes, int node_id, int *output, int &output_count,
          const int *string_lengths, const int *string_bytes) noexcept {
    const BurstNode &node = nodes[node_id];
    for (int i = 0; i < node.terminal_count; ++i)
        output[output_count++] = node.terminal_items[i];

    if (node.burst) {
        for (int key = 0; key < 4; ++key) {
            if (node.children[key] >= 0)
                emit(nodes, node.children[key], output, output_count,
                     string_lengths, string_bytes);
        }
        return;
    }

    int ordered[threshold];
    for (int i = 0; i < node.leaf_count; ++i) ordered[i] = node.leaf_items[i];
    for (int i = 1; i < node.leaf_count; ++i) {
        const int item = ordered[i];
        int position = i;
        while (position > 0 && string_less(item, ordered[position - 1],
                                           string_lengths, string_bytes)) {
            ordered[position] = ordered[position - 1];
            --position;
        }
        ordered[position] = item;
    }
    for (int i = 0; i < node.leaf_count; ++i) output[output_count++] = ordered[i];
}
} // namespace

extern "C" std::int64_t burstsort(const std::int64_t *input,
                                  std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > max_strings) return -1;
    const int count = static_cast<int>(input[0]);
    int string_lengths[max_strings]{};
    int string_bytes[max_strings * max_string_length]{};

    std::size_t cursor = 1;
    for (int item = 0; item < count; ++item) {
        if (cursor >= length) return -1;
        const std::int64_t raw_length = input[cursor++];
        if (raw_length < 0 || raw_length > max_string_length) return -1;
        const int string_length = static_cast<int>(raw_length);
        if (static_cast<std::size_t>(string_length) > length - cursor) return -1;
        string_lengths[item] = string_length;
        for (int j = 0; j < string_length; ++j) {
            const std::int64_t byte = input[cursor++];
            if (byte < 0 || byte > 3) return -1;
            string_bytes[item * max_string_length + j] = static_cast<int>(byte);
        }
    }
    if (cursor != length) return -1;

    BurstNode nodes[max_nodes]{};
    int used = 0;
    const int root = new_node(nodes, used, 0);
    if (root < 0) return -1;
    for (int item = 0; item < count; ++item) {
        if (!insert(nodes, used, root, 0, item, string_lengths, string_bytes)) return -1;
    }

    int sorted[max_strings]{};
    int sorted_count = 0;
    emit(nodes, root, sorted, sorted_count, string_lengths, string_bytes);
    if (sorted_count != count) return -1;

    constexpr std::int64_t powers[8] = {78125, 15625, 3125, 625, 125, 25, 5, 1};
    std::int64_t checksum = 0;
    for (int rank = 0; rank < count; ++rank) {
        const int item = sorted[rank];
        std::int64_t key = 0;
        for (int j = 0; j < string_lengths[item]; ++j) {
            key += static_cast<std::int64_t>(
                       string_bytes[item * max_string_length + j] + 1) * powers[j];
        }
        checksum += static_cast<std::int64_t>(rank + 1) * key;
    }
    return checksum;
}
