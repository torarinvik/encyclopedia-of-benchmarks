#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_input_length = 193;
constexpr int max_nodes = 1024;
constexpr int max_heap_size = 128;
constexpr std::int64_t empty_rank = 20001;

struct PlhNode {
    std::int64_t key;
    int left;
    int right;
    int npl;
};

int allocate_node(PlhNode nodes[max_nodes], int& used, std::int64_t key,
                  int left, int right, int npl) noexcept {
    if (used >= max_nodes) return -1;
    const int node = used++;
    nodes[node] = {key, left, right, npl};
    return node;
}

int meld(PlhNode nodes[max_nodes], int& used, int left_root, int right_root) noexcept {
    if (left_root < 0 || right_root < 0) return -1;
    if (left_root == 0) return right_root;
    if (right_root == 0) return left_root;
    if (nodes[left_root].key > nodes[right_root].key) {
        const int temporary = left_root;
        left_root = right_root;
        right_root = temporary;
    }

    const PlhNode winner = nodes[left_root];
    const int copy = allocate_node(nodes, used, winner.key, winner.left, winner.right, winner.npl);
    if (copy < 0) return -1;
    const int merged_right = meld(nodes, used, winner.right, right_root);
    if (merged_right < 0) return -1;
    nodes[copy].right = merged_right;
    if (nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl) {
        const int temporary = nodes[copy].left;
        nodes[copy].left = nodes[copy].right;
        nodes[copy].right = temporary;
    }
    nodes[copy].npl = nodes[nodes[copy].right].npl + 1;
    return copy;
}
} // namespace

extern "C" std::int64_t persistent_leftist_heap(const std::int64_t *input,
                                                  std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(raw_operations);

    PlhNode nodes[max_nodes]{};
    nodes[0].npl = -1;
    int used = 1;
    int roots[max_operations + 1]{};
    int sizes[max_operations + 1]{};
    std::int64_t observation_sum = 0;
    std::int64_t observation_xor = 0;
    std::size_t cursor = 1;

    for (std::size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        if (cursor >= length) return -1;
        const std::int64_t operation = input[cursor++];
        std::int64_t first;
        std::int64_t second = 0;
        if (operation == 0 || operation == 1) {
            if (length - cursor < 2) return -1;
            first = input[cursor++];
            second = input[cursor++];
        } else if (operation == 2 || operation == 3) {
            if (length - cursor < 1) return -1;
            first = input[cursor++];
        } else {
            return -1;
        }

        int new_root = 0;
        int new_size = 0;
        if (operation == 0) {
            if (first < 0 || first > static_cast<std::int64_t>(operation_index) ||
                second < -10000 || second > 10000) return -1;
            const int base = static_cast<int>(first);
            if (sizes[base] >= max_heap_size) return -1;
            const int singleton = allocate_node(nodes, used, second, 0, 0, 0);
            if (singleton < 0) return -1;
            new_root = meld(nodes, used, roots[base], singleton);
            if (new_root < 0) return -1;
            new_size = sizes[base] + 1;
        } else if (operation == 1) {
            if (first < 0 || first > static_cast<std::int64_t>(operation_index) ||
                second < 0 || second > static_cast<std::int64_t>(operation_index)) return -1;
            const int left_version = static_cast<int>(first);
            const int right_version = static_cast<int>(second);
            new_size = sizes[left_version] + sizes[right_version];
            if (new_size > max_heap_size) return -1;
            new_root = meld(nodes, used, roots[left_version], roots[right_version]);
            if (new_root < 0) return -1;
        } else {
            if (first < 0 || first > static_cast<std::int64_t>(operation_index)) return -1;
            const int version = static_cast<int>(first);
            const int root = roots[version];
            const std::int64_t rank = root == 0 ? empty_rank : nodes[root].key + 10000;
            observation_sum += rank;
            observation_xor ^= rank;
            if (operation == 3) {
                new_root = root;
                new_size = sizes[version];
            } else if (root != 0) {
                new_root = meld(nodes, used, nodes[root].left, nodes[root].right);
                if (new_root < 0) return -1;
                new_size = sizes[version] - 1;
            }
        }

        if (new_size > max_heap_size) return -1;
        roots[operation_index + 1] = new_root;
        sizes[operation_index + 1] = new_size;
    }
    if (cursor != length) return -1;
    return (observation_sum << 15) | observation_xor;
}
