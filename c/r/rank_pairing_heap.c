/* Type-1 rank-pairing heap using binary left/right/parent half-trees. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_ITEMS 32
#define MAX_KEY 1000000

static int rank_of(int node, const int *ranks)
{
    return node < 0 ? -1 : ranks[node];
}

static bool root_precedes(int left, int right, const int64_t *keys, const int *items)
{
    if (keys[left] != keys[right]) return keys[left] < keys[right];
    if (items[left] != items[right]) return items[left] < items[right];
    return left < right;
}

static int minimum_root(int node_count, const int64_t *keys, const int *items,
                        const int *parent, const bool *alive)
{
    int minimum = -1;
    for (int node = 0; node < node_count; ++node) {
        if (!alive[node] || parent[node] != -1) continue;
        if (minimum < 0 || root_precedes(node, minimum, keys, items)) minimum = node;
    }
    return minimum;
}

static void fair_link(int first, int second, const int64_t *keys, const int *items,
                      int *ranks, int *left, int *right, int *parent)
{
    int winner = root_precedes(first, second, keys, items) ? first : second;
    int loser = winner == first ? second : first;
    int old_left = left[winner];
    left[winner] = loser;
    parent[loser] = winner;
    right[loser] = old_left;
    if (old_left >= 0) parent[old_left] = loser;
    ++ranks[winner];
}

static void consolidate_roots(int node_count, const int64_t *keys, const int *items,
                              int *ranks, int *left, int *right, int *parent,
                              const bool *alive)
{
    for (;;) {
        int duplicate_rank = -1;
        for (int first = 0; first < node_count; ++first) {
            if (!alive[first] || parent[first] != -1) continue;
            for (int second = first + 1; second < node_count; ++second) {
                if (!alive[second] || parent[second] != -1 || ranks[first] != ranks[second])
                    continue;
                if (duplicate_rank < 0 || ranks[first] < duplicate_rank)
                    duplicate_rank = ranks[first];
            }
        }
        if (duplicate_rank < 0) return;

        int first_root = -1, second_root = -1;
        for (int node = 0; node < node_count; ++node) {
            if (!alive[node] || parent[node] != -1 || ranks[node] != duplicate_rank) continue;
            if (first_root < 0) first_root = node;
            else { second_root = node; break; }
        }
        fair_link(first_root, second_root, keys, items, ranks, left, right, parent);
    }
}

int64_t rank_pairing_heap(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 194) return -1;
    int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (size_t)(1 + 3 * raw_operations) || length > 193) return -1;
    int operation_count = (int)raw_operations;

    int64_t keys[MAX_OPERATIONS] = {0};
    int items[MAX_OPERATIONS], ranks[MAX_OPERATIONS], left[MAX_OPERATIONS];
    int right[MAX_OPERATIONS], parent[MAX_OPERATIONS];
    bool alive[MAX_OPERATIONS] = {false};
    int item_nodes[MAX_ITEMS];
    bool active[MAX_ITEMS] = {false};
    for (int i = 0; i < MAX_OPERATIONS; ++i) {
        items[i] = -1;
        ranks[i] = 0;
        left[i] = right[i] = -1;
        parent[i] = -2;
    }
    for (int i = 0; i < MAX_ITEMS; ++i) item_nodes[i] = -1;

    int node_count = 0;
    int64_t result = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        int64_t opcode = input[1 + 3 * operation];
        int64_t raw_item = input[2 + 3 * operation];
        int64_t value = input[3 + 3 * operation];

        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || value < 0 || value > MAX_KEY ||
                active[raw_item] || node_count >= MAX_OPERATIONS) return -1;
            int node = node_count++;
            keys[node] = value;
            items[node] = (int)raw_item;
            ranks[node] = 0;
            left[node] = right[node] = -1;
            parent[node] = -1;
            alive[node] = true;
            item_nodes[raw_item] = node;
            active[raw_item] = true;
        } else if (opcode == 2) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || !active[raw_item] ||
                value < 0 || value > MAX_KEY || node_count >= MAX_OPERATIONS) return -1;
            int node = item_nodes[raw_item];
            if (value >= keys[node]) return -1;
            keys[node] = value;
            if (parent[node] >= 0) {
                int old_parent = parent[node];
                int next_sibling = right[node];
                if (left[old_parent] == node) left[old_parent] = next_sibling;
                else right[old_parent] = next_sibling;
                if (next_sibling >= 0) parent[next_sibling] = old_parent;
                parent[node] = -1;
                right[node] = -1;
                ranks[node] = rank_of(left[node], ranks) + 1;

                int ancestor = old_parent;
                while (ancestor >= 0) {
                    if (parent[ancestor] < 0) {
                        ranks[ancestor] = rank_of(left[ancestor], ranks) + 1;
                        break;
                    }
                    int left_rank = rank_of(left[ancestor], ranks);
                    int right_rank = rank_of(right[ancestor], ranks);
                    int new_rank = left_rank != right_rank
                        ? (left_rank > right_rank ? left_rank : right_rank)
                        : left_rank + 1;
                    if (new_rank >= ranks[ancestor]) break;
                    ranks[ancestor] = new_rank;
                    ancestor = parent[ancestor];
                }
            }
        } else if (opcode == 3 || opcode == 4) {
            if (raw_item != 0 || value != 0) return -1;
            int node = minimum_root(node_count, keys, items, parent, alive);
            if (node < 0) return -1;
            result += (int64_t)(operation + 1) * (keys[node] + 1) + items[node];
            if (opcode == 3) {
                int item = items[node];
                active[item] = false;
                item_nodes[item] = -1;
                int child = left[node];
                while (child >= 0) {
                    int next_sibling = right[child];
                    right[child] = -1;
                    parent[child] = -1;
                    ranks[child] = rank_of(left[child], ranks) + 1;
                    child = next_sibling;
                }
                alive[node] = false;
                parent[node] = -2;
                left[node] = right[node] = -1;
                items[node] = -1;
                consolidate_roots(node_count, keys, items, ranks, left, right, parent, alive);
            }
        } else {
            return -1;
        }
    }
    return result;
}
