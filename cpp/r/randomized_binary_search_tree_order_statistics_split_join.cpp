#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxInput = 164;
struct Node { std::int64_t key; int left; int right; int size; };
struct State { std::array<Node, 64> nodes{}; int used = 0; std::uint32_t random_state = 0; };

int size_of(const State& state, int root) { return root < 0 ? 0 : state.nodes[static_cast<std::size_t>(root)].size; }
void refresh(State& state, int root) {
    auto& node = state.nodes[static_cast<std::size_t>(root)];
    node.size = 1 + size_of(state, node.left) + size_of(state, node.right);
}
std::uint32_t randbelow(State& state, std::uint32_t bound) {
    const std::uint64_t threshold = (std::uint64_t{1} << 32) % bound;
    for (;;) {
        state.random_state = state.random_state * UINT32_C(1664525) + UINT32_C(1013904223);
        const auto raw = state.random_state;
        if (raw >= threshold) return raw % bound;
    }
}
int make_node(State& state, std::int64_t key, int left, int right) {
    const int id = state.used++;
    auto& node = state.nodes[static_cast<std::size_t>(id)];
    node.key = key; node.left = left; node.right = right;
    refresh(state, id);
    return id;
}
void split(State& state, int root, std::int64_t pivot, int& low, int& high) {
    if (root < 0) { low = -1; high = -1; return; }
    auto& node = state.nodes[static_cast<std::size_t>(root)];
    if (node.key < pivot) {
        int child_low, child_high;
        split(state, node.right, pivot, child_low, child_high);
        node.right = child_low; refresh(state, root); low = root; high = child_high;
    } else {
        int child_low, child_high;
        split(state, node.left, pivot, child_low, child_high);
        node.left = child_high; refresh(state, root); low = child_low; high = root;
    }
}
int join(State& state, int left, int right) {
    if (left < 0) return right;
    if (right < 0) return left;
    const auto left_size = static_cast<std::uint32_t>(size_of(state, left));
    const auto total = left_size + static_cast<std::uint32_t>(size_of(state, right));
    if (randbelow(state, total) < left_size) {
        auto& node = state.nodes[static_cast<std::size_t>(left)];
        node.right = join(state, node.right, right); refresh(state, left); return left;
    }
    auto& node = state.nodes[static_cast<std::size_t>(right)];
    node.left = join(state, left, node.left); refresh(state, right); return right;
}
bool contains(const State& state, int root, std::int64_t key) {
    while (root >= 0) {
        const auto& node = state.nodes[static_cast<std::size_t>(root)];
        if (key == node.key) return true;
        root = key < node.key ? node.left : node.right;
    }
    return false;
}
int insert_absent(State& state, int root, std::int64_t key) {
    if (root < 0) return make_node(state, key, -1, -1);
    if (randbelow(state, static_cast<std::uint32_t>(size_of(state, root) + 1)) == 0) {
        int left, right; split(state, root, key, left, right); return make_node(state, key, left, right);
    }
    auto& node = state.nodes[static_cast<std::size_t>(root)];
    if (key < node.key) node.left = insert_absent(state, node.left, key);
    else node.right = insert_absent(state, node.right, key);
    refresh(state, root); return root;
}
int erase_key(State& state, int root, std::int64_t key) {
    if (root < 0) return -1;
    auto& node = state.nodes[static_cast<std::size_t>(root)];
    if (key == node.key) return join(state, node.left, node.right);
    if (key < node.key) node.left = erase_key(state, node.left, key);
    else node.right = erase_key(state, node.right, key);
    refresh(state, root); return root;
}
std::int64_t kth(const State& state, int root, int rank) {
    if (rank > size_of(state, root)) return -1;
    while (root >= 0) {
        const auto& node = state.nodes[static_cast<std::size_t>(root)];
        const int left_size = size_of(state, node.left);
        if (rank == left_size + 1) return node.key;
        if (rank <= left_size) root = node.left;
        else { rank -= left_size + 1; root = node.right; }
    }
    return -1;
}
std::int64_t minimum(const State& state, int root) {
    if (root < 0) return -1;
    while (state.nodes[static_cast<std::size_t>(root)].left >= 0) root = state.nodes[static_cast<std::size_t>(root)].left;
    return state.nodes[static_cast<std::size_t>(root)].key;
}
std::int64_t maximum(const State& state, int root) {
    if (root < 0) return -1;
    while (state.nodes[static_cast<std::size_t>(root)].right >= 0) root = state.nodes[static_cast<std::size_t>(root)].right;
    return state.nodes[static_cast<std::size_t>(root)].key;
}
bool valid_operation(const std::int64_t* input, std::size_t offset) {
    const auto op = input[offset], a = input[offset + 1], b = input[offset + 2], c = input[offset + 3];
    if (op == 0 || op == 1) return (a == 0 || a == 1) && b >= 0 && b <= 1000 && c == 0;
    if (op == 2) return (a == 0 || a == 1) && b >= 1 && b <= 65 && c == 0;
    if (op == 3) return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c >= 0 && c <= 1001;
    if (op == 4) return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c == 0;
    return false;
}
}  // namespace

extern "C" std::int64_t randomized_binary_search_tree_order_statistics_split_join(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const auto n_value = input[0], q_value = input[1], seed = input[2];
    if (n_value < 0 || n_value > 32 || q_value < 0 || q_value > 32 || seed < 0 || seed > INT64_C(4294967295)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 3 + n + 4 * q) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[3 + i] < 0 || input[3 + i] > 1000 || (i > 0 && input[2 + i] >= input[3 + i])) return -1;
    }
    const std::size_t start = 3 + n;
    for (std::size_t op = 0; op < q; ++op) if (!valid_operation(input, start + 4 * op)) return -1;

    State state{};
    state.random_state = static_cast<std::uint32_t>(seed);
    std::array<int, 2> roots{-1, -1};
    for (std::size_t i = 0; i < n; ++i) roots[0] = insert_absent(state, roots[0], input[3 + i]);
    std::int64_t checksum = 0, query_number = 0;
    for (std::size_t op = 0; op < q; ++op) {
        const std::size_t offset = start + 4 * op;
        const auto opcode = input[offset];
        const int tree = static_cast<int>(input[offset + 1]);
        const auto argument = input[offset + 2], extra = input[offset + 3];
        if (opcode == 0) {
            if (!contains(state, roots[tree], argument)) roots[tree] = insert_absent(state, roots[tree], argument);
        } else if (opcode == 1) roots[tree] = erase_key(state, roots[tree], argument);
        else if (opcode == 2) { ++query_number; checksum += query_number * (kth(state, roots[tree], static_cast<int>(argument)) + 1); }
        else if (opcode == 3) {
            const int destination = static_cast<int>(argument);
            if (roots[destination] >= 0) return -1;
            split(state, roots[tree], extra, roots[tree], roots[destination]);
        } else {
            const int right = static_cast<int>(argument);
            const auto left_max = maximum(state, roots[tree]), right_min = minimum(state, roots[right]);
            if (left_max >= 0 && right_min >= 0 && left_max >= right_min) return -1;
            roots[tree] = join(state, roots[tree], roots[right]); roots[right] = -1;
        }
    }
    return checksum;
}
