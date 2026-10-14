module doubly_linked_list;

// Bounded doubly linked list with a portable index-based node pool.
fn long doubly_linked_list_benchmark(long* values, usz length) @export("doubly_linked_list_benchmark")
{
    if (length > 1024 || length % 2 != 0) return -1;
    usz operation_count = length / 2;
    long[256] node_value;
    usz[256] next_node;
    usz[256] prev_node;
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
            next_node[node] = 256; prev_node[node] = 256;
            if (opcode == 0) {
                if (tail == 256) { head = node; }
                else { prev_node[node] = tail; next_node[tail] = node; }
                tail = node;
            } else {
                if (head == 256) { tail = node; }
                else { next_node[node] = head; prev_node[head] = node; }
                head = node;
            }
            count++;
            returns_value = false;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            usz node = opcode == 2 ? head : tail;
            observed = node_value[node];
            usz before = prev_node[node];
            usz after = next_node[node];
            if (before == 256) { head = after; } else { next_node[before] = after; }
            if (after == 256) { tail = before; } else { prev_node[after] = before; }
            next_node[node] = free_head; free_head = node; count--;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz node = head;
            while (node != 256 && node_value[node] != payload) node = next_node[node];
            observed = (long)(node != 256);
            if (opcode == 4 && node != 256) {
                usz before = prev_node[node];
                usz after = next_node[node];
                if (before == 256) { head = after; } else { next_node[before] = after; }
                if (after == 256) { tail = before; } else { prev_node[after] = before; }
                next_node[node] = free_head; free_head = node; count--;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = (long)count;
        } else {
            return -1;
        }
        if (returns_value) checksum += (long)(operation + 1) * (observed + 1000000);
    }
    usz node = head;
    usz index = 0;
    while (node != 256) {
        checksum += (long)(operation_count + index + 1) * (node_value[node] + 1000000);
        node = next_node[node]; index++;
    }
    node = tail; index = 0;
    while (node != 256) {
        checksum += (long)(operation_count + count + index + 1) * (node_value[node] + 1000000);
        node = prev_node[node]; index++;
    }
    return checksum;
}
