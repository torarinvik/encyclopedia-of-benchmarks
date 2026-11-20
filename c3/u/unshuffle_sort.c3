module unshuffle_sort;

const usz MAX_ITEMS = 1024;
const uint NONE = 1024;

fn bool pile_less(long* values, uint[MAX_ITEMS]* pile_front, uint left, uint right) {
    uint left_node = (*pile_front)[left];
    uint right_node = (*pile_front)[right];
    if (values[left_node] != values[right_node]) return values[left_node] < values[right_node];
    return left < right;
}

fn void sift_down(long* values, uint[MAX_ITEMS]* pile_front, uint[MAX_ITEMS]* heap,
                  uint heap_size, uint position) {
    while (position * 2 + 1 < heap_size) {
        uint child = position * 2 + 1;
        if (child + 1 < heap_size
                && pile_less(values, pile_front, (*heap)[child + 1], (*heap)[child])) child++;
        if (!pile_less(values, pile_front, (*heap)[child], (*heap)[position])) break;
        uint temporary = (*heap)[position];
        (*heap)[position] = (*heap)[child];
        (*heap)[child] = temporary;
        position = child;
    }
}

fn void unshuffle_sort(long* values, long* scratch, usz length) @export("unshuffle_sort") {
    if (values == null || scratch == null || length < 2 || length > MAX_ITEMS) return;
    uint[MAX_ITEMS] previous = zeroed;
    uint[MAX_ITEMS] next = zeroed;
    uint[MAX_ITEMS] pile_front = zeroed;
    uint[MAX_ITEMS] pile_back = zeroed;
    uint[MAX_ITEMS] heap = zeroed;
    uint pile_count = 0;

    for (usz node = 0; node < length; node++) {
        previous[node] = NONE;
        next[node] = NONE;
        uint pile = 0;
        while (pile < pile_count) {
            uint front = pile_front[pile];
            uint back = pile_back[pile];
            if (values[node] <= values[front]) {
                next[node] = front;
                previous[front] = (uint)node;
                pile_front[pile] = (uint)node;
                break;
            }
            if (values[node] >= values[back]) {
                previous[node] = back;
                next[back] = (uint)node;
                pile_back[pile] = (uint)node;
                break;
            }
            pile++;
        }
        if (pile == pile_count) {
            pile_front[pile_count] = (uint)node;
            pile_back[pile_count] = (uint)node;
            pile_count++;
        }
    }

    uint heap_size = 0;
    for (uint pile = 0; pile < pile_count; pile++) {
        uint position = heap_size++;
        heap[position] = pile;
        while (position > 0) {
            uint parent = (position - 1) / 2;
            if (!pile_less(values, &pile_front, heap[position], heap[parent])) break;
            uint temporary = heap[position];
            heap[position] = heap[parent];
            heap[parent] = temporary;
            position = parent;
        }
    }

    usz output = 0;
    while (heap_size > 0) {
        uint pile = heap[0];
        uint node = pile_front[pile];
        scratch[output++] = values[node];
        uint successor = next[node];
        if (successor != NONE) {
            previous[successor] = NONE;
            next[node] = NONE;
            pile_front[pile] = successor;
        } else {
            pile_front[pile] = NONE;
            pile_back[pile] = NONE;
            heap_size--;
            if (heap_size > 0) heap[0] = heap[heap_size];
        }
        if (heap_size > 0) sift_down(values, &pile_front, &heap, heap_size, 0);
    }
    for (usz index = 0; index < length; index++) values[index] = scratch[index];
}
