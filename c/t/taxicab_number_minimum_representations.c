#include <stddef.h>
#include <stdint.h>

enum { TAXICAB_MAX_ROOT = 444, TAXICAB_MAX_PARSEABLE_LENGTH = 2 };

typedef struct {
    int32_t sum;
    int32_t a;
    int32_t b;
} TaxicabNode;

static int node_less(TaxicabNode left, TaxicabNode right) {
    if (left.sum != right.sum) return left.sum < right.sum;
    if (left.a != right.a) return left.a < right.a;
    return left.b < right.b;
}

static void heap_push(TaxicabNode heap[TAXICAB_MAX_ROOT], int32_t *size,
                      TaxicabNode node) {
    int32_t index = (*size)++;
    while (index > 0) {
        int32_t parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

static TaxicabNode heap_pop(TaxicabNode heap[TAXICAB_MAX_ROOT], int32_t *size) {
    TaxicabNode result = heap[0];
    TaxicabNode last = heap[--(*size)];
    if (*size == 0) return result;
    int32_t index = 0;
    while (2 * index + 1 < *size) {
        int32_t child = 2 * index + 1;
        if (child + 1 < *size && node_less(heap[child + 1], heap[child])) ++child;
        if (!node_less(heap[child], last)) break;
        heap[index] = heap[child];
        index = child;
    }
    heap[index] = last;
    return result;
}

static int32_t cube(int32_t value) { return value * value * value; }

static int64_t taxicab_search(int32_t ways) {
    TaxicabNode heap[TAXICAB_MAX_ROOT];
    int32_t size = 0;
    for (int32_t a = 1; a <= TAXICAB_MAX_ROOT; ++a) {
        int32_t value = cube(a);
        heap_push(heap, &size, (TaxicabNode){2 * value, a, a});
    }
    while (size > 0) {
        TaxicabNode first = heap_pop(heap, &size);
        int32_t total = first.sum;
        int32_t count = 1;
        if (first.b < TAXICAB_MAX_ROOT) {
            int32_t next_b = first.b + 1;
            heap_push(heap, &size, (TaxicabNode){cube(first.a) + cube(next_b), first.a, next_b});
        }
        while (size > 0 && heap[0].sum == total) {
            TaxicabNode equal = heap_pop(heap, &size);
            ++count;
            if (equal.b < TAXICAB_MAX_ROOT) {
                int32_t next_b = equal.b + 1;
                heap_push(heap, &size, (TaxicabNode){cube(equal.a) + cube(next_b), equal.a, next_b});
            }
        }
        if (count >= ways) return total;
    }
    return -1;
}

int64_t taxicab_number_minimum_representations(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > TAXICAB_MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || (input[0] != 2 && input[0] != 3)) return -1;
    return taxicab_search((int32_t)input[0]);
}
