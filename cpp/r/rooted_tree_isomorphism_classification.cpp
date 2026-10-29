#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TREES = 16;
constexpr std::size_t MAX_TREE_VERTICES = 32;
constexpr std::size_t MAX_TOTAL_VERTICES = 128;
constexpr std::size_t MAX_INPUT_LENGTH = 1 + 2 * MAX_TREES * MAX_TREE_VERTICES;

struct Signature {
    std::size_t child_count{};
    std::size_t child_types[MAX_TREE_VERTICES]{};
};

std::size_t intern(Signature* signatures, std::size_t& signature_count,
                   const std::size_t* children, std::size_t child_count) {
    for (std::size_t signature = 0; signature < signature_count; ++signature) {
        if (signatures[signature].child_count != child_count) continue;
        std::size_t index = 0;
        while (index < child_count && signatures[signature].child_types[index] == children[index]) ++index;
        if (index == child_count) return signature;
    }
    if (signature_count >= MAX_TOTAL_VERTICES) return MAX_TOTAL_VERTICES;
    const auto result = signature_count++;
    signatures[result].child_count = child_count;
    for (std::size_t index = 0; index < child_count; ++index)
        signatures[result].child_types[index] = children[index];
    return result;
}

std::int64_t canonical_root(const std::uint32_t* adjacency, std::size_t n,
                            std::size_t root, Signature* signatures,
                            std::size_t& signature_count) {
    std::size_t parent[MAX_TREE_VERTICES];
    std::size_t order[MAX_TREE_VERTICES];
    std::size_t stack[MAX_TREE_VERTICES];
    std::size_t type[MAX_TREE_VERTICES];
    bool visited[MAX_TREE_VERTICES]{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = MAX_TREE_VERTICES;
    parent[root] = root;
    visited[root] = true;
    std::size_t stack_size = 1, order_size = 0;
    stack[0] = root;
    while (stack_size != 0) {
        const auto vertex = stack[--stack_size];
        order[order_size++] = vertex;
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            const auto bit = UINT32_C(1) << static_cast<std::uint32_t>(neighbor);
            if ((adjacency[vertex] & bit) == 0 || neighbor == parent[vertex]) continue;
            if (visited[neighbor]) return -1;
            visited[neighbor] = true;
            parent[neighbor] = vertex;
            stack[stack_size++] = neighbor;
        }
    }
    if (order_size != n) return -1;

    for (std::size_t reverse = order_size; reverse > 0; --reverse) {
        const auto vertex = order[reverse - 1];
        std::size_t children[MAX_TREE_VERTICES];
        std::size_t child_count = 0;
        for (std::size_t candidate = 0; candidate < n; ++candidate)
            if (candidate != vertex && parent[candidate] == vertex) children[child_count++] = type[candidate];
        for (std::size_t index = 1; index < child_count; ++index) {
            const auto value = children[index];
            auto position = index;
            while (position > 0 && children[position - 1] > value) {
                children[position] = children[position - 1];
                --position;
            }
            children[position] = value;
        }
        type[vertex] = intern(signatures, signature_count, children, child_count);
        if (type[vertex] >= MAX_TOTAL_VERTICES) return -1;
    }
    return static_cast<std::int64_t>(type[root]);
}
} // namespace

extern "C" std::int64_t rooted_tree_isomorphism_classification(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) {
    if (values == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(MAX_TREES)) return -1;
    const auto tree_count = static_cast<std::size_t>(values[0]);
    Signature signatures[MAX_TOTAL_VERTICES]{};
    std::size_t signature_count = 0;
    std::size_t root_types[MAX_TREES]{};
    std::uint8_t labels[MAX_TREES]{};
    std::size_t position = 1, total_vertices = 0, class_count = 0;

    for (std::size_t tree = 0; tree < tree_count; ++tree) {
        if (position + 2 > length) return -1;
        const auto n_value = values[position++];
        const auto root_value = values[position++];
        if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_TREE_VERTICES)) return -1;
        const auto n = static_cast<std::size_t>(n_value);
        if (root_value < 0 || root_value >= n_value) return -1;
        total_vertices += n;
        if (total_vertices > MAX_TOTAL_VERTICES) return -1;
        const auto edge_count = n - 1;
        if (2 * edge_count > length - position) return -1;

        std::uint32_t adjacency[MAX_TREE_VERTICES]{};
        for (std::size_t edge = 0; edge < edge_count; ++edge) {
            const auto left_value = values[position++];
            const auto right_value = values[position++];
            if (left_value < 0 || right_value < 0 || left_value >= n_value ||
                right_value >= n_value || left_value == right_value) return -1;
            const auto left = static_cast<std::size_t>(left_value);
            const auto right = static_cast<std::size_t>(right_value);
            const auto left_bit = UINT32_C(1) << static_cast<std::uint32_t>(left);
            const auto right_bit = UINT32_C(1) << static_cast<std::uint32_t>(right);
            if ((adjacency[left] & right_bit) != 0) return -1;
            adjacency[left] |= right_bit;
            adjacency[right] |= left_bit;
        }

        const auto root_type = canonical_root(adjacency, n, static_cast<std::size_t>(root_value),
                                               signatures, signature_count);
        if (root_type < 0) return -1;
        root_types[tree] = static_cast<std::size_t>(root_type);
        std::size_t prior = 0;
        while (prior < tree && root_types[prior] != root_types[tree]) ++prior;
        if (prior < tree) labels[tree] = labels[prior];
        else labels[tree] = static_cast<std::uint8_t>(class_count++);
    }
    if (position != length) return -1;
    if (output == nullptr || output_capacity < tree_count) return -2;
    for (std::size_t tree = 0; tree < tree_count; ++tree) output[tree] = labels[tree];
    return static_cast<std::int64_t>(tree_count);
}
