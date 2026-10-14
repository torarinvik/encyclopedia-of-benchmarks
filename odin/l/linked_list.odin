package linked_list

import "core:c"

// Bounded singly linked list with a portable index-based node pool.
@(export)
linked_list_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || length % 2 != 0 do return -1
    operation_count := length / 2
    node_value: [256]i64
    next_node: [256]c.size_t
    for i := c.size_t(0); i < 256; i += 1 { next_node[i] = i + 1 }
    free_head: c.size_t = 0
    head: c.size_t = 256
    tail: c.size_t = 256
    count: c.size_t = 0
    checksum: i64 = 0
    for operation := c.size_t(0); operation < operation_count; operation += 1 {
        opcode := values[2 * operation]
        payload := values[2 * operation + 1]
        observed: i64 = 0
        returns_value := true
        if opcode == 0 || opcode == 1 {
            if payload < -1000000 || payload > 1000000 || count == 256 || free_head == 256 do return -1
            node := free_head
            free_head = next_node[node]
            node_value[node] = payload
            if opcode == 0 {
                if tail == 256 do head = node
                else { next_node[tail] = node }
                tail = node
                next_node[node] = 256
            } else {
                next_node[node] = head
                head = node
                if tail == 256 do tail = node
            }
            count += 1
            returns_value = false
        } else if opcode == 2 {
            if payload != 0 || count == 0 do return -1
            node := head
            observed = node_value[node]
            head = next_node[node]
            if head == 256 do tail = 256
            next_node[node] = free_head
            free_head = node
            count -= 1
        } else if opcode == 3 {
            if payload != 0 || count == 0 do return -1
            node := tail
            observed = node_value[node]
            if head == tail {
                head = 256
                tail = 256
            } else {
                before := head
                for next_node[before] != tail { before = next_node[before] }
                tail = before
                next_node[before] = 256
            }
            next_node[node] = free_head
            free_head = node
            count -= 1
        } else if opcode == 4 || opcode == 5 {
            if payload < -1000000 || payload > 1000000 do return -1
            before: c.size_t = 256
            node := head
            for node != 256 && node_value[node] != payload {
                before = node
                node = next_node[node]
            }
            if node == 256 { observed = 0 } else { observed = 1 }
            if opcode == 4 && node != 256 {
                if before == 256 do head = next_node[node]
                else { next_node[before] = next_node[node] }
                if tail == node do tail = before
                next_node[node] = free_head
                free_head = node
                count -= 1
            }
        } else if opcode == 6 {
            if payload != 0 do return -1
            observed = i64(count)
        } else {
            return -1
        }
        if returns_value do checksum += i64(operation + 1) * (observed + 1000000)
    }
    node := head
    index: c.size_t = 0
    for node != 256 {
        checksum += i64(operation_count + index + 1) * (node_value[node] + 1000000)
        node = next_node[node]
        index += 1
    }
    return checksum
}
