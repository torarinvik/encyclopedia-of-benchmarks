module ascending_priority_queue;

const long MAX_OPERATIONS = 512;
const int MAX_CAPACITY = 64;

struct Node {
    long value;
    int next;
}

// Bounded linked-node pool for an ascending priority queue.
fn long ascending_priority_queue(long* input, usz length) @export("ascending_priority_queue") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS
        || length != 1 + 2 * (usz)input[0]) return -1;

    Node[64] nodes;
    for (int index = 0; index < MAX_CAPACITY - 1; index++) nodes[index].next = index + 1;
    nodes[MAX_CAPACITY - 1].next = -1;
    int free_head = 0;
    int front = -1;
    int rear = -1;
    long checksum = 0;

    for (usz operation = 0; operation < (usz)input[0]; operation++) {
        long opcode = input[1 + 2 * operation];
        long payload = input[2 + 2 * operation];
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || free_head < 0) return -1;
            int node = free_head;
            free_head = nodes[node].next;
            nodes[node].value = payload;
            nodes[node].next = -1;
            if (front < 0) { front = node; rear = node; }
            else { nodes[rear].next = node; rear = node; }
        } else if (opcode == 1) {
            if (payload != 0 || front < 0) return -1;
            int previous = -1;
            int current = front;
            int minimum = front;
            int minimum_previous = -1;
            while (current >= 0) {
                if (nodes[current].value < nodes[minimum].value) {
                    minimum = current;
                    minimum_previous = previous;
                }
                previous = current;
                current = nodes[current].next;
            }
            checksum += (long)(operation + 1) * (nodes[minimum].value + 1000001);
            if (minimum_previous < 0) {
                front = nodes[minimum].next;
            } else {
                nodes[minimum_previous].next = nodes[minimum].next;
            }
            if (rear == minimum) rear = minimum_previous;
            nodes[minimum].next = free_head;
            free_head = minimum;
        } else {
            return -1;
        }
    }

    usz position = 1;
    int node = front;
    while (node >= 0) {
        checksum += (long)position * (nodes[node].value + 1000001);
        node = nodes[node].next;
        position++;
    }
    return checksum;
}
