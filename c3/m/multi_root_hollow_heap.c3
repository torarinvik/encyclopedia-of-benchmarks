module multi_root_hollow_heap;

const int MAX_OPERATIONS = 64;
const int MAX_ITEMS = 32;
const long MAX_KEY = 1000000;

fn bool root_precedes(int left, int right, long* keys, int* items) {
    if (keys[left] != keys[right]) return keys[left] < keys[right];
    if (items[left] != items[right]) return items[left] < items[right];
    return left < right;
}

fn int find_minimum_root(usz node_count, long* keys, int* items, int* parent, bool* alive) {
    int minimum = -1;
    for (usz node = 0; node < node_count; node += 1) {
        if (!alive[node] || parent[node] != -1 || items[node] < 0) continue;
        if (minimum < 0 || root_precedes((int)node, minimum, keys, items)) minimum = (int)node;
    }
    return minimum;
}

fn void destroy_hollow_roots_and_consolidate(usz node_count, long* keys, int* items,
                                              int* ranks, int* parent, bool* alive) {
    while (true) {
        int hollow_root = -1;
        for (usz node = 0; node < node_count; node += 1) {
            if (alive[node] && parent[node] == -1 && items[node] < 0) {
                hollow_root = (int)node;
                break;
            }
        }
        if (hollow_root < 0) break;
        for (usz child = 0; child < node_count; child += 1)
            if (alive[child] && parent[child] == hollow_root) parent[child] = -1;
        alive[hollow_root] = false;
        parent[hollow_root] = -2;
    }

    while (true) {
        int duplicate_rank = -1;
        for (usz first = 0; first < node_count; first += 1) {
            if (!alive[first] || parent[first] != -1 || items[first] < 0) continue;
            for (usz second = first + 1; second < node_count; second += 1) {
                if (!alive[second] || parent[second] != -1 || items[second] < 0 ||
                    ranks[first] != ranks[second]) continue;
                if (duplicate_rank < 0 || ranks[first] < duplicate_rank)
                    duplicate_rank = ranks[first];
            }
        }
        if (duplicate_rank < 0) return;

        int first_root = -1, second_root = -1;
        for (usz node = 0; node < node_count; node += 1) {
            if (!alive[node] || parent[node] != -1 || items[node] < 0 ||
                ranks[node] != duplicate_rank) continue;
            if (first_root < 0) first_root = (int)node;
            else { second_root = (int)node; break; }
        }
        int winner = root_precedes(first_root, second_root, keys, items)
                   ? first_root : second_root;
        int loser = winner == first_root ? second_root : first_root;
        parent[loser] = winner;
        ranks[winner] += 1;
    }
}

fn long multi_root_hollow_heap(long* input, usz length) @export("multi_root_hollow_heap") {
    if (input == null || length < 1 || length > 194) return -1;
    long raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (usz)(1 + 3 * raw_operations) || length > 193) return -1;
    int operation_count = (int)raw_operations;

    long[MAX_OPERATIONS] keys = zeroed;
    int[MAX_OPERATIONS] items, ranks, parent;
    bool[MAX_OPERATIONS] alive = zeroed;
    int[MAX_ITEMS] item_nodes;
    bool[MAX_ITEMS] active = zeroed;
    for (int i = 0; i < MAX_OPERATIONS; i += 1) {
        items[i] = -1;
        ranks[i] = 0;
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
            parent[node] = -1;
            alive[node] = true;
            item_nodes[(usz)raw_item] = (int)node;
            active[(usz)raw_item] = true;
        } else if (opcode == 2) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || !active[(usz)raw_item] ||
                value < 0 || value > MAX_KEY || node_count >= MAX_OPERATIONS) return -1;
            int old = item_nodes[(usz)raw_item];
            if (value >= keys[old]) return -1;
            usz node = node_count++;
            int new_rank = ranks[old] >= 2 ? ranks[old] - 2 : 0;
            items[old] = -1;
            keys[node] = value;
            items[node] = (int)raw_item;
            ranks[node] = new_rank;
            parent[node] = -1;
            alive[node] = true;
            for (usz child = 0; child < node; child += 1) {
                if (alive[child] && parent[child] == old && ranks[child] < new_rank)
                    parent[child] = (int)node;
            }
            item_nodes[(usz)raw_item] = (int)node;
        } else if (opcode == 3 || opcode == 4) {
            if (raw_item != 0 || value != 0) return -1;
            int minimum = find_minimum_root(node_count, &keys[0], &items[0], &parent[0], &alive[0]);
            if (minimum < 0) return -1;
            result += (long)(operation + 1) * (keys[minimum] + 1) + items[minimum];
            if (opcode == 3) {
                int item = items[minimum];
                active[item] = false;
                item_nodes[item] = -1;
                items[minimum] = -1;
                destroy_hollow_roots_and_consolidate(node_count, &keys[0], &items[0],
                                                      &ranks[0], &parent[0], &alive[0]);
            }
        } else if (opcode == 5) {
            if (raw_item < 0 || raw_item >= MAX_ITEMS || value != 0 || !active[(usz)raw_item])
                return -1;
            int node = item_nodes[(usz)raw_item];
            int minimum = find_minimum_root(node_count, &keys[0], &items[0], &parent[0], &alive[0]);
            bool was_minimum = node == minimum;
            active[(usz)raw_item] = false;
            item_nodes[(usz)raw_item] = -1;
            items[node] = -1;
            if (was_minimum)
                destroy_hollow_roots_and_consolidate(node_count, &keys[0], &items[0],
                                                      &ranks[0], &parent[0], &alive[0]);
        } else {
            return -1;
        }
    }
    return result;
}
