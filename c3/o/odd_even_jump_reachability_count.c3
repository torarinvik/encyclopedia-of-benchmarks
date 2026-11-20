module odd_even_jump_reachability_count;

const usz MAX_N = 64;
const usz MAX_PARSEABLE = 66;

fn bool comes_before(long* values, usz left, usz right, bool descending) {
    if (values[left] != values[right])
        return descending ? values[left] > values[right] : values[left] < values[right];
    return left < right;
}

fn void build_successors(long* values, usz n, bool descending, long* target) {
    usz[64] order = {};
    usz[64] stack = {};
    for (usz i = 0; i < n; i++) { order[i] = i; target[i] = -1; }
    for (usz i = 1; i < n; i++) {
        usz key = order[i];
        usz position = i;
        while (position > 0 && comes_before(values, key, order[position - 1], descending)) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = key;
    }
    usz stack_size = 0;
    for (usz i = 0; i < n; i++) {
        usz index = order[i];
        while (stack_size > 0 && stack[stack_size - 1] < index) {
            stack_size--;
            target[stack[stack_size]] = (long)index;
        }
        stack[stack_size++] = index;
    }
}

fn long odd_even_jump_reachability_count(long* input, usz length)
    @export("odd_even_jump_reachability_count") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    long* values = input + 1;
    for (usz i = 0; i < n; i++)
        if (values[i] < -1000000 || values[i] > 1000000) return -1;

    long[64] odd_next = {};
    long[64] even_next = {};
    build_successors(values, n, false, &odd_next[0]);
    build_successors(values, n, true, &even_next[0]);
    bool[64] odd = {};
    bool[64] even = {};
    odd[n - 1] = true; even[n - 1] = true;
    for (usz i = n - 1; i > 0;) {
        i--;
        if (odd_next[i] >= 0) odd[i] = even[(usz)odd_next[i]];
        if (even_next[i] >= 0) even[i] = odd[(usz)even_next[i]];
    }
    long count = 0;
    for (usz i = 0; i < n; i++) if (odd[i]) count++;
    return count;
}
