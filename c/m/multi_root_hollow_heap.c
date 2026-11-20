/* Bounded multi-root hollow heap operation trace and checksum. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_ITEMS 32
#define MAX_KEY 1000000

static bool root_precedes(int left, int right, const int64_t *keys, const int *items)
{
    if (keys[left] != keys[right]) return keys[left] < keys[right];
    if (items[left] != items[right]) return items[left] < items[right];
    return left < right;
}

static int find_minimum_root(int node_count, const int64_t *keys, const int *items,
                             const int *parent, const bool *alive)
{
    int minimum = -1;
    for (int node = 0; node < node_count; ++node) {
        if (!alive[node] || parent[node] != -1 || items[node] < 0) continue;
        if (minimum < 0 || root_precedes(node, minimum, keys, items)) minimum = node;
    }
    return minimum;
}

static void destroy_hollow_roots_and_consolidate(int node_count, const int64_t *keys,
                                                 const int *items, int *ranks,
                                                 int *parent, bool *alive)
{
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
        int winner = root_precedes(first_root, second_root, keys, items)
                   ? first_root : second_root;
        int loser = winner == first_root ? second_root : first_root;
        parent[loser] = winner;
        ++ranks[winner];
    }
}

int64_t multi_root_hollow_heap(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 194) return -1;
    int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (size_t)(1 + 3 * raw_operations) || length > 193) return -1;
    int operation_count = (int)raw_operations;

    int64_t keys[MAX_OPERATIONS] = {0};
    int items[MAX_OPERATIONS], ranks[MAX_OPERATIONS], parent[MAX_OPERATIONS];
    bool alive[MAX_OPERATIONS] = {false};
    int item_nodes[MAX_ITEMS];
    bool active[MAX_ITEMS] = {false};
    for (int i = 0; i < MAX_OPERATIONS; ++i) {
        items[i] = -1;
        ranks[i] = 0;
        parent[i] = -2;
    }
    for (int i = 0; i < MAX_ITEMS; ++i) item_nodes[i] = -1;

    int node_count = 0;
    int64_t result = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = input[1 + 3 * operation];
        const int64_t raw_item = input[2 + 3 * operation];
        const int64_t value = input[3 + 3 * operation];

        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || value < 0 || value > MAX_KEY ||
                active[raw_item] || node_count >= MAX_OPERATIONS) return -1;
            int node = node_count++;
            keys[node] = value;
            items[node] = (int)raw_item;
            ranks[node] = 0;
            parent[node] = -1;
            alive[node] = true;
            item_nodes[raw_item] = node;
            active[raw_item] = true;
        } else if (opcode == 2) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || !active[raw_item] ||
                value < 0 || value > MAX_KEY || node_count >= MAX_OPERATIONS) return -1;
            int old = item_nodes[raw_item];
            if (value >= keys[old]) return -1;
            int node = node_count++;
            const int new_rank = ranks[old] >= 2 ? ranks[old] - 2 : 0;
            items[old] = -1;
            keys[node] = value;
            items[node] = (int)raw_item;
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
            int minimum = find_minimum_root(node_count, keys, items, parent, alive);
            if (minimum < 0) return -1;
            result += (int64_t)(operation + 1) * (keys[minimum] + 1) + items[minimum];
            if (opcode == 3) {
                int item = items[minimum];
                active[item] = false;
                item_nodes[item] = -1;
                items[minimum] = -1;
                destroy_hollow_roots_and_consolidate(node_count, keys, items, ranks, parent, alive);
            }
        } else if (opcode == 5) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || value != 0 || !active[raw_item]) return -1;
            int node = item_nodes[raw_item];
            int minimum = find_minimum_root(node_count, keys, items, parent, alive);
            bool was_minimum = node == minimum;
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
