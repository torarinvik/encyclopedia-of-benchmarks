module fibonacci_heap;

const usz MAX_NODES = 128;

struct FibNode {
    long key;
    int parent;
    int child;
    int left;
    int right;
    int degree;
}

fn void add_root(FibNode* nodes, int* minimum, int node) {
    nodes[node].parent = -1;
    if (*minimum < 0) {
        nodes[node].left = node; nodes[node].right = node; *minimum = node;
    } else {
        int m = *minimum;
        int r = nodes[m].right;
        nodes[node].left = m; nodes[node].right = r;
        nodes[m].right = node; nodes[r].left = node;
        if (nodes[node].key < nodes[m].key) *minimum = node;
    }
}

fn void remove_circle(FibNode* nodes, int node) {
    nodes[nodes[node].left].right = nodes[node].right;
    nodes[nodes[node].right].left = nodes[node].left;
}

fn void link_child(FibNode* nodes, int parent, int child) {
    nodes[child].parent = parent;
    if (nodes[parent].child < 0) {
        nodes[parent].child = child;
        nodes[child].left = child; nodes[child].right = child;
    } else {
        int c = nodes[parent].child;
        int r = nodes[c].right;
        nodes[child].left = c; nodes[child].right = r;
        nodes[c].right = child; nodes[r].left = child;
    }
    nodes[parent].degree++;
}

fn long fibonacci_heap(long* values, usz length, char* output, usz output_capacity)
        @export("fibonacci_heap") {
    if ((values == null && length > 0) || length > MAX_NODES) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < -2147483648 || values[i] > 2147483647) return -1;
    usz output_length = length * 8;
    if (output_capacity < output_length || (length > 0 && output == null)) return -2;
    FibNode[MAX_NODES] nodes;
    int minimum = -1;
    for (usz i = 0; i < length; i++) {
        nodes[i].key = values[i]; nodes[i].child = -1; nodes[i].degree = 0;
        add_root(&nodes[0], &minimum, (int)i);
    }
    usz extracted = 0;
    while (minimum >= 0) {
        int z = minimum;
        long key = nodes[z].key;
        if (nodes[z].child >= 0) {
            int c = nodes[z].child;
            int[MAX_NODES] kids; int kid_count = 0; int next = c;
            do { kids[kid_count++] = next; next = nodes[next].right; } while (next != c);
            for (int j = 0; j < kid_count; j++) {
                remove_circle(&nodes[0], kids[j]);
                add_root(&nodes[0], &minimum, kids[j]);
            }
            nodes[z].child = -1; nodes[z].degree = 0;
        }
        bool was_single = nodes[z].right == z;
        remove_circle(&nodes[0], z);
        minimum = was_single ? -1 : nodes[z].right;
        if (minimum >= 0) {
            int[MAX_NODES] table;
            for (int k = 0; k < (int)MAX_NODES; k++) table[k] = -1;
            int[MAX_NODES] roots; int count = 0;
            int x = minimum;
            do { roots[count++] = x; x = nodes[x].right; } while (x != minimum);
            for (int ri = 0; ri < count; ri++) {
                x = roots[ri]; int d = nodes[x].degree;
                if (nodes[x].parent >= 0) continue;
                while (table[d] >= 0) {
                    int y = table[d];
                    if (nodes[y].key < nodes[x].key) { int tmp = x; x = y; y = tmp; }
                    remove_circle(&nodes[0], y); link_child(&nodes[0], x, y);
                    table[d] = -1; d = nodes[x].degree;
                }
                table[d] = x;
            }
            minimum = -1;
            for (int k = 0; k < (int)MAX_NODES; k++) if (table[k] >= 0) {
                int q = table[k]; nodes[q].left = q; nodes[q].right = q; add_root(&nodes[0], &minimum, q);
            }
        }
        ulong bits = (ulong)key;
        for (int b = 0; b < 8; b++) output[extracted * 8 + (usz)b] = (char)((bits >> (b * 8)) & 255ul);
        extracted++;
    }
    return (long)(extracted * 8);
}
