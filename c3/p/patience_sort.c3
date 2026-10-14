module patience_sort;

const MAX_INPUT_LENGTH = 1024;

fn bool node_less(long* keys, usz left, usz right) {
    return keys[left] < keys[right] || (keys[left] == keys[right] && left < right);
}

fn void sift_down(long* keys, usz* heap, usz heap_length, usz root) {
    while (root < heap_length / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < heap_length && node_less(keys, heap[child + 1], heap[child])) child++;
        if (!node_less(keys, heap[child], heap[root])) break;
        usz temporary = heap[root]; heap[root] = heap[child]; heap[child] = temporary;
        root = child;
    }
}

fn void patience_sort(long* values, usz length) @export("patience_sort") {
    if (length < 2 || length > MAX_INPUT_LENGTH) return;
    long[MAX_INPUT_LENGTH] keys;
    usz[MAX_INPUT_LENGTH] pile_tops, next_in_pile, heap;
    usz pile_count = 0;
    for (usz index = 0; index < length; index++) {
        keys[index] = values[index];
        next_in_pile[index] = length;
        usz low = 0; usz high = pile_count;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (keys[pile_tops[middle]] >= keys[index]) { high = middle; }
            else { low = middle + 1; }
        }
        if (low == pile_count) { pile_tops[pile_count] = index; pile_count++; }
        else { next_in_pile[index] = pile_tops[low]; pile_tops[low] = index; }
    }
    for (usz pile = 0; pile < pile_count; pile++) heap[pile] = pile_tops[pile];
    usz heap_length = pile_count;
    for (usz start = heap_length / 2; start > 0;) { start--; sift_down(&keys[0], &heap[0], heap_length, start); }
    usz output = 0;
    while (heap_length > 0) {
        usz node = heap[0];
        values[output++] = keys[node];
        usz successor = next_in_pile[node];
        if (successor < length) { heap[0] = successor; }
        else { heap_length--; if (heap_length > 0) heap[0] = heap[heap_length]; }
        if (heap_length > 0) sift_down(&keys[0], &heap[0], heap_length, 0);
    }
}
