package circular_doubly_linked_list

import "core:c"

// Bounded circular doubly linked list using a circular sentinel ring.
@(export)
circular_doubly_linked_list_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || length % 2 != 0 do return -1
    capacity :: c.size_t(256)
    sentinel :: capacity
    operation_count := length / 2
    node_value: [256]i64
    next_node: [257]c.size_t
    prev_node: [257]c.size_t
    for i := c.size_t(0); i < capacity; i += 1 { next_node[i] = i + 1 }
    free_head: c.size_t = 0
    count: c.size_t = 0
    next_node[sentinel] = sentinel
    prev_node[sentinel] = sentinel
    checksum: i64 = 0
    for operation := c.size_t(0); operation < operation_count; operation += 1 {
        opcode := values[2 * operation]
        payload := values[2 * operation + 1]
        observed: i64 = 0
        returns_value := true
        if opcode == 0 || opcode == 1 {
            if payload < -1000000 || payload > 1000000 || count == capacity || free_head == sentinel do return -1
            node := free_head
            free_head = next_node[node]
            node_value[node] = payload
            before := sentinel
            after := sentinel
            if opcode == 0 { before = prev_node[sentinel] } else { after = next_node[sentinel] }
            next_node[node] = after
            prev_node[node] = before
            next_node[before] = node
            prev_node[after] = node
            count += 1
            returns_value = false
        } else if opcode == 2 || opcode == 3 {
            if payload != 0 || count == 0 do return -1
            node := next_node[sentinel]
            if opcode == 3 { node = prev_node[sentinel] }
            observed = node_value[node]
            next_node[prev_node[node]] = next_node[node]
            prev_node[next_node[node]] = prev_node[node]
            next_node[node] = free_head
            free_head = node
            count -= 1
        } else if opcode == 4 || opcode == 5 {
            if payload < -1000000 || payload > 1000000 do return -1
            node := next_node[sentinel]
            for node != sentinel && node_value[node] != payload { node = next_node[node] }
            if node != sentinel { observed = 1 }
            if opcode == 4 && node != sentinel {
                next_node[prev_node[node]] = next_node[node]
                prev_node[next_node[node]] = prev_node[node]
                next_node[node] = free_head
                free_head = node
                count -= 1
            }
        } else if opcode == 6 {
            if payload != 0 do return -1
            observed = i64(count)
        } else if opcode == 7 || opcode == 8 {
            if payload < 0 || payload > 1000000 || count == 0 do return -1
            if opcode == 8 && c.size_t(payload) >= count do return -1
            index := c.size_t(payload)
            if opcode == 7 { index %= count }
            node := next_node[sentinel]
            if index > count / 2 {
                node = prev_node[sentinel]
                for i := count - 1; i > index; i -= 1 { node = prev_node[node] }
            } else {
                for i := c.size_t(0); i < index; i += 1 { node = next_node[node] }
            }
            observed = node_value[node]
            if opcode == 8 {
                next_node[prev_node[node]] = next_node[node]
                prev_node[next_node[node]] = prev_node[node]
                next_node[node] = free_head
                free_head = node
                count -= 1
            }
        } else { return -1 }
        if returns_value { checksum += i64(operation + 1) * (observed + 1000000) }
    }
    node := next_node[sentinel]
    index: c.size_t = 0
    for node != sentinel {
        checksum += i64(operation_count + index + 1) * (node_value[node] + 1000000)
        node = next_node[node]
        index += 1
    }
    node = prev_node[sentinel]
    index = 0
    for node != sentinel {
        checksum += i64(operation_count + count + index + 1) * (node_value[node] + 1000000)
        node = prev_node[node]
        index += 1
    }
    return checksum
}
