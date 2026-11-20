/* Bounded multi-root hollow heap operation trace and checksum. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_operations = 64;
constexpr int max_items = 32;
constexpr std::int64_t max_key = 1'000'000;

bool root_precedes(int left, int right, const std::int64_t* keys, const int* items) noexcept {
    if (keys[left] != keys[right]) return keys[left] < keys[right];
    if (items[left] != items[right]) return items[left] < items[right];
    return left < right;
}

int find_minimum_root(int node_count, const std::int64_t* keys, const int* items,
                      const int* parent, const bool* alive) noexcept {
    int minimum = -1;
    for (int node = 0; node < node_count; ++node) {
        if (!alive[node] || parent[node] != -1 || items[node] < 0) continue;
        if (minimum < 0 || root_precedes(node, minimum, keys, items)) minimum = node;
    }
    return minimum;
}

void destroy_hollow_roots_and_consolidate(int node_count, const std::int64_t* keys,
                                          const int* items, int* ranks,
                                          int* parent, bool* alive) noexcept {
    for (;;) {
        int hollow_root = -1;
        for (int node = 0; node < node_count; ++node) {
            if (alive[node] && parent[node] == -1 && items[node] < 0) {
                hollow_root = node;
                break;
            }
        }
        if (hollow_root < 0) break;
        for (int child = 0; child < node_count; ++child)
            if (alive[child] && parent[child] == hollow_root) parent[child] = -1;
        alive[hollow_root] = false;
        parent[hollow_root] = -2;
    }

    for (;;) {
        int duplicate_rank = -1;
        for (int first = 0; first < node_count; ++first) {
            if (!alive[first] || parent[first] != -1 || items[first] < 0) continue;
            for (int second = first + 1; second < node_count; ++second) {
                if (!alive[second] || parent[second] != -1 || items[second] < 0 ||
                    ranks[first] != ranks[second]) continue;
                if (duplicate_rank < 0 || ranks[first] < duplicate_rank)
                    duplicate_rank = ranks[first];
            }
        }
        if (duplicate_rank < 0) return;

        int first_root = -1, second_root = -1;
        for (int node = 0; node < node_count; ++node) {
            if (!alive[node] || parent[node] != -1 || items[node] < 0 ||
                ranks[node] != duplicate_rank) continue;
            if (first_root < 0) first_root = node;
            else { second_root = node; break; }
        }
        const int winner = root_precedes(first_root, second_root, keys, items)
                         ? first_root : second_root;
        const int loser = winner == first_root ? second_root : first_root;
        parent[loser] = winner;
        ++ranks[winner];
    }
}
}

extern "C" std::int64_t multi_root_hollow_heap(const std::int64_t* input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 194) return -1;
    const std::int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > max_operations ||
        length != static_cast<std::size_t>(1 + 3 * raw_operations) || length > 193) return -1;
    const int operation_count = static_cast<int>(raw_operations);

    std::int64_t keys[max_operations]{};
    int items[max_operations], ranks[max_operations], parent[max_operations];
    bool alive[max_operations]{};
    int item_nodes[max_items];
    bool active[max_items]{};
    for (int i = 0; i < max_operations; ++i) {
        items[i] = -1;
        ranks[i] = 0;
        parent[i] = -2;
    }
    for (int i = 0; i < max_items; ++i) item_nodes[i] = -1;

    int node_count = 0;
    std::int64_t result = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[1 + 3 * operation];
        const std::int64_t raw_item = input[2 + 3 * operation];
        const std::int64_t value = input[3 + 3 * operation];

        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= max_items || value < 0 || value > max_key ||
                active[raw_item] || node_count >= max_operations) return -1;
            const int node = node_count++;
            keys[node] = value;
            items[node] = static_cast<int>(raw_item);
            ranks[node] = 0;
            parent[node] = -1;
            alive[node] = true;
            item_nodes[raw_item] = node;
            active[raw_item] = true;
        } else if (opcode == 2) {
            if (raw_item < 0 || raw_item >= max_items || !active[raw_item] ||
                value < 0 || value > max_key || node_count >= max_operations) return -1;
            const int old = item_nodes[raw_item];
            if (value >= keys[old]) return -1;
            const int node = node_count++;
            const int new_rank = ranks[old] >= 2 ? ranks[old] - 2 : 0;
            items[old] = -1;
            keys[node] = value;
            items[node] = static_cast<int>(raw_item);
            ranks[node] = new_rank;
            parent[node] = -1;
            alive[node] = true;
            for (int child = 0; child < node; ++child) {
                if (alive[child] && parent[child] == old && ranks[child] < new_rank)
                    parent[child] = node;
            }
            item_nodes[raw_item] = node;
        } else if (opcode == 3 || opcode == 4) {
            if (raw_item != 0 || value != 0) return -1;
            const int minimum = find_minimum_root(node_count, keys, items, parent, alive);
            if (minimum < 0) return -1;
            result += static_cast<std::int64_t>(operation + 1) * (keys[minimum] + 1) + items[minimum];
            if (opcode == 3) {
                const int item = items[minimum];
                active[item] = false;
                item_nodes[item] = -1;
                items[minimum] = -1;
                destroy_hollow_roots_and_consolidate(node_count, keys, items, ranks, parent, alive);
            }
        } else if (opcode == 5) {
            if (raw_item < 0 || raw_item >= max_items || value != 0 || !active[raw_item]) return -1;
            const int node = item_nodes[raw_item];
            const int minimum = find_minimum_root(node_count, keys, items, parent, alive);
            const bool was_minimum = node == minimum;
            active[raw_item] = false;
            item_nodes[raw_item] = -1;
            items[node] = -1;
            if (was_minimum)
                destroy_hollow_roots_and_consolidate(node_count, keys, items, ranks, parent, alive);
        } else {
            return -1;
        }
    }
    return result;
}
