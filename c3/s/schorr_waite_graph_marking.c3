module schorr_waite_graph_marking;

fn long schorr_waite_graph_marking(long* input, usz length)
    @export("schorr_waite_graph_marking") {
    if (input == null || length < 4 || length > 66) return -1;

    long node_count_value = input[0];
    long root = input[1];
    if (node_count_value < 1 || node_count_value > 32) return -1;
    usz node_count = (usz)node_count_value;
    if (length != 2 + 2 * node_count || root < 0 || root >= node_count_value) {
        return -1;
    }

    long[32] left = {};
    long[32] right = {};
    bool[32] marked = {};
    bool[32] phase = {};
    for (usz node = 0; node < node_count; node += 1) {
        long left_child = input[2 + 2 * node];
        long right_child = input[3 + 2 * node];
        if (left_child < -1 || left_child >= node_count_value
            || right_child < -1 || right_child >= node_count_value) {
            return -1;
        }
        left[node] = left_child;
        right[node] = right_child;
    }

    long parent = -1;
    long current = root;
    long temporary;
    while (parent != -1 || (current != -1 && !marked[(usz)current])) {
        if (current == -1 || marked[(usz)current]) {
            usz frame = (usz)parent;
            if (phase[frame]) {
                temporary = current;
                current = parent;
                parent = right[frame];
                right[frame] = temporary;
            } else {
                temporary = current;
                current = right[frame];
                right[frame] = left[frame];
                left[frame] = temporary;
                phase[frame] = true;
            }
        } else {
            temporary = parent;
            parent = current;
            current = left[(usz)parent];
            left[(usz)parent] = temporary;
            marked[(usz)parent] = true;
            phase[(usz)parent] = false;
        }
    }

    ulong reachable = 0;
    for (usz node = 0; node < node_count; node += 1) {
        if (marked[node]) reachable |= 1UL << node;
    }
    return (long)reachable;
}
