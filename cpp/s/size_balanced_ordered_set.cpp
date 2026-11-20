#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_operations = 128;
constexpr int max_nodes = 128;
constexpr std::int64_t missing = -1025;

struct SbtTree {
    std::int64_t key[max_nodes + 1]{};
    int size[max_nodes + 1]{};
    int left[max_nodes + 1]{};
    int right[max_nodes + 1]{};
    int used = 0;
};

int subtree_size(const SbtTree& tree, int node) noexcept {
    return node == 0 ? 0 : tree.size[node];
}

void update_size(SbtTree& tree, int node) noexcept {
    tree.size[node] = subtree_size(tree, tree.left[node])
                    + subtree_size(tree, tree.right[node]) + 1;
}

int rotate_left(SbtTree& tree, int root) noexcept {
    const int pivot = tree.right[root];
    tree.right[root] = tree.left[pivot];
    tree.left[pivot] = root;
    update_size(tree, root);
    update_size(tree, pivot);
    return pivot;
}

int rotate_right(SbtTree& tree, int root) noexcept {
    const int pivot = tree.left[root];
    tree.left[root] = tree.right[pivot];
    tree.right[pivot] = root;
    update_size(tree, root);
    update_size(tree, pivot);
    return pivot;
}

int maintain(SbtTree& tree, int root) noexcept {
    if (root == 0) return 0;

    const int left = tree.left[root];
    const int right = tree.right[root];
    if (subtree_size(tree, left) < subtree_size(tree, tree.left[right])) {
        tree.right[root] = rotate_right(tree, right);
        root = rotate_left(tree, root);
        tree.left[root] = maintain(tree, tree.left[root]);
        tree.right[root] = maintain(tree, tree.right[root]);
        return maintain(tree, root);
    }
    if (subtree_size(tree, left) < subtree_size(tree, tree.right[right])) {
        root = rotate_left(tree, root);
        tree.left[root] = maintain(tree, tree.left[root]);
        return maintain(tree, root);
    }
    if (subtree_size(tree, right) < subtree_size(tree, tree.left[left])) {
        root = rotate_right(tree, root);
        tree.right[root] = maintain(tree, tree.right[root]);
        return maintain(tree, root);
    }
    if (subtree_size(tree, right) < subtree_size(tree, tree.right[left])) {
        tree.left[root] = rotate_left(tree, left);
        root = rotate_right(tree, root);
        tree.left[root] = maintain(tree, tree.left[root]);
        tree.right[root] = maintain(tree, tree.right[root]);
        return maintain(tree, root);
    }
    return root;
}

bool contains(const SbtTree& tree, int root, std::int64_t key) noexcept {
    while (root != 0) {
        if (key < tree.key[root]) root = tree.left[root];
        else if (key > tree.key[root]) root = tree.right[root];
        else return true;
    }
    return false;
}

int insert_new(SbtTree& tree, int root, std::int64_t key) noexcept {
    if (root == 0) {
        const int node = ++tree.used;
        tree.key[node] = key;
        tree.size[node] = 1;
        return node;
    }
    if (key < tree.key[root]) tree.left[root] = insert_new(tree, tree.left[root], key);
    else tree.right[root] = insert_new(tree, tree.right[root], key);
    update_size(tree, root);
    return maintain(tree, root);
}

std::int64_t rank_less(const SbtTree& tree, int root, std::int64_t key) noexcept {
    std::int64_t rank = 0;
    while (root != 0) {
        if (key <= tree.key[root]) root = tree.left[root];
        else {
            rank += subtree_size(tree, tree.left[root]) + 1;
            root = tree.right[root];
        }
    }
    return rank;
}

std::int64_t kth(const SbtTree& tree, int root, std::int64_t index) noexcept {
    if (index < 0 || index >= subtree_size(tree, root)) return missing;
    while (root != 0) {
        const int left_size = subtree_size(tree, tree.left[root]);
        if (index == left_size) return tree.key[root];
        if (index < left_size) root = tree.left[root];
        else {
            index -= left_size + 1;
            root = tree.right[root];
        }
    }
    return missing;
}

std::int64_t predecessor(const SbtTree& tree, int root, std::int64_t key) noexcept {
    std::int64_t answer = missing;
    while (root != 0) {
        if (tree.key[root] < key) {
            answer = tree.key[root];
            root = tree.right[root];
        } else root = tree.left[root];
    }
    return answer;
}

std::int64_t successor(const SbtTree& tree, int root, std::int64_t key) noexcept {
    std::int64_t answer = missing;
    while (root != 0) {
        if (tree.key[root] > key) {
            answer = tree.key[root];
            root = tree.left[root];
        } else root = tree.right[root];
    }
    return answer;
}
} // namespace

extern "C" std::int64_t size_balanced_ordered_set(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 1 + 2 * max_operations) return -1;
    const std::int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > max_operations) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != 1 + 2 * operation_count) return -1;

    for (std::size_t i = 0; i < operation_count; ++i) {
        const std::int64_t operation = input[1 + 2 * i];
        const std::int64_t argument = input[2 + 2 * i];
        if (operation < 0 || operation > 4) return -1;
        if (operation == 2) {
            if (argument < 0 || argument > 127) return -1;
        } else if (argument < -1024 || argument > 1023) return -1;
    }

    SbtTree tree{};
    int root = 0;
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < operation_count; ++i) {
        const std::int64_t operation = input[1 + 2 * i];
        const std::int64_t argument = input[2 + 2 * i];
        std::int64_t answer;
        if (operation == 0) {
            if (!contains(tree, root, argument)) root = insert_new(tree, root, argument);
            continue;
        }
        if (operation == 1) answer = rank_less(tree, root, argument);
        else if (operation == 2) answer = kth(tree, root, argument);
        else if (operation == 3) answer = predecessor(tree, root, argument);
        else answer = successor(tree, root, argument);
        checksum += static_cast<std::int64_t>(i + 1) * (answer + 1025);
    }
    return checksum;
}
