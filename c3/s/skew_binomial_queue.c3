module skew_binomial_queue;

const int MAX_OPERATIONS = 64;
const int MAX_ITEMS = 32;
const int MAX_NODES = 64;
const int MAX_RANK_BUCKETS = 65;
const long MAX_KEY = 1000000;

fn bool node_precedes(int first, int second, long* keys, int* serials, int* items) {
    if (keys[first] != keys[second]) return keys[first] < keys[second];
    if (serials[first] != serials[second]) return serials[first] < serials[second];
    if (items[first] != items[second]) return items[first] < items[second];
    return first < second;
}

fn bool root_order_precedes(int first, int second, int* ranks, int* serials) {
    if (ranks[first] != ranks[second]) return ranks[first] < ranks[second];
    if (serials[first] != serials[second]) return serials[first] < serials[second];
    return first < second;
}

fn int collect_roots(usz node_count, int* parents, bool* alive, int* ranks,
                     int* serials, int* roots) {
    int count = 0;
    for (usz node = 0; node < node_count; node += 1) {
        if (alive[node] && parents[node] == -1) roots[count++] = (int)node;
    }
    for (int i = 1; i < count; i += 1) {
        int key = roots[i], j = i;
        while (j > 0 && root_order_precedes(key, roots[j - 1], ranks, serials)) {
            roots[j] = roots[j - 1];
            j -= 1;
        }
        roots[j] = key;
    }
    return count;
}

fn int minimum_root(usz node_count, long* keys, int* items, int* serials,
                    int* parents, bool* alive) {
    int minimum = -1;
    for (usz node = 0; node < node_count; node += 1) {
        if (!alive[node] || parents[node] != -1) continue;
        if (minimum < 0 || node_precedes((int)node, minimum, keys, serials, items))
            minimum = (int)node;
    }
    return minimum;
}

fn int simple_link(int first, int second, long* keys, int* items, int* serials,
                  int* ranks, int* first_child, int* next_sibling, int* parents) {
    int winner = node_precedes(first, second, keys, serials, items) ? first : second;
    int loser = winner == first ? second : first;
    next_sibling[loser] = first_child[winner];
    first_child[winner] = loser;
    parents[loser] = winner;
    ranks[winner] += 1;
    return winner;
}

