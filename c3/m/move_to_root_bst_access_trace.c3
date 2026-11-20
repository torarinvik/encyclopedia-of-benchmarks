module move_to_root_bst_access_trace;

const usz MAX_INITIAL = 16;
const usz MAX_ACCESSES = 32;

fn long move_to_root_bst_access_trace(long* values, usz length) @export("move_to_root_bst_access_trace") {
    if (values == null || length < 2 || length > 51) return -1;
    long initial_count = values[0];
    if (initial_count < 0 || initial_count > (long)MAX_INITIAL) return -1;
    usz query_count_index = 1 + (usz)initial_count;
    if (length < query_count_index + 1) return -1;
    long access_count = values[query_count_index];
    if (access_count < 0 || access_count > (long)MAX_ACCESSES
        || length != query_count_index + 1 + (usz)access_count) return -1;

    long[MAX_INITIAL] keys = {0};
    long[MAX_INITIAL] left = {0};
    long[MAX_INITIAL] right = {0};
    long[MAX_INITIAL] parent = {0};
    for (usz index = 0; index < MAX_INITIAL; index++) {
        left[index] = -1;
        right[index] = -1;
        parent[index] = -1;
    }
    for (usz index = 0; index < (usz)initial_count; index++) {
        long key = values[1 + index];
        if (key < -100 || key > 100) return -1;
        for (usz earlier = 0; earlier < index; earlier++) {
            if (values[1 + earlier] == key) return -1;
        }
        keys[index] = key;
    }
    for (usz query = 0; query < (usz)access_count; query++) {
        long key = values[query_count_index + 1 + query];
        if (key < -100 || key > 100) return -1;
    }

    long root = -1;
    for (long node = 0; node < initial_count; node++) {
        if (root == -1) {
            root = node;
            continue;
        }
        long current = root;
        while (true) {
            if (keys[(usz)node] < keys[(usz)current]) {
                if (left[(usz)current] == -1) {
                    left[(usz)current] = node;
                    parent[(usz)node] = current;
                    break;
                }
                current = left[(usz)current];
            } else {
                if (right[(usz)current] == -1) {
                    right[(usz)current] = node;
                    parent[(usz)node] = current;
                    break;
                }
                current = right[(usz)current];
            }
        }
    }

    long result = 0;
    for (usz query_number = 1; query_number <= (usz)access_count; query_number++) {
        long key = values[query_count_index + query_number];
        long node = root;
        long comparisons = 0;
        while (node != -1) {
            comparisons += 1;
            if (key == keys[(usz)node]) break;
            node = key < keys[(usz)node] ? left[(usz)node] : right[(usz)node];
        }
        while (node != -1 && parent[(usz)node] != -1) {
            long old_parent = parent[(usz)node];
            long grandparent = parent[(usz)old_parent];
            if (left[(usz)old_parent] == node) {
                long middle = right[(usz)node];
                right[(usz)node] = old_parent;
                left[(usz)old_parent] = middle;
                if (middle != -1) parent[(usz)middle] = old_parent;
            } else {
                long middle = left[(usz)node];
                left[(usz)node] = old_parent;
                right[(usz)old_parent] = middle;
                if (middle != -1) parent[(usz)middle] = old_parent;
            }
            parent[(usz)old_parent] = node;
            parent[(usz)node] = grandparent;
            if (grandparent == -1) root = node;
            else if (left[(usz)grandparent] == old_parent) left[(usz)grandparent] = node;
            else right[(usz)grandparent] = node;
        }
        result += (long)query_number * comparisons;
    }
    return result;
}
