module shootout_lists;

const int LIST_SIZE = 100;
const long MIN_RUNS = 0;
const long MAX_RUNS = 10000;
const usz NODE_COUNT = 203;

struct ListNode { int value; int next; int prev; }

void init_sequence(ListNode* nodes, int head, int base) {
    nodes[head].value = LIST_SIZE;
    nodes[head].next = base;
    nodes[head].prev = base + LIST_SIZE - 1;
    for (int offset = 0; offset < LIST_SIZE; offset++) {
        int item = base + offset;
        nodes[item].value = offset + 1;
        nodes[item].prev = offset == 0 ? head : item - 1;
        nodes[item].next = offset + 1 == LIST_SIZE ? head : item + 1;
    }
}

int list_length(ListNode* nodes, int head) { return nodes[head].value; }

int pop_head(ListNode* nodes, int head) {
    if (list_length(nodes, head) == 0) return -1;
    int item = nodes[head].next;
    int next = nodes[item].next;
    nodes[head].next = next;
    nodes[next].prev = head;
    nodes[head].value--;
    return item;
}

int pop_tail(ListNode* nodes, int head) {
    if (list_length(nodes, head) == 0) return -1;
    int item = nodes[head].prev;
    int prev = nodes[item].prev;
    nodes[head].prev = prev;
    nodes[prev].next = head;
    nodes[head].value--;
    return item;
}

void push_tail(ListNode* nodes, int head, int item) {
    int tail = nodes[head].prev;
    nodes[tail].next = item;
    nodes[item].next = head;
    nodes[head].prev = item;
    nodes[item].prev = tail;
    nodes[head].value++;
}

void reverse_list(ListNode* nodes, int head) {
    int current = head;
    do {
        int old_next = nodes[current].next;
        nodes[current].next = nodes[current].prev;
        nodes[current].prev = old_next;
        current = old_next;
    } while (current != head);
}

bool lists_equal(ListNode* nodes, int left, int right) {
    if (list_length(nodes, left) != list_length(nodes, right)) return false;
    int a = nodes[left].next, b = nodes[right].next;
    while (a != left && b != right) {
        if (nodes[a].value != nodes[b].value) return false;
        a = nodes[a].next;
        b = nodes[b].next;
    }
    return a == left && b == right;
}

int test_lists() {
    ListNode[NODE_COUNT] nodes = zeroed;
    int original = 0, copied = 101, staging = 202;
    init_sequence(&nodes[0], original, 1);
    init_sequence(&nodes[0], copied, 102);
    nodes[staging].value = 0;
    nodes[staging].next = staging;
    nodes[staging].prev = staging;
    if (!lists_equal(&nodes[0], copied, original)) return -1;
    while (list_length(&nodes[0], copied) > 0) {
        int item = pop_head(&nodes[0], copied);
        if (item < 0) return -1;
        push_tail(&nodes[0], staging, item);
    }
    if (list_length(&nodes[0], copied) != 0) return -1;
    while (list_length(&nodes[0], staging) > 0) {
        int item = pop_tail(&nodes[0], staging);
        if (item < 0) return -1;
        push_tail(&nodes[0], copied, item);
    }
    if (list_length(&nodes[0], staging) != 0) return -1;
    reverse_list(&nodes[0], original);
    if (nodes[nodes[original].next].value != LIST_SIZE) return -1;
    if (nodes[nodes[original].prev].value != 1) return -1;
    if (nodes[nodes[copied].next].value != LIST_SIZE) return -1;
    if (nodes[nodes[copied].prev].value != 1) return -1;
    if (list_length(&nodes[0], original) != LIST_SIZE) return -1;
    if (!lists_equal(&nodes[0], original, copied)) return -1;
    return list_length(&nodes[0], original);
}

fn long shootout_lists(long runs, char* output, usz output_capacity)
    @export("shootout_lists") {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == null) return -2;
    char[4] staged;
    usz output_bytes = 4;
    if (runs == 0) {
        staged[0] = '0'; staged[1] = '\n'; output_bytes = 2;
    } else {
        staged[0] = '1'; staged[1] = '0'; staged[2] = '0'; staged[3] = '\n';
    }
    if (output_capacity < output_bytes) return -2;
    for (long run = 0; run < runs; run++) if (test_lists() != LIST_SIZE) return -1;
    for (usz index = 0; index < output_bytes; index++) output[index] = staged[index];
    return (long)output_bytes;
}
