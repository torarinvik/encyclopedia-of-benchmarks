/* Bounded skew-binomial forest with singleton-assisted skew links. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_ITEMS 32
#define MAX_NODES 64
#define MAX_RANK_BUCKETS (MAX_NODES + 1)
#define MAX_KEY 1000000

static int node_precedes(int first, int second, const int64_t *keys,
                         const int *serials, const int *items)
{
    if (keys[first] != keys[second]) return keys[first] < keys[second];
    if (serials[first] != serials[second]) return serials[first] < serials[second];
    if (items[first] != items[second]) return items[first] < items[second];
    return first < second;
}

static int root_order_precedes(int first, int second, const int *ranks,
                               const int *serials)
{
    if (ranks[first] != ranks[second]) return ranks[first] < ranks[second];
    if (serials[first] != serials[second]) return serials[first] < serials[second];
    return first < second;
}

static int collect_roots(int node_count, const int *parents, const bool *alive,
                         const int *ranks, const int *serials, int roots[MAX_NODES])
{
    int count = 0;
    for (int node = 0; node < node_count; ++node)
        if (alive[node] && parents[node] == -1) roots[count++] = node;
    for (int i = 1; i < count; ++i) {
        int key = roots[i], j = i;
        while (j > 0 && root_order_precedes(key, roots[j - 1], ranks, serials)) {
            roots[j] = roots[j - 1];
            --j;
        }
        roots[j] = key;
    }
    return count;
}

static int minimum_root(int node_count, const int64_t *keys, const int *items,
                        const int *serials, const int *parents, const bool *alive)
{
    int minimum = -1;
    for (int node = 0; node < node_count; ++node) {
        if (!alive[node] || parents[node] != -1) continue;
        if (minimum < 0 || node_precedes(node, minimum, keys, serials, items)) minimum = node;
    }
    return minimum;
}

static int simple_link(int first, int second, const int64_t *keys, const int *items,
                       const int *serials, int *ranks, int *first_child,
                       int *next_sibling, int *parents)
{
    int winner = node_precedes(first, second, keys, serials, items) ? first : second;
    int loser = winner == first ? second : first;
    next_sibling[loser] = first_child[winner];
    first_child[winner] = loser;
    parents[loser] = winner;
    ++ranks[winner];
    return winner;
}

static int skew_link(int singleton, int first, int second, const int64_t *keys,
                     const int *items, const int *serials, int *ranks,
                     int *first_child, int *next_sibling, int *parents)
{
    int link_rank = ranks[first];
    int winner;
    if (node_precedes(singleton, first, keys, serials, items) &&
        node_precedes(singleton, second, keys, serials, items)) {
        winner = singleton;
        first_child[winner] = first;
        next_sibling[first] = second;
        next_sibling[second] = -1;
        parents[first] = winner;
        parents[second] = winner;
    } else {
        winner = node_precedes(first, second, keys, serials, items) ? first : second;
        int loser = winner == first ? second : first;
        int old_children = first_child[winner];
        first_child[winner] = singleton;
        next_sibling[singleton] = loser;
        next_sibling[loser] = old_children;
        parents[singleton] = winner;
        parents[loser] = winner;
    }
    parents[winner] = -1;
    ranks[winner] = link_rank + 1;
    return winner;
}

static int insert_singleton(int singleton, int node_count, const int64_t *keys,
                            const int *items, const int *serials, int *ranks,
                            int *first_child, int *next_sibling, int *parents,
                            const bool *alive)
{
    int roots[MAX_NODES];
    parents[singleton] = -2;
    next_sibling[singleton] = -1;
    int count = collect_roots(node_count, parents, alive, ranks, serials, roots);
    if (count >= 2 && ranks[roots[0]] == ranks[roots[1]])
        return skew_link(singleton, roots[0], roots[1], keys, items, serials,
                         ranks, first_child, next_sibling, parents);
    parents[singleton] = -1;
    return singleton;
}

static int normalize_equal_ranks(int *roots, int root_count, const int64_t *keys,
                                 const int *items, const int *serials, int *ranks,
                                 int *first_child, int *next_sibling, int *parents)
{
    for (int i = 1; i < root_count; ++i) {
        int key = roots[i], j = i;
        while (j > 0 && root_order_precedes(key, roots[j - 1], ranks, serials)) {
            roots[j] = roots[j - 1];
            --j;
        }
        roots[j] = key;
    }
    int buckets[MAX_RANK_BUCKETS];
    for (int i = 0; i < MAX_RANK_BUCKETS; ++i) buckets[i] = -1;
    for (int i = 0; i < root_count; ++i) {
        int current = roots[i];
        while (ranks[current] >= 0 && ranks[current] < MAX_RANK_BUCKETS &&
               buckets[ranks[current]] >= 0) {
            int previous = buckets[ranks[current]];
            buckets[ranks[current]] = -1;
            current = simple_link(previous, current, keys, items, serials,
                                  ranks, first_child, next_sibling, parents);
        }
        if (ranks[current] < 0 || ranks[current] >= MAX_RANK_BUCKETS) return 0;
        buckets[ranks[current]] = current;
    }
    return 1;
}

int64_t skew_binomial_queue(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 194) return -1;
    int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (size_t)(1 + 3 * raw_operations) || length > 193) return -1;
    int operation_count = (int)raw_operations;

    int64_t keys[MAX_NODES] = {0};
    int items[MAX_NODES], serials[MAX_NODES], ranks[MAX_NODES];
    int first_child[MAX_NODES], next_sibling[MAX_NODES], parents[MAX_NODES];
    bool alive[MAX_NODES] = {false};
    bool active[MAX_ITEMS] = {false};
    int item_nodes[MAX_ITEMS];
    for (int node = 0; node < MAX_NODES; ++node) {
        items[node] = -1;
        serials[node] = 0;
        ranks[node] = 0;
        first_child[node] = next_sibling[node] = -1;
        parents[node] = -2;
    }
    for (int item = 0; item < MAX_ITEMS; ++item) item_nodes[item] = -1;

    int node_count = 0, insertion_serial = 0;
    int64_t result = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        int64_t opcode = input[1 + 3 * operation];
        int64_t raw_item = input[2 + 3 * operation];
        int64_t key = input[3 + 3 * operation];
        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || key < 0 || key > MAX_KEY ||
                active[raw_item] || node_count >= MAX_NODES) return -1;
            int item = (int)raw_item;
            int node = node_count++;
            keys[node] = key;
            items[node] = item;
            serials[node] = insertion_serial++;
            ranks[node] = 0;
            first_child[node] = next_sibling[node] = -1;
            parents[node] = -1;
            alive[node] = true;
            item_nodes[item] = node;
            active[item] = true;
            if (insert_singleton(node, node_count, keys, items, serials, ranks,
                                 first_child, next_sibling, parents, alive) < 0) return -1;
        } else if (opcode == 2 || opcode == 3) {
            if (raw_item != 0 || key != 0) return -1;
            int node = minimum_root(node_count, keys, items, serials, parents, alive);
            if (node < 0) return -1;
            result += (int64_t)(operation + 1) * (keys[node] + 1) + items[node];
            if (opcode == 2) continue;

            int removed_item = items[node];
            active[removed_item] = false;
            item_nodes[removed_item] = -1;
            int children[MAX_NODES], child_count = 0;
            for (int child = first_child[node]; child >= 0;) {
                int following = next_sibling[child];
                parents[child] = -1;
                next_sibling[child] = -1;
                children[child_count++] = child;
                child = following;
            }
            alive[node] = false;
            parents[node] = -2;
            items[node] = -1;
            first_child[node] = next_sibling[node] = -1;

            bool is_child[MAX_NODES] = {false};
            int positive_children[MAX_NODES], positive_count = 0;
            int zero_children[MAX_NODES], zero_count = 0;
            for (int i = 0; i < child_count; ++i) {
                int child = children[i];
                is_child[child] = true;
                if (ranks[child] == 0) zero_children[zero_count++] = child;
                else positive_children[positive_count++] = child;
            }
            for (int i = 1; i < zero_count; ++i) {
                int value = zero_children[i], j = i;
                while (j > 0 && (serials[value] < serials[zero_children[j - 1]] ||
                       (serials[value] == serials[zero_children[j - 1]] &&
                        value < zero_children[j - 1]))) {
                    zero_children[j] = zero_children[j - 1];
                    --j;
                }
                zero_children[j] = value;
            }

            int roots[MAX_NODES], root_count = 0;
            for (int candidate = 0; candidate < node_count; ++candidate)
                if (alive[candidate] && parents[candidate] == -1 && !is_child[candidate])
                    roots[root_count++] = candidate;
            for (int i = 0; i < positive_count; ++i) roots[root_count++] = positive_children[i];
            if (!normalize_equal_ranks(roots, root_count, keys, items, serials, ranks,
                                       first_child, next_sibling, parents)) return -1;
            for (int i = 0; i < zero_count; ++i)
                if (insert_singleton(zero_children[i], node_count, keys, items, serials,
                                     ranks, first_child, next_sibling, parents, alive) < 0) return -1;
        } else {
            return -1;
        }
    }
    return result;
}
