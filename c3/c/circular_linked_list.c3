module circular_linked_list;

fn long circular_linked_list_benchmark(long* values, usz length)
        @export("circular_linked_list_benchmark") {
    if (length > 1024 || length % 2 != 0) return -1;
    const usz capacity = 256;
    const usz sentinel = capacity;
    usz operation_count = length / 2;
    long[256] node_value;
    usz[257] next_node;
    for (usz index = 0; index < capacity; index++) next_node[index] = index + 1;
    next_node[sentinel] = sentinel;
    usz free_head = 0, tail = sentinel, count = 0;
    long checksum = 0;

    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[2 * operation], payload = values[2 * operation + 1];
        long observed = 0;
        bool returns_value = true;
        if (opcode == 0 || opcode == 1) {
            if (payload < -1000000 || payload > 1000000 || count == capacity || free_head == sentinel) return -1;
            usz node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            if (opcode == 0) {
                next_node[node] = sentinel;
                next_node[tail] = node;
                tail = node;
            } else {
                next_node[node] = next_node[sentinel];
                next_node[sentinel] = node;
                if (count == 0) tail = node;
            }
            count++;
            returns_value = false;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            usz previous = sentinel;
            if (opcode == 3) for (next_node[previous] != tail) previous = next_node[previous];
            usz node = next_node[previous];
            observed = node_value[node];
            next_node[previous] = next_node[node];
            if (node == tail) tail = previous;
            next_node[node] = free_head;
            free_head = node;
            count--;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -1000000 || payload > 1000000) return -1;
            usz previous = sentinel;
            for (next_node[previous] != sentinel && node_value[next_node[previous]] != payload)
                previous = next_node[previous];
            usz node = next_node[previous];
            observed = (long)(node != sentinel);
            if (opcode == 4 && node != sentinel) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                count--;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = count.long();
        } else if (opcode == 7 || opcode == 8) {
            if (payload < 0 || payload > 1000000 || count == 0 || payload >= count.long()) return -1;
            usz previous = sentinel;
            for (usz index = 0; index < payload.usz(); index++) previous = next_node[previous];
            usz node = next_node[previous];
            observed = node_value[node];
            if (opcode == 8) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                count--;
            }
        } else return -1;
        if (returns_value) checksum += (long)(operation + 1) * (observed + 1000000);
    }

    usz node = next_node[sentinel], index = 0;
    while (node != sentinel) {
        checksum += (long)(operation_count + index + 1) * (node_value[node] + 1000000);
        node = next_node[node];
        index++;
    }
    return checksum;
}
