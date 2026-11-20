module divide_combine_tree_incremental;

const usz DCT_MAX_N = 16;
const usz DCT_MAX_NODES = 31;
const usz DCT_MAX_PARSEABLE_LENGTH = 18;

fn void dct_add(int node, int left, int right, int ql, int qr, int delta,
                int[] minimum, int[] lazy) {
    if (ql <= left && right <= qr) {
        minimum[node] += delta;
        lazy[node] += delta;
        return;
    }
    int middle = (left + right) / 2;
    if (lazy[node] != 0) {
        int tag = lazy[node];
        minimum[node * 2] += tag; minimum[node * 2 + 1] += tag;
        lazy[node * 2] += tag; lazy[node * 2 + 1] += tag;
        lazy[node] = 0;
    }
    if (ql <= middle && qr >= left) dct_add(node * 2, left, middle, ql, qr, delta, minimum, lazy);
    if (qr > middle && ql <= right) dct_add(node * 2 + 1, middle + 1, right, ql, qr, delta, minimum, lazy);
    minimum[node] = minimum[node * 2] < minimum[node * 2 + 1]
        ? minimum[node * 2] : minimum[node * 2 + 1];
}

fn int dct_first_zero(int node, int left, int right, int[] minimum) {
    if (left == right) return left;
    int middle = (left + right) / 2;
    if (minimum[node * 2] == 0) return dct_first_zero(node * 2, left, middle, minimum);
    return dct_first_zero(node * 2 + 1, middle + 1, right, minimum);
}

fn bool dct_connected(int left, int right, int[] logs, int[] range_min, int[] range_max) {
    int level = logs[right - left + 1];
    int span = 1 << level;
    int other = right - span + 1;
    int low_a = range_min[level * 16 + left], low_b = range_min[level * 16 + other];
    int high_a = range_max[level * 16 + left], high_b = range_max[level * 16 + other];
    int low = low_a < low_b ? low_a : low_b;
    int high = high_a > high_b ? high_a : high_b;
    return high - low == right - left;
}

fn int dct_new_node(int left, int right, int combine, int last_left, int* count,
                    int[] node_left, int[] node_right, int[] node_combine, int[] node_last) {
    int id = *count;
    *count += 1;
    node_left[id] = left; node_right[id] = right;
    node_combine[id] = combine; node_last[id] = last_left;
    return id;
}

fn long divide_combine_tree_incremental(long* input, usz length)
    @export("divide_combine_tree_incremental")
{
    if (input == null || length < 1 || length > DCT_MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)DCT_MAX_N || length != (usz)n_value + 1) return -1;
    int n = (int)n_value;
    int permutation[DCT_MAX_N]; int seen[DCT_MAX_N];
    for (int i = 0; i < n; i++) seen[i] = 0;
    for (int i = 0; i < n; i++) {
        long value = input[i + 1];
        if (value < 0 || value >= n || seen[(int)value]) return -1;
        permutation[i] = (int)value; seen[(int)value] = 1;
    }
    int logs[DCT_MAX_N + 1]; logs[0] = 0; logs[1] = 0;
    for (int i = 2; i <= n; i++) logs[i] = logs[i / 2] + 1;
    int levels = logs[n] + 1;
    int range_min[DCT_MAX_N * DCT_MAX_N]; int range_max[DCT_MAX_N * DCT_MAX_N];
    for (int i = 0; i < n; i++) { range_min[i] = permutation[i]; range_max[i] = permutation[i]; }
    for (int level = 1; level < levels; level++) {
        int half = 1 << (level - 1); int width = half * 2;
        for (int start = 0; start + width <= n; start++) {
            int a = range_min[(level - 1) * 16 + start], b = range_min[(level - 1) * 16 + start + half];
            range_min[level * 16 + start] = a < b ? a : b;
            a = range_max[(level - 1) * 16 + start]; b = range_max[(level - 1) * 16 + start + half];
            range_max[level * 16 + start] = a > b ? a : b;
        }
    }

    int segment_min[68]; int lazy[68];
    for (int i = 0; i < 68; i++) { segment_min[i] = 0; lazy[i] = 0; }
    int node_left[DCT_MAX_NODES], node_right[DCT_MAX_NODES], node_combine[DCT_MAX_NODES], node_last[DCT_MAX_NODES];
    int node_stack[DCT_MAX_N], min_stack[DCT_MAX_N], max_stack[DCT_MAX_N];
    int node_top = 0, min_top = 0, max_top = 0, node_count = 0;
    for (int end = 0; end < n; end++) {
        int value = permutation[end];
        while (min_top > 0 && permutation[min_stack[min_top - 1]] >= value) {
            int position = min_stack[--min_top]; int start = min_top > 0 ? min_stack[min_top - 1] + 1 : 0;
            dct_add(1, 0, n - 1, start, position, permutation[position], segment_min, lazy);
        }
        while (max_top > 0 && permutation[max_stack[max_top - 1]] <= value) {
            int position = max_stack[--max_top]; int start = max_top > 0 ? max_stack[max_top - 1] + 1 : 0;
            dct_add(1, 0, n - 1, start, position, -permutation[position], segment_min, lazy);
        }
        int start = min_top > 0 ? min_stack[min_top - 1] + 1 : 0;
        dct_add(1, 0, n - 1, start, end, -value, segment_min, lazy); min_stack[min_top++] = end;
        start = max_top > 0 ? max_stack[max_top - 1] + 1 : 0;
        dct_add(1, 0, n - 1, start, end, value, segment_min, lazy); max_stack[max_top++] = end;
        int leftmost = dct_first_zero(1, 0, n - 1, segment_min);
        int current = dct_new_node(end, end, 0, 0, &node_count, node_left, node_right, node_combine, node_last);
        while (node_top > 0 && node_left[node_stack[node_top - 1]] >= leftmost) {
            int top = node_stack[node_top - 1];
            if (node_combine[top] && dct_connected(node_last[top], end, logs, range_min, range_max)) {
                node_right[top] = end; node_last[top] = node_left[current]; current = node_stack[--node_top];
            } else if (dct_connected(node_left[top], end, logs, range_min, range_max)) {
                int merged = dct_new_node(node_left[top], end, 1, node_left[current], &node_count,
                    node_left, node_right, node_combine, node_last);
                --node_top; current = merged;
            } else {
                int merged = dct_new_node(-1, end, 0, 0, &node_count, node_left, node_right, node_combine, node_last);
                do { --node_top; }
                while (node_top > 0 && !dct_connected(node_left[node_stack[node_top - 1]], end, logs, range_min, range_max));
                if (node_top == 0) return -1;
                int base = node_stack[--node_top]; node_left[merged] = node_left[base]; current = merged;
            }
        }
        node_stack[node_top++] = current;
        dct_add(1, 0, n - 1, 0, end, -1, segment_min, lazy);
    }
    for (int i = 1; i < node_count; i++) {
        int left = node_left[i], right = node_right[i], j = i;
        while (j > 0 && (node_left[j - 1] > left || (node_left[j - 1] == left && node_right[j - 1] > right))) {
            node_left[j] = node_left[j - 1]; node_right[j] = node_right[j - 1]; --j;
        }
        node_left[j] = left; node_right[j] = right;
    }
    long checksum = 0;
    for (int i = 0; i < node_count; i++)
        checksum += (long)(i + 1) * ((long)(node_left[i] + 1) * (n + 1) + node_right[i] + 1);
    return checksum;
}