fn int skew_link(int singleton, int first, int second, long* keys, int* items,
                 int* serials, int* ranks, int* first_child, int* next_sibling,
                 int* parents) {
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

fn int insert_singleton(int singleton, usz node_count, long* keys, int* items,
                        int* serials, int* ranks, int* first_child,
                        int* next_sibling, int* parents, bool* alive) {
    int[MAX_NODES] roots;
    parents[singleton] = -2;
    next_sibling[singleton] = -1;
    int count = collect_roots(node_count, parents, alive, ranks, serials, &roots[0]);
    if (count >= 2 && ranks[roots[0]] == ranks[roots[1]])
        return skew_link(singleton, roots[0], roots[1], keys, items, serials,
                         ranks, first_child, next_sibling, parents);
    parents[singleton] = -1;
    return singleton;
}

fn bool normalize_equal_ranks(int* roots, int root_count, long* keys, int* items,
                              int* serials, int* ranks, int* first_child,
                              int* next_sibling, int* parents) {
    for (int i = 1; i < root_count; i += 1) {
        int key = roots[i], j = i;
        while (j > 0 && root_order_precedes(key, roots[j - 1], ranks, serials)) {
            roots[j] = roots[j - 1];
            j -= 1;
        }
        roots[j] = key;
    }
    int[MAX_RANK_BUCKETS] buckets;
    for (int i = 0; i < MAX_RANK_BUCKETS; i += 1) buckets[i] = -1;
    for (int i = 0; i < root_count; i += 1) {
        int current = roots[i];
        while (ranks[current] >= 0 && ranks[current] < MAX_RANK_BUCKETS &&
               buckets[ranks[current]] >= 0) {
            int previous = buckets[ranks[current]];
            buckets[ranks[current]] = -1;
            current = simple_link(previous, current, keys, items, serials, ranks,
                                 first_child, next_sibling, parents);
        }
        if (ranks[current] < 0 || ranks[current] >= MAX_RANK_BUCKETS) return false;
        buckets[ranks[current]] = current;
    }
    return true;
}

fn long skew_binomial_queue(long* input, usz length) @export("skew_binomial_queue") {
    if (input == null || length < 1 || length > 194) return -1;
    long raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (usz)(1 + 3 * raw_operations) || length > 193) return -1;
    int operation_count = (int)raw_operations;

    long[MAX_NODES] keys = zeroed;
    int[MAX_NODES] items, serials, ranks, first_child, next_sibling, parents;
    bool[MAX_NODES] alive = zeroed;
    bool[MAX_ITEMS] active = zeroed;
    int[MAX_ITEMS] item_nodes;
    for (int node = 0; node < MAX_NODES; node += 1) {
        items[node] = -1;
        serials[node] = 0;
        ranks[node] = 0;
        first_child[node] = -1;
        next_sibling[node] = -1;
        parents[node] = -2;
    }
    for (int item = 0; item < MAX_ITEMS; item += 1) item_nodes[item] = -1;

    usz node_count = 0;
    int insertion_serial = 0;
    long result = 0;
    for (int operation = 0; operation < operation_count; operation += 1) {
        long opcode = input[1 + 3 * operation];
        long raw_item = input[2 + 3 * operation];
        long key = input[3 + 3 * operation];
        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || key < 0 || key > MAX_KEY ||
                active[(usz)raw_item] || node_count >= MAX_NODES) return -1;
            int item = (int)raw_item;
            usz node = node_count++;
            keys[node] = key;
            items[node] = item;
            serials[node] = insertion_serial++;
            ranks[node] = 0;
            first_child[node] = -1;
            next_sibling[node] = -1;
            parents[node] = -1;
            alive[node] = true;
            item_nodes[(usz)item] = (int)node;
            active[(usz)item] = true;
            if (insert_singleton((int)node, node_count, &keys[0], &items[0], &serials[0],
                                 &ranks[0], &first_child[0], &next_sibling[0],
                                 &parents[0], &alive[0]) < 0) return -1;
        } else if (opcode == 2 || opcode == 3) {
            if (raw_item != 0 || key != 0) return -1;
            int node = minimum_root(node_count, &keys[0], &items[0], &serials[0],
                                   &parents[0], &alive[0]);
            if (node < 0) return -1;
            result += (long)(operation + 1) * (keys[node] + 1) + items[node];
            if (opcode == 2) continue;

            int removed_item = items[node];
            active[removed_item] = false;
            item_nodes[removed_item] = -1;
            int[MAX_NODES] children;
            int child_count = 0;
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
            first_child[node] = -1;
            next_sibling[node] = -1;

            bool[MAX_NODES] is_child = zeroed;
            int[MAX_NODES] positive_children;
            int positive_count = 0;
            int[MAX_NODES] zero_children;
            int zero_count = 0;
            for (int i = 0; i < child_count; i += 1) {
                int child = children[i];
                is_child[child] = true;
                if (ranks[child] == 0) zero_children[zero_count++] = child;
                else positive_children[positive_count++] = child;
            }
            for (int i = 1; i < zero_count; i += 1) {
                int value = zero_children[i], j = i;
                while (j > 0 && (serials[value] < serials[zero_children[j - 1]] ||
                       (serials[value] == serials[zero_children[j - 1]] &&
                        value < zero_children[j - 1]))) {
                    zero_children[j] = zero_children[j - 1];
                    j -= 1;
                }
                zero_children[j] = value;
            }
            int[MAX_NODES] roots;
            int root_count = 0;
            for (usz candidate = 0; candidate < node_count; candidate += 1)
                if (alive[candidate] && parents[candidate] == -1 && !is_child[candidate])
                    roots[root_count++] = (int)candidate;
            for (int i = 0; i < positive_count; i += 1)
                roots[root_count++] = positive_children[i];
            if (!normalize_equal_ranks(&roots[0], root_count, &keys[0], &items[0],
                                       &serials[0], &ranks[0], &first_child[0],
                                       &next_sibling[0], &parents[0])) return -1;
            for (int i = 0; i < zero_count; i += 1)
                if (insert_singleton(zero_children[i], node_count, &keys[0], &items[0],
                                     &serials[0], &ranks[0], &first_child[0],
                                     &next_sibling[0], &parents[0], &alive[0]) < 0) return -1;
        } else {
            return -1;
        }
    }
    return result;
}
