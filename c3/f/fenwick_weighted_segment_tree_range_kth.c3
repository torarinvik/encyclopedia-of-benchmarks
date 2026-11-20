module fenwick_weighted_segment_tree_range_kth;

const MAX_N = 12;
const MAX_Q = 16;
const VALUE_COUNT = 61;
const NODE_CAPACITY = 1280;
struct Context {
    int[1281] left;
    int[1281] right;
    int[1281] count;
    int[13] roots;
    int[12] current;
    int used;
}

fn int change(Context* ctx, int root, int low, int high, int coordinate, int delta) {
    if (root == 0) { ctx.used++; root = ctx.used; }
    ctx.count[root] += delta;
    if (high - low > 1) {
        int middle = (low + high) / 2;
        if (coordinate < middle)
            ctx.left[root] = change(ctx, ctx.left[root], low, middle, coordinate, delta);
        else
            ctx.right[root] = change(ctx, ctx.right[root], middle, high, coordinate, delta);
    }
    return root;
}

fn void apply(Context* ctx, int n, int position, int value, int delta) {
    int node = position + 1;
    while (node <= n) {
        ctx.roots[node] = change(ctx, ctx.roots[node], 0, VALUE_COUNT, value + 30, delta);
        node += node & -node;
    }
}

fn long fenwick_weighted_segment_tree_range_kth(long* input, usz length) @export("fenwick_weighted_segment_tree_range_kth") {
    if (input == null || length < 3 || length > 79) return -9223372036854775807L - 1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q)
        return -9223372036854775807L - 1;
    int n = (int)input[0], q = (int)input[1];
    if (length != (usz)(2 + n + 4 * q)) return -9223372036854775807L - 1;

    Context ctx = zeroed;
    for (int i = 0; i < n; i++) {
        if (input[2 + i] < -30 || input[2 + i] > 30) return -9223372036854775807L - 1;
        ctx.current[i] = (int)input[2 + i];
        apply(&ctx, n, i, ctx.current[i], 1);
    }
    long checksum = 0;
    int query_number = 0;
    usz cursor = (usz)(2 + n);
    for (int op = 0; op < q; op++) {
        long opcode = input[cursor], first = input[cursor + 1];
        long second = input[cursor + 2], third = input[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 || first >= n || second < -30 || second > 30 || third != 0)
                return -9223372036854775807L - 1;
            int position = (int)first;
            apply(&ctx, n, position, ctx.current[position], -1);
            ctx.current[position] = (int)second;
            apply(&ctx, n, position, ctx.current[position], 1);
        } else if (opcode == 1) {
            if (first < 0 || first >= second || second > n || third < 1 || third > second - first)
                return -9223372036854775807L - 1;
            int[13] left_roots, right_roots;
            int left_size = 0, right_size = 0;
            for (int node = (int)first; node > 0; node -= node & -node)
                left_roots[left_size++] = ctx.roots[node];
            for (int node = (int)second; node > 0; node -= node & -node)
                right_roots[right_size++] = ctx.roots[node];
            int low = 0, high = VALUE_COUNT;
            long rank = third;
            while (high - low > 1) {
                int middle = (low + high) / 2;
                long left_count = 0;
                for (int i = 0; i < right_size; i++) left_count += ctx.count[ctx.left[right_roots[i]]];
                for (int i = 0; i < left_size; i++) left_count -= ctx.count[ctx.left[left_roots[i]]];
                if (rank <= left_count) {
                    for (int i = 0; i < right_size; i++) right_roots[i] = ctx.left[right_roots[i]];
                    for (int i = 0; i < left_size; i++) left_roots[i] = ctx.left[left_roots[i]];
                    high = middle;
                } else {
                    rank -= left_count;
                    for (int i = 0; i < right_size; i++) right_roots[i] = ctx.right[right_roots[i]];
                    for (int i = 0; i < left_size; i++) left_roots[i] = ctx.right[left_roots[i]];
                    low = middle;
                }
            }
            query_number++;
            checksum += (long)query_number * (low - 30);
        } else return -9223372036854775807L - 1;
    }
    return checksum;
}
