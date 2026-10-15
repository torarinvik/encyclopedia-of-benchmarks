module circular_doubly_linked_list;

// Bounded circular doubly linked list using a circular sentinel ring.
fn long circular_doubly_linked_list_benchmark(long* values, usz length) @export("circular_doubly_linked_list_benchmark")
{
    if (length > 1024 || length % 2 != 0) return -1;
    const usz capacity = 256;
    const usz sentinel = capacity;
    usz operation_count = length / 2;
    long[256] node_value;
    usz[257] next_node;
    usz[257] prev_node;
    for (usz i = 0; i < capacity; i++) next_node[i] = i + 1;
    usz free_head = 0;
    usz count = 0;
    next_node[sentinel] = sentinel;
    prev_node[sentinel] = sentinel;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[2 * operation];
        long payload = values[2 * operation + 1];
        long observed = 0;
        bool returns_value = true;
        if (opcode == 0 || opcode == 1) {
            if (payload < -1000000 || payload > 1000000 || count == capacity || free_head == sentinel) return -1;
            usz node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            usz before = opcode == 0 ? prev_node[sentinel] : sentinel;
            usz after = opcode == 0 ? sentinel : next_node[sentinel];
            next_node[node] = after; prev_node[node] = before;
            next_node[before] = node; prev_node[after] = node;
            count++;
            returns_value = false;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            usz node = opcode == 2 ? next_node[sentinel] : prev_node[sentinel];
            observed = node_value[node];
            next_node[prev_node[node]] = next_node[node];
            prev_node[next_node[node]] = prev_node[node];
            next_node[node] = free_head; free_head = node; count--;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz node = next_node[sentinel];
            while (node != sentinel && node_value[node] != payload) node = next_node[node];
            observed = (long)(node != sentinel);
            if (opcode == 4 && node != sentinel) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head; free_head = node; count--;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = count.long();
        } else if (opcode == 7 || opcode == 8) {
            if (payload < 0 || payload > 1000000 || count == 0) return -1;
            if (opcode == 8 && payload >= count.long()) return -1;
            usz index = opcode == 7 ? payload.usz() % count : payload.usz();
            usz node;
            if (index <= count / 2) {
                node = next_node[sentinel];
                for (usz i = 0; i < index; i++) node = next_node[node];
            } else {
                node = prev_node[sentinel];
                for (usz i = count - 1; i > index; i--) node = prev_node[node];
            }
            observed = node_value[node];
            if (opcode == 8) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head; free_head = node; count--;
            }
        } else return -1;
        if (returns_value) checksum += (long)(operation + 1) * (observed + 1000000);
    }
    usz node = next_node[sentinel];
    usz index = 0;
    while (node != sentinel) {
        checksum += (long)(operation_count + index + 1) * (node_value[node] + 1000000);
        node = next_node[node]; index++;
    }
    node = prev_node[sentinel]; index = 0;
    while (node != sentinel) {
        checksum += (long)(operation_count + count + index + 1) * (node_value[node] + 1000000);
        node = prev_node[node]; index++;
    }
    return checksum;
}
