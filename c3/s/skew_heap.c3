module skew_heap;

const usz MAX_OPERATIONS = 64;
const usz MAX_LIVE_VALUES = 32;
const usz MAX_INPUT_LENGTH = 130;
const usz MAX_OUTPUT_VALUES = 1024;
struct SkewNode { int value; int left; int right; int next_free; }
struct SkewHeap { SkewNode[MAX_LIVE_VALUES] nodes; int root; int free_head; int count; }

void initialize(SkewHeap* heap) {
    heap.root = -1; heap.count = 0; heap.free_head = 0;
    for (int i = 0; i < (int)MAX_LIVE_VALUES; ++i) {
        heap.nodes[i].left = -1; heap.nodes[i].right = -1;
        heap.nodes[i].next_free = i + 1 < (int)MAX_LIVE_VALUES ? i + 1 : -1;
    }
}
int merge(SkewHeap* heap, int first, int second) {
    if (first < 0) return second;
    if (second < 0) return first;
    if (heap.nodes[first].value > heap.nodes[second].value) { int temporary = first; first = second; second = temporary; }
    int old_right = heap.nodes[first].right;
    heap.nodes[first].right = heap.nodes[first].left;
    heap.nodes[first].left = merge(heap, old_right, second);
    return first;
}
bool insert(SkewHeap* heap, int value) {
    if (heap.free_head < 0) return false;
    int node = heap.free_head; heap.free_head = heap.nodes[node].next_free;
    heap.nodes[node] = SkewNode{value, -1, -1, -1};
    heap.root = merge(heap, heap.root, node); ++heap.count; return true;
}
int pop(SkewHeap* heap) {
    int node = heap.root; int value = heap.nodes[node].value;
    heap.root = merge(heap, heap.nodes[node].left, heap.nodes[node].right);
    heap.nodes[node].next_free = heap.free_head; heap.free_head = node; --heap.count; return value;
}
void store_i64(char* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; ++byte) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long skew_heap(long* input, usz length, char* output, usz capacity) @export("skew_heap") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];
    if (length != 1 + 2 * operation_count || length > MAX_INPUT_LENGTH - 1) return -1;
    SkewHeap heap; initialize(&heap);
    long[MAX_OUTPUT_VALUES] answers = zeroed; usz answer_count = 0;
    for (usz operation = 0; operation < operation_count; ++operation) {
        long opcode = input[1 + 2 * operation], argument = input[2 + 2 * operation];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < -2147483648 || argument > 2147483647 || heap.count == (int)MAX_LIVE_VALUES) return -1;
            if (!insert(&heap, (int)argument)) return -1;
        } else {
            if (argument != 0) return -1;
            if (opcode == 1) { if (heap.root < 0) return -1; answers[answer_count++] = heap.nodes[heap.root].value; }
            else if (opcode == 2) { if (heap.root < 0) return -1; answers[answer_count++] = pop(&heap); }
            else if (opcode == 3) {
                int[MAX_LIVE_VALUES] snapshot = zeroed; usz snapshot_count = 0;
                while (heap.root >= 0) snapshot[snapshot_count++] = pop(&heap);
                for (usz i = 0; i < snapshot_count; ++i) {
                    if (!insert(&heap, snapshot[i])) return -1;
                    answers[answer_count++] = snapshot[i];
                }
            } else if (opcode == 4) initialize(&heap);
            else answers[answer_count++] = heap.count == 0 ? 1 : 0;
        }
    }
    usz output_bytes = answer_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < answer_count; ++i) store_i64(output, 8 * i, answers[i]);
    return (long)output_bytes;
}
