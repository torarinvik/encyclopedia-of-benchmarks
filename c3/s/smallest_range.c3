module smallest_range;

fn bool less_head(long[16][16]* values, usz[16]* positions, usz a, usz b) {
    long left = values[a][positions[a]];
    long right = values[b][positions[b]];
    return left < right || (left == right && a < b);
}

fn void sift_down(usz[16]* heap, usz size, usz root, long[16][16]* values, usz[16]* positions) {
    while (true) {
        usz child = root * 2 + 1;
        if (child >= size) return;
        if (child + 1 < size && less_head(values, positions, heap[child + 1], heap[child])) child++;
        if (!less_head(values, positions, heap[child], heap[root])) return;
        usz swap = heap[root]; heap[root] = heap[child]; heap[child] = swap;
        root = child;
    }
}

fn long smallest_range(long* packed, usz length) @export("smallest_range") {
    if (packed == null || length < 2 || length > 273) return -1;
    if (packed[0] < 1 || packed[0] > 16) return -1;
    usz count = (usz)packed[0];
    long[16][16] values;
    usz[16] lengths;
    usz[16] positions;
    usz[16] heap;
    usz offset = 1, total = 0;
    long current_max = -1000000001;
    for (usz i = 0; i < count; i++) {
        if (offset >= length || packed[offset] < 1 || packed[offset] > 16) return -1;
        lengths[i] = (usz)packed[offset]; offset++;
        if (lengths[i] > 256 - total || offset + lengths[i] > length) return -1;
        total += lengths[i];
        for (usz j = 0; j < lengths[i]; j++) {
            long value = packed[offset]; offset++;
            if (value < -1000000000 || value > 1000000000 || (j > 0 && value < values[i][j - 1])) return -1;
            values[i][j] = value;
        }
        heap[i] = i;
        if (values[i][0] > current_max) current_max = values[i][0];
    }
    if (offset != length) return -1;
    usz heap_size = count;
    for (usz i = heap_size / 2; i > 0; i--) sift_down(&heap, heap_size, i - 1, &values, &positions);
    long best_lo = 0, best_hi = 0, best_width = 9223372036854775807;
    while (true) {
        usz list = heap[0];
        long lo = values[list][positions[list]];
        long width = current_max - lo;
        if (width < best_width) { best_width = width; best_lo = lo; best_hi = current_max; }
        positions[list]++;
        if (positions[list] == lengths[list]) break;
        if (values[list][positions[list]] > current_max) current_max = values[list][positions[list]];
        sift_down(&heap, heap_size, 0, &values, &positions);
    }
    return (best_lo + 1000000000) * 2000000001 + best_hi + 1000000000;
}
