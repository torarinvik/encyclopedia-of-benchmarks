#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_ops = 48;
constexpr std::size_t handles = 8;
constexpr std::size_t max_words = 1 + 3 * max_ops;

struct Node {
    std::int64_t value;
    std::int32_t next;
    std::int32_t child;
    std::uint8_t kind;
    std::uint8_t live;
};

std::int32_t normalize(std::int32_t head, const Node *nodes) {
    while (head >= 0 && nodes[head].kind == 1 && nodes[head].live == 0)
        head = nodes[head].next;
    return head;
}

bool top_value(std::int32_t head, const Node *nodes, std::int64_t &value) {
    head = normalize(head, nodes);
    while (head >= 0 && nodes[head].kind == 1)
        head = normalize(nodes[head].next, nodes);
    if (head < 0) return false;
    value = nodes[head].value;
    return true;
}

void store_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t cactus_stack_branch_trace(const std::int64_t *input,
                                                   std::size_t length,
                                                   std::uint8_t *output,
                                                   std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_words + 1) return -1;
    const std::int64_t q_value = input[0];
    if (q_value < 0 || q_value > static_cast<std::int64_t>(max_ops)
        || length != 1 + 3 * static_cast<std::size_t>(q_value)) return -1;
    const auto q = static_cast<std::size_t>(q_value);
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = input[1 + 3*i];
        const auto a = input[2 + 3*i];
        const auto b = input[3 + 3*i];
        if (op == 0) {
            if (a < 0 || a >= static_cast<std::int64_t>(handles) || b < -1000 || b > 1000) return -1;
        } else if (op >= 1 && op <= 3) {
            if (a < 0 || a >= static_cast<std::int64_t>(handles) || b != 0) return -1;
        } else if (op == 4) {
            if (a < 0 || a >= static_cast<std::int64_t>(handles)
                || b < 0 || b >= static_cast<std::int64_t>(handles)) return -1;
        } else return -1;
    }

    Node nodes[max_ops]{};
    std::int32_t heads[handles], branch_child[handles], attached_owner[handles], wrapper_for_child[handles];
    std::int64_t statuses[max_ops]{}, results[max_ops]{};
    for (std::size_t h = 0; h < handles; ++h)
        heads[h] = branch_child[h] = attached_owner[h] = wrapper_for_child[h] = -1;
    std::size_t node_count = 0;

    for (std::size_t i = 0; i < q; ++i) {
        const auto op = static_cast<std::int32_t>(input[1 + 3*i]);
        const auto a = static_cast<std::int32_t>(input[2 + 3*i]);
        const auto b = input[3 + 3*i];
        heads[a] = normalize(heads[a], nodes);
        const auto head = heads[a];
        statuses[i] = 1;
        if (op == 0) {
            nodes[node_count] = Node{b, head, -1, 0, 0};
            heads[a] = static_cast<std::int32_t>(node_count++);
        } else if (op == 1) {
            if (head < 0 || (nodes[head].kind == 1 && nodes[head].live != 0)) statuses[i] = 0;
            else {
                results[i] = nodes[head].value;
                heads[a] = normalize(nodes[head].next, nodes);
                if (heads[a] < 0 && attached_owner[a] >= 0) {
                    const auto owner = attached_owner[a];
                    nodes[wrapper_for_child[a]].live = 0;
                    branch_child[owner] = -1;
                    attached_owner[a] = wrapper_for_child[a] = -1;
                }
            }
        } else if (op == 2) {
            std::int64_t value = 0;
            if (top_value(head, nodes, value)) results[i] = value;
            else statuses[i] = 0;
        } else if (op == 3) {
            results[i] = head >= 0 && nodes[head].kind == 1 && nodes[head].live != 0 ? 1 : 0;
        } else {
            const auto child = static_cast<std::int32_t>(b);
            heads[child] = normalize(heads[child], nodes);
            std::int64_t ignored = 0;
            const bool owner_nonempty = top_value(head, nodes, ignored);
            if (a == child || !owner_nonempty || attached_owner[a] >= 0
                || branch_child[a] >= 0 || attached_owner[child] >= 0
                || branch_child[child] >= 0) return -1;
            if (heads[child] < 0) results[i] = 0;
            else {
                nodes[node_count] = Node{0, head, child, 1, 1};
                const auto wrapper = static_cast<std::int32_t>(node_count++);
                heads[a] = wrapper;
                branch_child[a] = child;
                attached_owner[child] = a;
                wrapper_for_child[child] = wrapper;
                results[i] = 1;
            }
        }
    }

    const std::size_t required = 16 * q;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < q; ++i) {
        store_i64(output, 16*i, statuses[i]);
        store_i64(output, 16*i + 8, results[i]);
    }
    return static_cast<std::int64_t>(required);
}
