module mccat_qbsort;
const usz MAX_ITEMS = 32;
fn void bubble(int* a, usz n) {
    usz end = n;
    while (end > 1) { end--; usz i = 0; while (i < end) { if (a[i + 1] < a[i]) { int t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; } i++; } }
}
fn int quick(int head, int* nodes, int* links, usz* used) {
    if (head < 0) return -1;
    int pivot = nodes[head], lower = -1, upper = -1, current = links[head];
    while (current >= 0) {
        int value = nodes[current], following = links[current];
        int created = (int)*used; *used += 1; nodes[created] = value;
        if (value < pivot) { links[created] = lower; lower = created; }
        else { links[created] = upper; upper = created; }
        current = following;
    }
    int sorted_upper = quick(upper, nodes, links, used);
    int sorted_lower = quick(lower, nodes, links, used);
    int pivot_node = (int)*used; *used += 1;
    nodes[pivot_node] = pivot; links[pivot_node] = sorted_upper;
    if (sorted_lower < 0) return pivot_node;
    int tail = sorted_lower;
    while (links[tail] >= 0) tail = links[tail];
    links[tail] = pivot_node;
    return sorted_lower;
}
fn void put_le(uint8* out, usz i, int value) { uint32 bits = (uint32)value; for (usz b = 0; b < 4; b++) { out[4 * i + b] = (uint8)(bits >> (8 * b)); } }
fn long mccat_qbsort(long* input, usz length, uint8* output, usz capacity) @export("mccat_qbsort") {
    if (input == null || length < 3 || length > 34) { return -1; }
    long mode = input[0], cv = input[1]; if ((mode != 0 && mode != 1) || cv < 1 || cv > 32) { return -1; }
    usz n = (usz)cv; if (length != n + 2) { return -1; }
    int[32] values = {0}; for (usz i = 0; i < n; i++) { if (input[i + 2] < -2147483648 || input[i + 2] > 2147483647) { return -1; } values[i] = (int)input[i + 2]; }
    for (usz pass = 0; pass < 1000; pass++) {
        for (usz i = 0; i < n; i++) { values[i] = (int)input[i + 2]; }
        if (mode == 0) { bubble(&values[0], n); }
        else {
            int[560] nodes = {0}, links = {0}; usz used = n;
            for (usz i = 0; i < n; i++) { nodes[i] = values[i]; links[i] = i + 1 < n ? (int)(i + 1) : -1; }
            int current = quick(0, &nodes[0], &links[0], &used); usz i = 0;
            while (current >= 0) { values[i++] = nodes[current]; current = links[current]; }
        }
    }
    usz need = n * 4; if (output == null || capacity < need) { return -2; }
    for (usz i = 0; i < n; i++) { put_le(output, i, values[i]); } return (long)need;
}
