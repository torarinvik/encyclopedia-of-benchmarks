#include <array>
#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t max_ops = 64, max_keys = 32, max_input = 130, max_output = 784;
struct Node { std::int32_t key, left, right; };
std::int32_t rotate_right(std::array<Node, max_ops>& nodes, std::int32_t root) {
    const auto child = nodes[root].left; nodes[root].left = nodes[child].right; nodes[child].right = root; return child;
}
std::int32_t rotate_left(std::array<Node, max_ops>& nodes, std::int32_t root) {
    const auto child = nodes[root].right; nodes[root].right = nodes[child].left; nodes[child].left = root; return child;
}
std::int32_t splay(std::array<Node, max_ops>& nodes, std::int32_t root, std::int32_t key) {
    if (root < 0 || nodes[root].key == key) return root;
    if (key < nodes[root].key) {
        const auto left = nodes[root].left; if (left < 0) return root;
        if (key < nodes[left].key) { nodes[left].left = splay(nodes, nodes[left].left, key); root = rotate_right(nodes, root); }
        else if (key > nodes[left].key) { nodes[left].right = splay(nodes, nodes[left].right, key); if (nodes[left].right >= 0) nodes[root].left = rotate_left(nodes, left); }
        return nodes[root].left < 0 ? root : rotate_right(nodes, root);
    }
    const auto right = nodes[root].right; if (right < 0) return root;
    if (key > nodes[right].key) { nodes[right].right = splay(nodes, nodes[right].right, key); root = rotate_left(nodes, root); }
    else if (key < nodes[right].key) { nodes[right].left = splay(nodes, nodes[right].left, key); if (nodes[right].left >= 0) nodes[root].right = rotate_right(nodes, right); }
    return nodes[root].right < 0 ? root : rotate_left(nodes, root);
}
void inorder(const std::array<Node, max_ops>& nodes, std::int32_t root, std::array<std::int64_t, max_keys>& keys, std::size_t& count) {
    if (root < 0) return; inorder(nodes, nodes[root].left, keys, count); keys[count++] = nodes[root].key; inorder(nodes, nodes[root].right, keys, count);
}
void put(std::array<std::uint8_t, max_output>& out, std::size_t& offset, std::int64_t word) {
    const auto bits = static_cast<std::uint64_t>(word); for (unsigned shift = 0; shift < 64; shift += 8) out[offset++] = static_cast<std::uint8_t>(bits >> shift);
}
}

extern "C" std::int64_t splay_tree(const std::int64_t* input, std::size_t input_length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || input_length == 0 || input_length > max_input || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_ops)) return -1;
    const auto op_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + 2 * op_count) return -1;
    std::array<std::int64_t, max_ops> ops{}, keys{}, tags{};
    std::array<std::int64_t, max_keys> live{};
    std::size_t live_count = 0, offset = 1;
    for (std::size_t i = 0; i < op_count; ++i) {
        const auto op = input[offset++], key = input[offset++];
        if ((op != 0 && op != 1 && op != 2) || key < INT32_MIN || key > INT32_MAX) return -1;
        ops[i] = op; keys[i] = key;
        std::size_t found = live_count; for (std::size_t j = 0; j < live_count; ++j) if (live[j] == key) { found = j; break; }
        if (op == 0) { if (found < live_count || live_count == max_keys) return -1; live[live_count++] = key; }
        else if (op == 2) { if (live_count == 0) return -1; if (found < live_count) live[found] = live[--live_count]; }
    }
    std::array<Node, max_ops> nodes{}; std::size_t node_count = 0; std::int32_t root = -1;
    for (std::size_t i = 0; i < op_count; ++i) {
        const auto key = static_cast<std::int32_t>(keys[i]);
        if (ops[i] == 0) {
            if (root < 0) { nodes[node_count] = {key, -1, -1}; root = static_cast<std::int32_t>(node_count++); }
            else {
                root = splay(nodes, root, key); nodes[node_count] = {key, -1, -1}; const auto fresh = static_cast<std::int32_t>(node_count++);
                if (key < nodes[root].key) { nodes[fresh].left = nodes[root].left; nodes[fresh].right = root; nodes[root].left = -1; }
                else { nodes[fresh].right = nodes[root].right; nodes[fresh].left = root; nodes[root].right = -1; }
                root = fresh;
            }
            tags[i] = -2;
        } else if (ops[i] == 1) { root = splay(nodes, root, key); tags[i] = root >= 0 && nodes[root].key == key ? 1 : 0; }
        else {
            root = splay(nodes, root, key); tags[i] = -3;
            if (nodes[root].key == key) { const auto left = nodes[root].left, right = nodes[root].right; if (left < 0) root = right; else { const auto joined = splay(nodes, left, key); nodes[joined].right = right; root = joined; } }
        }
    }
    std::array<std::int64_t, max_keys> final_keys{}; std::size_t final_count = 0; inorder(nodes, root, final_keys, final_count);
    std::array<std::uint8_t, max_output> staged{}; std::size_t written = 0;
    put(staged, written, static_cast<std::int64_t>(op_count)); for (std::size_t i = 0; i < op_count; ++i) put(staged, written, tags[i]);
    put(staged, written, static_cast<std::int64_t>(final_count)); for (std::size_t i = 0; i < final_count; ++i) put(staged, written, final_keys[i]);
    if (output == nullptr || capacity < written) return -2;
    for (std::size_t i = 0; i < written; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(written);
}
