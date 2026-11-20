module small_to_large_subtree_color_mode_sum;

const MAX_N = 64;
const CELL_COUNT = MAX_N * MAX_N;

fn void add_color(usz map, usz color, long amount, long* labels,
                  long* frequencies, usz* keys, usz* lengths,
                  long* maximum, long* mode_sum) {
    usz cell = map * MAX_N + color;
    long old = frequencies[cell];
    if (old == 0) {
        keys[map * MAX_N + lengths[map]] = color;
        lengths[map]++;
    }
    if (old > 0 && old == maximum[map]) mode_sum[map] -= labels[color];
    long updated = old + amount;
    if (updated > maximum[map]) {
        maximum[map] = updated;
        mode_sum[map] = labels[color];
    } else if (updated == maximum[map]) {
        mode_sum[map] += labels[color];
    }
    frequencies[cell] = updated;
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long small_to_large_subtree_color_mode_sum(long* input, usz length,
        char* output, usz capacity) @export("small_to_large_subtree_color_mode_sum") {
    if (input == null || length < 2 || length > 129) return -1;
    long nv = input[0];
    if (nv < 1 || nv > MAX_N || length != (usz)(2 * nv)) return -1;
    usz n = (usz)nv;
    usz parent[MAX_N] = zeroed;
    for (usz vertex = 1; vertex < n; vertex++) {
        long p = input[vertex];
        if (p < 0 || p >= (long)vertex) return -1;
        parent[vertex] = (usz)p;
    }
    long sorted[MAX_N] = zeroed;
    for (usz vertex = 0; vertex < n; vertex++) {
        long color = input[n + vertex];
        if (color < -1000 || color > 1000) return -1;
        sorted[vertex] = color;
    }
    for (usz i = 1; i < n; i++) {
        long value = sorted[i];
        usz j = i;
        while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; j--; }
        sorted[j] = value;
    }
    long labels[MAX_N] = zeroed;
    usz distinct = 0;
    for (usz i = 0; i < n; i++) {
        if (distinct == 0 || labels[distinct - 1] != sorted[i]) {
            labels[distinct] = sorted[i];
            distinct++;
        }
    }
    usz color_index[MAX_N] = zeroed;
    for (usz vertex = 0; vertex < n; vertex++) {
        usz index = 0;
        while (labels[index] != input[n + vertex]) index++;
        color_index[vertex] = index;
    }
    if (output == null || capacity < 8 * n) return -2;

    long frequencies[CELL_COUNT] = zeroed;
    usz keys[CELL_COUNT] = zeroed;
    usz map_lengths[MAX_N] = zeroed, map_id[MAX_N] = zeroed;
    long maximum[MAX_N] = zeroed, mode_sum[MAX_N] = zeroed, answers[MAX_N] = zeroed;
    usz vertex = n;
    while (vertex > 0) {
        vertex--;
        usz largest = n;
        for (usz child = vertex + 1; child < n; child++) {
            if (parent[child] == vertex &&
                (largest == n || map_lengths[map_id[child]] > map_lengths[map_id[largest]])) largest = child;
        }
        usz map = largest == n ? vertex : map_id[largest];
        for (usz child = vertex + 1; child < n; child++) {
            if (parent[child] != vertex || child == largest) continue;
            usz small = map_id[child];
            for (usz i = 0; i < map_lengths[small]; i++) {
                usz color = keys[small * MAX_N + i];
                long amount = frequencies[small * MAX_N + color];
                add_color(map, color, amount, labels, frequencies, keys, map_lengths, maximum, mode_sum);
            }
        }
        add_color(map, color_index[vertex], 1, labels, frequencies, keys, map_lengths, maximum, mode_sum);
        map_id[vertex] = map;
        answers[vertex] = mode_sum[map];
    }
    for (usz vertex = 0; vertex < n; vertex++) put_i64(output, vertex * 8, answers[vertex]);
    return (long)(8 * n);
}
