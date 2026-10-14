module binary_search_tree;

// Bounded unbalanced binary search tree with an index-based node pool.
fn long binary_search_tree_benchmark(long* values, usz length) @export("binary_search_tree_benchmark")
{
    if (length > 1024 || length % 2 != 0) return -1;
    usz operation_count = length / 2;
    long[256] key;
    usz[256] left;
    usz[256] right;
    usz[256] free_next;
    for (usz i = 0; i < 256; i++) free_next[i] = i + 1;
    usz free_head = 0;
    usz root = 256;
    usz count = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[2 * operation];
        long payload = values[2 * operation + 1];
        long observed = 0;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz parent = 256;
            usz node = root;
            while (node != 256 && key[node] != payload) {
                parent = node;
                if (payload < key[node]) { node = left[node]; } else { node = right[node]; }
            }
            if (node == 256) {
                if (count == 256 || free_head == 256) return -1;
                node = free_head;
                free_head = free_next[node];
                key[node] = payload;
                left[node] = 256;
                right[node] = 256;
                if (parent == 256) { root = node; }
                else if (payload < key[parent]) { left[parent] = node; } else { right[parent] = node; }
                count++;
                observed = 1;
            }
        } else if (opcode == 1) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz parent = 256;
            usz node = root;
            while (node != 256 && key[node] != payload) {
                parent = node;
                if (payload < key[node]) { node = left[node]; } else { node = right[node]; }
            }
            observed = (long)(node != 256);
            if (node != 256) {
                if (left[node] != 256 && right[node] != 256) {
                    usz pred_parent = node;
                    usz pred = left[node];
                    while (right[pred] != 256) { pred_parent = pred; pred = right[pred]; }
                    key[node] = key[pred];
                    parent = pred_parent;
                    node = pred;
                }
                usz child = left[node];
                if (child == 256) child = right[node];
                if (parent == 256) { root = child; }
                else if (left[parent] == node) { left[parent] = child; } else { right[parent] = child; }
                free_next[node] = free_head;
                free_head = node;
                count--;
            }
        } else if (opcode == 2) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz node = root;
            while (node != 256 && key[node] != payload) {
                if (payload < key[node]) { node = left[node]; } else { node = right[node]; }
            }
            observed = (long)(node != 256);
        } else if (opcode == 3 || opcode == 4) {
            if (payload != 0 || root == 256) return -1;
            usz node = root;
            if (opcode == 3) { while (left[node] != 256) node = left[node]; }
            else { while (right[node] != 256) node = right[node]; }
            observed = key[node];
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            observed = (long)count;
        } else {
            return -1;
        }
        checksum += (long)(operation + 1) * (observed + 1000000);
    }
    usz[256] stack;
    usz top = 0;
    usz node = root;
    usz index = 0;
    while (node != 256 || top != 0) {
        while (node != 256) { stack[top] = node; top++; node = left[node]; }
        top--;
        node = stack[top];
        checksum += (long)(operation_count + index + 1) * (key[node] + 1000000);
        index++;
        node = right[node];
    }
    return checksum;
}
