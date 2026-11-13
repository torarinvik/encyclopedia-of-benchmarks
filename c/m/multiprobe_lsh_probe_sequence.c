#include <stddef.h>
#include <stdint.h>

typedef struct { int distance, coordinate, sign; } probe_choice;
typedef struct { int score, count, mask; } probe_item;

static int probe_less(probe_item a, probe_item b) {
    return a.score != b.score ? a.score < b.score :
           a.count != b.count ? a.count < b.count : a.mask < b.mask;
}
static probe_item probe_entry(int mask, const probe_choice *choices, int size) {
    probe_item item = {0, 0, mask};
    for (int i = 0; i < size; ++i) if (mask & (1 << i)) {
        item.score += choices[i].distance * choices[i].distance;
        ++item.count;
    }
    return item;
}
static void probe_push(probe_item *heap, int *size, probe_item item) {
    int at = (*size)++;
    while (at > 0 && probe_less(item, heap[(at-1)/2])) { heap[at] = heap[(at-1)/2]; at = (at-1)/2; }
    heap[at] = item;
}
static probe_item probe_pop(probe_item *heap, int *size) {
    probe_item result = heap[0], last = heap[--*size];
    int at = 0;
    while (2*at+1 < *size) {
        int child = 2*at+1;
        if (child+1 < *size && probe_less(heap[child+1], heap[child])) ++child;
        if (!probe_less(heap[child], last)) break;
        heap[at] = heap[child]; at = child;
    }
    if (*size) heap[at] = last;
    return result;
}

int64_t multiprobe_lsh_probe_sequence(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length < 4 || length > 7 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 1000) return -1;
    int m = (int)input[0], width = (int)input[1], max_probes = 1;
    for (int i = 0; i < m; ++i) max_probes *= 3;
    if (length != (size_t)(3+m) || input[2] < 0 || input[2] >= max_probes) return -1;
    int count = (int)input[2];
    probe_choice choices[8];
    for (int i = 0; i < m; ++i) {
        if (input[3+i] < 0 || input[3+i] > width) return -1;
        choices[2*i] = (probe_choice){(int)input[3+i], i, -1};
        choices[2*i+1] = (probe_choice){width-(int)input[3+i], i, 1};
    }
    for (int i = 1; i < 2*m; ++i) {
        probe_choice v = choices[i]; int j = i;
        while (j > 0 && (choices[j-1].distance > v.distance ||
               (choices[j-1].distance == v.distance && (choices[j-1].coordinate > v.coordinate ||
                (choices[j-1].coordinate == v.coordinate && choices[j-1].sign > v.sign))))) {
            choices[j] = choices[j-1]; --j;
        }
        choices[j] = v;
    }
    probe_item heap[256]; int heap_size = 0, emitted = 0;
    uint8_t staged[80];
    probe_push(heap, &heap_size, probe_entry(1, choices, 2*m));
    while (emitted < count) {
        int mask = probe_pop(heap, &heap_size).mask;
        int top = 0;
        while ((1 << (top+1)) <= mask) ++top;
        if (top+1 < 2*m) {
            probe_push(heap, &heap_size, probe_entry((mask ^ (1 << top)) | (1 << (top+1)), choices, 2*m));
            probe_push(heap, &heap_size, probe_entry(mask | (1 << (top+1)), choices, 2*m));
        }
        int seen = 0, valid = 1;
        for (int i = 0; i < 2*m; ++i) if (mask & (1 << i)) {
            int bit = 1 << choices[i].coordinate;
            if (seen & bit) { valid = 0; break; }
            seen |= bit;
        }
        if (valid) staged[emitted++] = (uint8_t)mask;
    }
    if (!output || capacity < (size_t)count) return -2;
    for (int i = 0; i < count; ++i) output[i] = staged[i];
    return count;
}
