module linked_list;

// Bounded singly linked list with a portable index-based node pool.
fn long linked_list_benchmark(long* values, usz length) @export("linked_list_benchmark")
{
    if (length > 1024 || length % 2 != 0) return -1;
    usz operation_count = length / 2;
    long[256] node_value;
    usz[256] next_node;
    for (usz i = 0; i < 256; i++) next_node[i] = i + 1;
    usz free_head = 0;
    usz head = 256;
    usz tail = 256;
    usz count = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[2 * operation];
        long payload = values[2 * operation + 1];
        long observed = 0;
        bool returns_value = true;
        if (opcode == 0 || opcode == 1) {
            if (payload < -1000000 || payload > 1000000 || count == 256 || free_head == 256) return -1;
            usz node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            if (opcode == 0) {
                if (tail == 256) { head = node; }
                else { next_node[tail] = node; }
                tail = node;
                next_node[node] = 256;
            } else {
                next_node[node] = head;
                head = node;
                if (tail == 256) { tail = node; }
            }
            count++;
            returns_value = false;
        } else if (opcode == 2) {
            if (payload != 0 || count == 0) return -1;
            usz node = head;
            observed = node_value[node];
            head = next_node[node];
            if (head == 256) { tail = 256; }
            next_node[node] = free_head;
            free_head = node;
            count--;
        } else if (opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            usz node = tail;
            observed = node_value[node];
            if (head == tail) {
                head = 256;
                tail = 256;
            } else {
                usz before = head;
                while (next_node[before] != tail) { before = next_node[before]; }
                tail = before;
                next_node[before] = 256;
            }
            next_node[node] = free_head;
            free_head = node;
            count--;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz before = 256;
            usz node = head;
            while (node != 256 && node_value[node] != payload) {
                before = node;
                node = next_node[node];
            }
            observed = (long)(node != 256);
            if (opcode == 4 && node != 256) {
                if (before == 256) { head = next_node[node]; }
                else { next_node[before] = next_node[node]; }
                if (tail == node) { tail = before; }
                next_node[node] = free_head;
                free_head = node;
                count--;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = (long)count;
        } else if (opcode == 7) {
            if (payload != 0) return -1;
            usz previous = 256;
            usz node = head;
            tail = head;
            while (node != 256) {
                usz next = next_node[node];
                next_node[node] = previous;
                previous = node;
                node = next;
            }
            head = previous;
            returns_value = false;
        } else {
            return -1;
        }
        if (returns_value) checksum += (long)(operation + 1) * (observed + 1000000);
    }
    usz node = head;
    usz index = 0;
    while (node != 256) {
        checksum += (long)(operation_count + index + 1) * (node_value[node] + 1000000);
        node = next_node[node];
        index++;
    }
    return checksum;
}
