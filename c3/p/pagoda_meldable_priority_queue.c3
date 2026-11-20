module pagoda_meldable_priority_queue;

const int MAX_QUEUES = 8;
const int MAX_OPERATIONS = 64;
const usz MAX_PARSEABLE_WORDS = 259;
const long NIL = -1;

fn int branch_stack(long root, bool right_branch, usz node_count,
                    long* leftmost, long* rightmost, long* stack) {
    long node = right_branch ? rightmost[root] : leftmost[root];
    if (node < 0 || node >= (long)node_count) return -1;
    int count = 0;
    while (count < (int)node_count) {
        stack[count] = node;
        count += 1;
        if (node == root) return count;
        node = right_branch ? rightmost[node] : leftmost[node];
        if (node < 0 || node >= (long)node_count) return -1;
    }
    return -1;
}

fn long pagoda_meld(long g_root, long d_root, usz node_count, long* keys,
                    long* leftmost, long* rightmost) {
    if (g_root < 0) return d_root;
    if (d_root < 0) return g_root;
    long[MAX_OPERATIONS] g_branch;
    long[MAX_OPERATIONS] d_branch;
    int g_count = branch_stack(g_root, true, node_count, leftmost, rightmost, &g_branch[0]);
    int d_count = branch_stack(d_root, false, node_count, leftmost, rightmost, &d_branch[0]);
    if (g_count < 1 || d_count < 1) return -2;

    int gi = 0, di = 0;
    long central = NIL, central_left = NIL, central_right = NIL;
    while (gi < g_count || di < d_count) {
        bool take_g = di >= d_count ||
            (gi < g_count && keys[g_branch[gi]] > keys[d_branch[di]]);
        long node;
        long kept_extreme;
        if (take_g) {
            node = g_branch[gi];
            gi += 1;
            kept_extreme = leftmost[node];
        } else {
            node = d_branch[di];
            di += 1;
            kept_extreme = rightmost[node];
        }
        if (central >= 0) {
            if (take_g) {
                rightmost[central] = node;
                leftmost[central] = central_left == central ? NIL : central_left;
            } else {
                leftmost[central] = node;
                rightmost[central] = central_right == central ? NIL : central_right;
            }
        }
        long new_left = take_g
            ? (kept_extreme < 0 ? node : kept_extreme)
            : (central >= 0 ? central_left : node);
        long new_right = take_g
            ? (central >= 0 ? central_right : node)
            : (kept_extreme < 0 ? node : kept_extreme);
        leftmost[node] = new_left;
        rightmost[node] = new_right;
        central = node;
        central_left = new_left;
        central_right = new_right;
    }
    return central;
}

fn long pagoda_extract_min(long root, usz node_count, long* keys,
                           long* leftmost, long* rightmost) {
    long old_leftmost = leftmost[root];
    long old_rightmost = rightmost[root];
    long left_child = NIL, right_child = NIL;
    if (old_leftmost != root) {
        long node = old_leftmost;
        int steps = 0;
        while (node >= 0 && node < (long)node_count && leftmost[node] != root && steps < (int)node_count) {
            node = leftmost[node];
            steps += 1;
        }
        if (node < 0 || node >= (long)node_count || leftmost[node] != root) return -2;
        left_child = node;
    }
    if (old_rightmost != root) {
        long node = old_rightmost;
        int steps = 0;
        while (node >= 0 && node < (long)node_count && rightmost[node] != root && steps < (int)node_count) {
            node = rightmost[node];
            steps += 1;
        }
        if (node < 0 || node >= (long)node_count || rightmost[node] != root) return -2;
        right_child = node;
    }
    if (left_child >= 0) {
        leftmost[left_child] = old_leftmost;
        if (rightmost[left_child] < 0) rightmost[left_child] = left_child;
    }
    if (right_child >= 0) {
        rightmost[right_child] = old_rightmost;
        if (leftmost[right_child] < 0) leftmost[right_child] = right_child;
    }
    long new_root = pagoda_meld(right_child, left_child, node_count, keys, leftmost, rightmost);
    leftmost[root] = NIL;
    rightmost[root] = NIL;
    return new_root;
}

fn long pagoda_meldable_priority_queue(long* input, usz length) @export("pagoda_meldable_priority_queue") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_WORDS) return -1;
    long raw_queues = input[0], raw_operations = input[1];
    if (raw_queues < 1 || raw_queues > MAX_QUEUES || raw_operations < 0 ||
        raw_operations > MAX_OPERATIONS || length != (usz)(2 + 4 * raw_operations) || length > 258)
        return -1;

    long[MAX_OPERATIONS] keys = zeroed;
    long[MAX_OPERATIONS] leftmost;
    long[MAX_OPERATIONS] rightmost;
    long[MAX_QUEUES] roots;
    for (int i = 0; i < MAX_OPERATIONS; i += 1) leftmost[i] = rightmost[i] = NIL;
    for (int i = 0; i < MAX_QUEUES; i += 1) roots[i] = NIL;
    usz node_count = 0;
    long result = 0;

    for (long op = 0; op < raw_operations; op += 1) {
        usz offset = (usz)(2 + 4 * op);
        long opcode = input[offset];
        long first = input[offset + 1];
        long second = input[offset + 2];
        long priority = input[offset + 3];
        if (opcode == 1) {
            if (first < 0 || first >= raw_queues || second != 0 || priority < -1000 ||
                priority > 1000 || node_count >= MAX_OPERATIONS) return -1;
            for (usz i = 0; i < node_count; i += 1) if (keys[i] == priority) return -1;
            long node = (long)node_count;
            node_count += 1;
            keys[node] = priority;
            leftmost[node] = rightmost[node] = node;
            long merged = pagoda_meld(roots[first], node, node_count, &keys[0], &leftmost[0], &rightmost[0]);
            if (merged < 0) return -1;
            roots[first] = merged;
        } else if (opcode == 2) {
            if (first < 0 || first >= raw_queues || second < 0 || second >= raw_queues ||
                first == second || priority != 0) return -1;
            long merged = pagoda_meld(roots[first], roots[second], node_count, &keys[0], &leftmost[0], &rightmost[0]);
            if (merged == -2) return -1;
            roots[first] = merged;
            roots[second] = NIL;
        } else if (opcode == 3 || opcode == 4) {
            if (first < 0 || first >= raw_queues || second != 0 || priority != 0 || roots[first] < 0)
                return -1;
            long root = roots[first];
            result += (op + 1) * (keys[root] + 1001);
            if (opcode == 4) {
                long new_root = pagoda_extract_min(root, node_count, &keys[0], &leftmost[0], &rightmost[0]);
                if (new_root == -2) return -1;
                roots[first] = new_root;
            }
        } else return -1;
    }
    return result;
}
