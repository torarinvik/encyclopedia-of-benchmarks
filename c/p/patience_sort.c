/* Patience sorting with lower-bound piles and a binary min-heap merge. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 1024

static int node_less(const int64_t *keys, size_t left, size_t right)
{
    return keys[left] < keys[right] || (keys[left] == keys[right] && left < right);
}

static void sift_down(const int64_t *keys, size_t *heap, size_t heap_length, size_t root)
{
    while (root < heap_length / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < heap_length && node_less(keys, heap[child + 1], heap[child])) ++child;
        if (!node_less(keys, heap[child], heap[root])) break;
        const size_t temporary = heap[root];
        heap[root] = heap[child];
        heap[child] = temporary;
        root = child;
    }
}

void patience_sort(int64_t *values, size_t length)
{
    if (length < 2 || length > MAX_INPUT_LENGTH) return;

    int64_t keys[MAX_INPUT_LENGTH];
    size_t pile_tops[MAX_INPUT_LENGTH];
    size_t next_in_pile[MAX_INPUT_LENGTH];
    size_t heap[MAX_INPUT_LENGTH];
    size_t pile_count = 0;

    for (size_t index = 0; index < length; ++index) {
        keys[index] = values[index];
        next_in_pile[index] = length;
        size_t low = 0;
        size_t high = pile_count;
        while (low < high) {
            const size_t middle = low + (high - low) / 2;
            if (keys[pile_tops[middle]] >= keys[index]) high = middle;
            else low = middle + 1;
        }
        if (low == pile_count) {
            pile_tops[pile_count++] = index;
        } else {
            next_in_pile[index] = pile_tops[low];
            pile_tops[low] = index;
        }
    }

    for (size_t pile = 0; pile < pile_count; ++pile) heap[pile] = pile_tops[pile];
    size_t heap_length = pile_count;
    for (size_t start = heap_length / 2; start > 0;) {
        --start;
        sift_down(keys, heap, heap_length, start);
    }

    size_t output = 0;
    while (heap_length > 0) {
        const size_t node = heap[0];
        values[output++] = keys[node];
        const size_t successor = next_in_pile[node];
        if (successor < length) {
            heap[0] = successor;
        } else {
            --heap_length;
            if (heap_length > 0) heap[0] = heap[heap_length];
        }
        if (heap_length > 0) sift_down(keys, heap, heap_length, 0);
    }
}
