module taxicab_number_minimum_representations;

const int MAX_ROOT = 444;
const usz MAX_PARSEABLE_LENGTH = 2;

struct TaxicabNode { int sum; int a; int b; }

fn bool node_less(TaxicabNode left, TaxicabNode right) {
    if (left.sum != right.sum) return left.sum < right.sum;
    if (left.a != right.a) return left.a < right.a;
    return left.b < right.b;
}

fn void heap_push(TaxicabNode* heap, int* size, TaxicabNode node) {
    int index = size[0]++;
    while (index > 0) {
        int parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

fn TaxicabNode heap_pop(TaxicabNode* heap, int* size) {
    TaxicabNode result = heap[0];
    TaxicabNode last = heap[--size[0]];
    if (size[0] == 0) return result;
    int index = 0;
    while (2 * index + 1 < size[0]) {
        int child = 2 * index + 1;
        if (child + 1 < size[0] && node_less(heap[child + 1], heap[child])) child++;
        if (!node_less(heap[child], last)) break;
        heap[index] = heap[child];
        index = child;
    }
    heap[index] = last;
    return result;
}

fn int cube(int value) { return value * value * value; }

fn long taxicab_search(int ways) {
    TaxicabNode[MAX_ROOT] heap;
    int size = 0;
    for (int a = 1; a <= MAX_ROOT; a++) {
        heap_push(&heap[0], &size, TaxicabNode{2 * cube(a), a, a});
    }
    while (size > 0) {
        TaxicabNode first = heap_pop(&heap[0], &size);
        int total = first.sum;
        int count = 1;
        if (first.b < MAX_ROOT) {
            int next_b = first.b + 1;
            heap_push(&heap[0], &size, TaxicabNode{cube(first.a) + cube(next_b), first.a, next_b});
        }
        while (size > 0 && heap[0].sum == total) {
            TaxicabNode equal = heap_pop(&heap[0], &size);
            count++;
            if (equal.b < MAX_ROOT) {
                int next_b = equal.b + 1;
                heap_push(&heap[0], &size, TaxicabNode{cube(equal.a) + cube(next_b), equal.a, next_b});
            }
        }
        if (count >= ways) return (long)total;
    }
    return -1;
}

fn long taxicab_number_minimum_representations(long* input, usz length) @export("taxicab_number_minimum_representations") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || (input[0] != 2 && input[0] != 3)) return -1;
    return taxicab_search((int)input[0]);
}
