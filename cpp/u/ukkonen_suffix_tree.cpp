#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_text = 64;
constexpr int max_symbols = max_text + 1;
constexpr int max_nodes = 2 * max_symbols;
constexpr std::size_t max_input_length = max_text + 2;

struct UkkonenNode {
    int start = 0;
    int end = 0;
    int suffix_link = 0;
    int suffix_start = -1;
    bool open_end = false;
    int children[5] = {-1, -1, -1, -1, -1};
};

int new_node(UkkonenNode* nodes, int& used, int start, int end,
             bool open_end, int suffix_start) noexcept {
    if (used >= max_nodes) return -1;
    const int id = used++;
    nodes[id] = UkkonenNode{};
    nodes[id].start = start;
    nodes[id].end = end;
    nodes[id].suffix_link = 0;
    nodes[id].suffix_start = suffix_start;
    nodes[id].open_end = open_end;
    return id;
}

int edge_end(const UkkonenNode& node, int current_end) noexcept {
    return node.open_end ? current_end : node.end;
}

void append_token(std::int64_t token, std::int64_t& position,
                  std::int64_t& hash) noexcept {
    hash += position * token;
    ++position;
}

bool emit_tree(const UkkonenNode* nodes, const int* text, int node_id,
               int current_end, std::int64_t& distinct,
               std::int64_t& position, std::int64_t& hash) noexcept {
    for (int symbol = 0; symbol < 5; ++symbol) {
        const int child_id = nodes[node_id].children[symbol];
        if (child_id < 0) continue;
        const UkkonenNode& child = nodes[child_id];
        const int end = edge_end(child, current_end);
        const int length = end - child.start + 1;
        if (length <= 0) return false;

        append_token(1, position, hash);
        append_token(length, position, hash);
        for (int offset = 0; offset < length; ++offset) {
            const int edge_symbol = text[child.start + offset];
            append_token(edge_symbol + 1, position, hash);
            if (edge_symbol != 4) ++distinct;
        }

        bool has_children = false;
        for (int next_symbol = 0; next_symbol < 5; ++next_symbol) {
            if (child.children[next_symbol] >= 0) {
                has_children = true;
                break;
            }
        }
        if (has_children) {
            append_token(3, position, hash);
            if (!emit_tree(nodes, text, child_id, current_end, distinct,
                           position, hash)) return false;
            append_token(4, position, hash);
        } else {
            if (child.suffix_start < 0) return false;
            append_token(2, position, hash);
            append_token(static_cast<std::int64_t>(child.suffix_start) + 1,
                         position, hash);
        }
    }
    return true;
}
} // namespace

extern "C" std::int64_t ukkonen_suffix_tree(const std::int64_t* input,
                                             std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > max_text) return -1;
    const int text_length = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(text_length + 1)) return -1;

    int text[max_symbols]{};
    for (int index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 3) return -1;
        text[index] = static_cast<int>(input[index + 1]);
    }
    const int total_length = text_length + 1;
    text[text_length] = 4;

    UkkonenNode nodes[max_nodes]{};
    int used = 0;
    const int root = new_node(nodes, used, -1, -1, false, -1);
    if (root != 0) return -1;
    int active_node = root;
    int active_edge = -1;
    int active_length = 0;
    int remaining = 0;
    int leaf_end = -1;

    for (int phase = 0; phase < total_length; ++phase) {
        leaf_end = phase;
        ++remaining;
        int last_new_internal = -1;
        while (remaining > 0) {
            if (active_length == 0) active_edge = phase;
            const int edge_symbol = text[active_edge];
            const int next_id = nodes[active_node].children[edge_symbol];
            if (next_id < 0) {
                const int suffix_start = phase - remaining + 1;
                const int leaf = new_node(nodes, used, phase, -1, true, suffix_start);
                if (leaf < 0) return -1;
                nodes[active_node].children[edge_symbol] = leaf;
                if (last_new_internal >= 0) {
                    nodes[last_new_internal].suffix_link = active_node;
                    last_new_internal = -1;
                }
            } else {
                const int next_end = edge_end(nodes[next_id], leaf_end);
                const int length_on_edge = next_end - nodes[next_id].start + 1;
                if (active_length >= length_on_edge) {
                    active_edge += length_on_edge;
                    active_length -= length_on_edge;
                    active_node = next_id;
                    continue;
                }
                if (text[nodes[next_id].start + active_length] == text[phase]) {
                    if (last_new_internal >= 0) {
                        nodes[last_new_internal].suffix_link = active_node;
                        last_new_internal = -1;
                    }
                    ++active_length;
                    break;
                }

                const int split_start = nodes[next_id].start;
                const int split_end = split_start + active_length - 1;
                const int split = new_node(nodes, used, split_start, split_end,
                                           false, -1);
                if (split < 0) return -1;
                nodes[active_node].children[edge_symbol] = split;
                const int suffix_start = phase - remaining + 1;
                const int leaf = new_node(nodes, used, phase, -1, true, suffix_start);
                if (leaf < 0) return -1;
                nodes[split].children[text[phase]] = leaf;
                nodes[next_id].start += active_length;
                nodes[split].children[text[nodes[next_id].start]] = next_id;
                if (last_new_internal >= 0) nodes[last_new_internal].suffix_link = split;
                last_new_internal = split;
            }

            --remaining;
            if (active_node == root && active_length > 0) {
                --active_length;
                active_edge = phase - remaining + 1;
            } else if (active_node != root) {
                active_node = nodes[active_node].suffix_link;
            }
        }
    }

    std::int64_t distinct = 0;
    std::int64_t token_position = 1;
    std::int64_t hash = 0;
    append_token(0, token_position, hash);
    if (!emit_tree(nodes, text, root, leaf_end, distinct, token_position, hash)) return -1;
    append_token(4, token_position, hash);
    if (used > max_nodes || distinct > 2080 || hash > INT64_C(2576350140)) return -1;
    return (static_cast<std::int64_t>(used) << 44) | (distinct << 32) | hash;
}
