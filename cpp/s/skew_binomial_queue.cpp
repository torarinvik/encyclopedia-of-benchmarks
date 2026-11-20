/* Bounded skew-binomial forest with singleton-assisted skew links. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_operations = 64;
constexpr int max_items = 32;
constexpr int max_nodes = 64;
constexpr int max_rank_buckets = max_nodes + 1;
constexpr std::int64_t max_key = 1'000'000;

bool node_precedes(int first, int second, const std::int64_t* keys,
                   const int* serials, const int* items) noexcept {
    if (keys[first] != keys[second]) return keys[first] < keys[second];
    if (serials[first] != serials[second]) return serials[first] < serials[second];
    if (items[first] != items[second]) return items[first] < items[second];
    return first < second;
}

bool root_order_precedes(int first, int second, const int* ranks,
                         const int* serials) noexcept {
    if (ranks[first] != ranks[second]) return ranks[first] < ranks[second];
    if (serials[first] != serials[second]) return serials[first] < serials[second];
    return first < second;
}

int collect_roots(int node_count, const int* parents, const bool* alive,
                  const int* ranks, const int* serials, int* roots) noexcept {
    int count = 0;
    for (int node = 0; node < node_count; ++node)
        if (alive[node] && parents[node] == -1) roots[count++] = node;
    for (int i = 1; i < count; ++i) {
        const int key = roots[i];
        int j = i;
        while (j > 0 && root_order_precedes(key, roots[j - 1], ranks, serials)) {
            roots[j] = roots[j - 1];
            --j;
        }
        roots[j] = key;
    }
    return count;
}

int minimum_root(int node_count, const std::int64_t* keys, const int* items,
                 const int* serials, const int* parents, const bool* alive) noexcept {
    int minimum = -1;
    for (int node = 0; node < node_count; ++node) {
        if (!alive[node] || parents[node] != -1) continue;
        if (minimum < 0 || node_precedes(node, minimum, keys, serials, items)) minimum = node;
    }
    return minimum;
}

int simple_link(int first, int second, const std::int64_t* keys, const int* items,
                const int* serials, int* ranks, int* first_child,
                int* next_sibling, int* parents) noexcept {
    const int winner = node_precedes(first, second, keys, serials, items) ? first : second;
    const int loser = winner == first ? second : first;
    next_sibling[loser] = first_child[winner];
    first_child[winner] = loser;
    parents[loser] = winner;
    ++ranks[winner];
    return winner;
}

int skew_link(int singleton, int first, int second, const std::int64_t* keys,
              const int* items, const int* serials, int* ranks,
              int* first_child, int* next_sibling, int* parents) noexcept {
    const int link_rank = ranks[first];
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
        const int loser = winner == first ? second : first;
        const int old_children = first_child[winner];
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

int insert_singleton(int singleton, int node_count, const std::int64_t* keys,
                     const int* items, const int* serials, int* ranks,
                     int* first_child, int* next_sibling, int* parents,
                     const bool* alive) noexcept {
    int roots[max_nodes];
    parents[singleton] = -2;
    next_sibling[singleton] = -1;
    const int count = collect_roots(node_count, parents, alive, ranks, serials, roots);
    if (count >= 2 && ranks[roots[0]] == ranks[roots[1]])
        return skew_link(singleton, roots[0], roots[1], keys, items, serials,
                         ranks, first_child, next_sibling, parents);
    parents[singleton] = -1;
    return singleton;
}

bool normalize_equal_ranks(int* roots, int root_count, const std::int64_t* keys,
                           const int* items, const int* serials, int* ranks,
                           int* first_child, int* next_sibling, int* parents) noexcept {
    for (int i = 1; i < root_count; ++i) {
        const int key = roots[i];
        int j = i;
        while (j > 0 && root_order_precedes(key, roots[j - 1], ranks, serials)) {
            roots[j] = roots[j - 1];
            --j;
        }
        roots[j] = key;
    }
    int buckets[max_rank_buckets];
    for (int i = 0; i < max_rank_buckets; ++i) buckets[i] = -1;
    for (int i = 0; i < root_count; ++i) {
        int current = roots[i];
        while (ranks[current] >= 0 && ranks[current] < max_rank_buckets &&
               buckets[ranks[current]] >= 0) {
            const int previous = buckets[ranks[current]];
            buckets[ranks[current]] = -1;
            current = simple_link(previous, current, keys, items, serials, ranks,
                                  first_child, next_sibling, parents);
        }
        if (ranks[current] < 0 || ranks[current] >= max_rank_buckets) return false;
        buckets[ranks[current]] = current;
    }
    return true;
}
}

extern "C" std::int64_t skew_binomial_queue(const std::int64_t* input,
                                              std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 194) return -1;
    const std::int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > max_operations ||
        length != static_cast<std::size_t>(1 + 3 * raw_operations) || length > 193) return -1;
    const int operation_count = static_cast<int>(raw_operations);

    std::int64_t keys[max_nodes]{};
    int items[max_nodes], serials[max_nodes], ranks[max_nodes];
    int first_child[max_nodes], next_sibling[max_nodes], parents[max_nodes];
    bool alive[max_nodes]{}, active[max_items]{};
    int item_nodes[max_items];
    for (int node = 0; node < max_nodes; ++node) {
        items[node] = -1;
        serials[node] = 0;
        ranks[node] = 0;
        first_child[node] = next_sibling[node] = -1;
        parents[node] = -2;
    }
    for (int item = 0; item < max_items; ++item) item_nodes[item] = -1;

    int node_count = 0, insertion_serial = 0;
    std::int64_t result = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[1 + 3 * operation];
        const std::int64_t raw_item = input[2 + 3 * operation];
        const std::int64_t key = input[3 + 3 * operation];
        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= max_items || key < 0 || key > max_key ||
                active[raw_item] || node_count >= max_nodes) return -1;
            const int item = static_cast<int>(raw_item);
            const int node = node_count++;
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
            const int node = minimum_root(node_count, keys, items, serials, parents, alive);
            if (node < 0) return -1;
            result += static_cast<std::int64_t>(operation + 1) * (keys[node] + 1) + items[node];
            if (opcode == 2) continue;

            const int removed_item = items[node];
            active[removed_item] = false;
            item_nodes[removed_item] = -1;
            int children[max_nodes], child_count = 0;
            for (int child = first_child[node]; child >= 0;) {
                const int following = next_sibling[child];
                parents[child] = -1;
                next_sibling[child] = -1;
                children[child_count++] = child;
                child = following;
            }
            alive[node] = false;
            parents[node] = -2;
            items[node] = -1;
            first_child[node] = next_sibling[node] = -1;

            bool is_child[max_nodes]{};
            int positive_children[max_nodes], positive_count = 0;
            int zero_children[max_nodes], zero_count = 0;
            for (int i = 0; i < child_count; ++i) {
                const int child = children[i];
                is_child[child] = true;
                if (ranks[child] == 0) zero_children[zero_count++] = child;
                else positive_children[positive_count++] = child;
            }
            for (int i = 1; i < zero_count; ++i) {
                const int value = zero_children[i];
                int j = i;
                while (j > 0 && (serials[value] < serials[zero_children[j - 1]] ||
                       (serials[value] == serials[zero_children[j - 1]] &&
                        value < zero_children[j - 1]))) {
                    zero_children[j] = zero_children[j - 1];
                    --j;
                }
                zero_children[j] = value;
            }
            int roots[max_nodes], root_count = 0;
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
