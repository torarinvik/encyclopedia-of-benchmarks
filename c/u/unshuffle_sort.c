#include <stddef.h>
#include <stdint.h>

#define UNSHUFFLE_MAX_ITEMS 1024
#define UNSHUFFLE_NONE UNSHUFFLE_MAX_ITEMS

static int pile_less(const int64_t *values, const uint32_t *pile_front,
                     uint32_t left, uint32_t right) {
    const uint32_t left_node = pile_front[left];
    const uint32_t right_node = pile_front[right];
    if (values[left_node] != values[right_node]) return values[left_node] < values[right_node];
    return left < right;
}

static void heap_sift_down(const int64_t *values, const uint32_t *pile_front,
                           uint32_t *heap,
                           uint32_t heap_size, uint32_t position) {
    while (position * 2 + 1 < heap_size) {
        uint32_t child = position * 2 + 1;
        if (child + 1 < heap_size
                && pile_less(values, pile_front, heap[child + 1], heap[child]))
            child++;
        if (!pile_less(values, pile_front, heap[child], heap[position])) break;
        const uint32_t temporary = heap[position];
        heap[position] = heap[child];
        heap[child] = temporary;
        position = child;
    }
}

void unshuffle_sort(int64_t *values, int64_t *scratch, size_t length) {
    if (values == NULL || scratch == NULL || length < 2 || length > UNSHUFFLE_MAX_ITEMS) return;

    uint32_t previous[UNSHUFFLE_MAX_ITEMS];
    uint32_t next[UNSHUFFLE_MAX_ITEMS];
    uint32_t pile_front[UNSHUFFLE_MAX_ITEMS];
    uint32_t pile_back[UNSHUFFLE_MAX_ITEMS];
    uint32_t heap[UNSHUFFLE_MAX_ITEMS];
    uint32_t pile_count = 0;

    for (uint32_t node = 0; node < (uint32_t)length; ++node) {
        previous[node] = UNSHUFFLE_NONE;
        next[node] = UNSHUFFLE_NONE;
        uint32_t pile = 0;
        while (pile < pile_count) {
            const uint32_t front = pile_front[pile];
            const uint32_t back = pile_back[pile];
            if (values[node] <= values[front]) {
                next[node] = front;
                previous[front] = node;
                pile_front[pile] = node;
                break;
            }
            if (values[node] >= values[back]) {
                previous[node] = back;
                next[back] = node;
                pile_back[pile] = node;
                break;
            }
            pile++;
        }
        if (pile == pile_count) {
            pile_front[pile_count] = node;
            pile_back[pile_count] = node;
            pile_count++;
        }
    }

    uint32_t heap_size = 0;
    for (uint32_t pile = 0; pile < pile_count; ++pile) {
        uint32_t position = heap_size++;
        heap[position] = pile;
        while (position > 0) {
            const uint32_t parent = (position - 1) / 2;
            if (!pile_less(values, pile_front, heap[position], heap[parent])) break;
            const uint32_t temporary = heap[position];
            heap[position] = heap[parent];
            heap[parent] = temporary;
            position = parent;
        }
    }

    size_t output = 0;
    while (heap_size > 0) {
        const uint32_t pile = heap[0];
        const uint32_t node = pile_front[pile];
        scratch[output++] = values[node];
        const uint32_t successor = next[node];
        if (successor != UNSHUFFLE_NONE) {
            previous[successor] = UNSHUFFLE_NONE;
            next[node] = UNSHUFFLE_NONE;
            pile_front[pile] = successor;
        } else {
            pile_front[pile] = UNSHUFFLE_NONE;
            pile_back[pile] = UNSHUFFLE_NONE;
            heap_size--;
            if (heap_size > 0) heap[0] = heap[heap_size];
        }
        if (heap_size > 0) heap_sift_down(values, pile_front, heap, heap_size, 0);
    }
    for (size_t index = 0; index < length; ++index) values[index] = scratch[index];
}
