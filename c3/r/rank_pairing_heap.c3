module rank_pairing_heap;

const int MAX_OPERATIONS = 64;
const int MAX_ITEMS = 32;
const long MAX_KEY = 1000000;

fn int rank_of(int node, int* ranks) {
    return node < 0 ? -1 : ranks[node];
}

fn bool root_precedes(int left, int right, long* keys, int* items) {
    if (keys[left] != keys[right]) return keys[left] < keys[right];
    if (items[left] != items[right]) return items[left] < items[right];
    return left < right;
}

fn int minimum_root(usz node_count, long* keys, int* items, int* parent, bool* alive) {
    int minimum = -1;
    for (usz node = 0; node < node_count; node += 1) {
        if (!alive[node] || parent[node] != -1) continue;
        if (minimum < 0 || root_precedes((int)node, minimum, keys, items)) minimum = (int)node;
    }
    return minimum;
}

fn void fair_link(int first, int second, long* keys, int* items, int* ranks,
                  int* left, int* right, int* parent) {
    int winner = root_precedes(first, second, keys, items) ? first : second;
    int loser = winner == first ? second : first;
    int old_left = left[winner];
    left[winner] = loser;
    parent[loser] = winner;
    right[loser] = old_left;
    if (old_left >= 0) parent[old_left] = loser;
    ranks[winner] += 1;
}

fn void consolidate_roots(usz node_count, long* keys, int* items, int* ranks,
                          int* left, int* right, int* parent, bool* alive) {
    while (true) {
        int duplicate_rank = -1;
        for (usz first = 0; first < node_count; first += 1) {
            if (!alive[first] || parent[first] != -1) continue;
            for (usz second = first + 1; second < node_count; second += 1) {
                if (!alive[second] || parent[second] != -1 || ranks[first] != ranks[second])
                    continue;
                if (duplicate_rank < 0 || ranks[first] < duplicate_rank)
                    duplicate_rank = ranks[first];
            }
        }
        if (duplicate_rank < 0) return;

        int first_root = -1, second_root = -1;
        for (usz node = 0; node < node_count; node += 1) {
            if (!alive[node] || parent[node] != -1 || ranks[node] != duplicate_rank) continue;
            if (first_root < 0) first_root = (int)node;
            else { second_root = (int)node; break; }
        }
        fair_link(first_root, second_root, keys, items, ranks, left, right, parent);
    }
}

fn long rank_pairing_heap(long* input, usz length) @export("rank_pairing_heap") {
    if (input == null || length < 1 || length > 194) return -1;
    long raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (usz)(1 + 3 * raw_operations) || length > 193) return -1;
    int operation_count = (int)raw_operations;

    long[MAX_OPERATIONS] keys = zeroed;
    int[MAX_OPERATIONS] items, ranks, left, right, parent;
    bool[MAX_OPERATIONS] alive = zeroed;
    int[MAX_ITEMS] item_nodes;
    bool[MAX_ITEMS] active = zeroed;
    for (int i = 0; i < MAX_OPERATIONS; i += 1) {
        items[i] = -1;
        ranks[i] = 0;
        left[i] = right[i] = -1;
        parent[i] = -2;
    }
    for (int i = 0; i < MAX_ITEMS; i += 1) item_nodes[i] = -1;

    usz node_count = 0;
    long result = 0;
    for (int operation = 0; operation < operation_count; operation += 1) {
        long opcode = input[1 + 3 * operation];
        long raw_item = input[2 + 3 * operation];
        long value = input[3 + 3 * operation];

        if (opcode == 1) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || value < 0 || value > MAX_KEY ||
                active[(usz)raw_item] || node_count >= MAX_OPERATIONS) return -1;
            usz node = node_count++;
            keys[node] = value;
            items[node] = (int)raw_item;
            ranks[node] = 0;
            left[node] = right[node] = -1;
            parent[node] = -1;
            alive[node] = true;
            item_nodes[(usz)raw_item] = (int)node;
            active[(usz)raw_item] = true;
        } else if (opcode == 2) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || !active[(usz)raw_item] ||
                value < 0 || value > MAX_KEY || node_count >= MAX_OPERATIONS) return -1;
            int node = item_nodes[(usz)raw_item];
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
                ranks[node] = rank_of(left[node], &ranks[0]) + 1;

                int ancestor = old_parent;
                while (ancestor >= 0) {
                    if (parent[ancestor] < 0) {
                        ranks[ancestor] = rank_of(left[ancestor], &ranks[0]) + 1;
                        break;
                    }
                    int left_rank = rank_of(left[ancestor], &ranks[0]);
                    int right_rank = rank_of(right[ancestor], &ranks[0]);
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
            int node = minimum_root(node_count, &keys[0], &items[0], &parent[0], &alive[0]);
            if (node < 0) return -1;
            result += (long)(operation + 1) * (keys[node] + 1) + items[node];
            if (opcode == 3) {
                int item = items[node];
                active[item] = false;
                item_nodes[item] = -1;
                int child = left[node];
                while (child >= 0) {
                    int next_sibling = right[child];
                    right[child] = -1;
                    parent[child] = -1;
                    ranks[child] = rank_of(left[child], &ranks[0]) + 1;
                    child = next_sibling;
                }
                alive[node] = false;
                parent[node] = -2;
                left[node] = right[node] = -1;
                items[node] = -1;
                consolidate_roots(node_count, &keys[0], &items[0], &ranks[0],
                                  &left[0], &right[0], &parent[0], &alive[0]);
            }
        } else {
            return -1;
        }
    }
    return result;
}
