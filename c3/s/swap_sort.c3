module swap_sort;

const MAX_VALUES = 256;

fn bool position_less(long* keys, usz* order, usz left, usz right) {
    usz left_index = order[left]; usz right_index = order[right];
    return keys[left_index] < keys[right_index] || (keys[left_index] == keys[right_index] && left_index < right_index);
}

fn void sift_down(long* keys, usz* order, usz heap_length, usz root) {
    while (root < heap_length / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < heap_length && position_less(keys, order, child, child + 1)) child++;
        if (!position_less(keys, order, root, child)) break;
        usz temporary = order[root]; order[root] = order[child]; order[child] = temporary;
        root = child;
    }
}

fn long swap_sort(long* values, usz length) @export("swap_sort") {
    if (length > MAX_VALUES) return -1;
    long[MAX_VALUES] keys;
    usz[MAX_VALUES] order;
    bool[MAX_VALUES] visited;
    for (usz index = 0; index < length; index++) { keys[index] = values[index]; order[index] = index; visited[index] = false; }
    for (usz start = length / 2; start > 0;) { start--; sift_down(&keys[0], &order[0], length, start); }
    for (usz end = length; end > 1;) {
        end--; usz temporary = order[0]; order[0] = order[end]; order[end] = temporary;
        sift_down(&keys[0], &order[0], end, 0);
    }
    for (usz index = 1; index < length; index++) if (keys[order[index - 1]] == keys[order[index]]) return -1;
    usz swaps = 0;
    for (usz start = 0; start < length; start++) {
        if (visited[start]) continue;
        usz node = start; usz cycle_length = 0;
        while (!visited[node]) { visited[node] = true; node = order[node]; cycle_length++; }
        if (cycle_length > 0) swaps += cycle_length - 1;
    }
    return (long)swaps;
}
