module doubly_linked_list

// Bounded doubly linked list with a portable index-based node pool.
@[export: 'doubly_linked_list_benchmark']
pub fn doubly_linked_list_benchmark(values &i64, length usize) i64 {
    if length > 1024 || length % 2 != 0 { return -1 }
    operation_count := length / 2
    mut node_value := [256]i64{init: 0}
    mut next_node := [256]int{init: 0}
    mut prev_node := [256]int{init: 0}
    for i in 0 .. 256 { next_node[i] = i + 1 }
    mut free_head := 0
    mut head := 256
    mut tail := 256
    mut count := 0
    mut checksum := i64(0)
    for operation in 0 .. operation_count {
        opcode := unsafe { values[2 * operation] }
        payload := unsafe { values[2 * operation + 1] }
        mut observed := i64(0)
        mut returns_value := true
        if opcode == 0 || opcode == 1 {
            if payload < -1000000 || payload > 1000000 || count == 256 || free_head == 256 { return -1 }
            node := free_head
            free_head = next_node[node]
            node_value[node] = payload
            next_node[node] = 256
            prev_node[node] = 256
            if opcode == 0 {
                if tail == 256 { head = node } else { prev_node[node] = tail; next_node[tail] = node }
                tail = node
            } else {
                if head == 256 { tail = node } else { next_node[node] = head; prev_node[head] = node }
                head = node
            }
            count++
            returns_value = false
        } else if opcode == 2 || opcode == 3 {
            if payload != 0 || count == 0 { return -1 }
            node := if opcode == 2 { head } else { tail }
            observed = node_value[node]
            before := prev_node[node]
            after := next_node[node]
            if before == 256 { head = after } else { next_node[before] = after }
            if after == 256 { tail = before } else { prev_node[after] = before }
            next_node[node] = free_head
            free_head = node
            count--
        } else if opcode == 4 || opcode == 5 {
            if payload < -1000000 || payload > 1000000 { return -1 }
            mut node := head
            for node != 256 && node_value[node] != payload { node = next_node[node] }
            if node == 256 { observed = 0 } else { observed = 1 }
            if opcode == 4 && node != 256 {
                before := prev_node[node]
                after := next_node[node]
                if before == 256 { head = after } else { next_node[before] = after }
                if after == 256 { tail = before } else { prev_node[after] = before }
                next_node[node] = free_head
                free_head = node
                count--
            }
        } else if opcode == 6 {
            if payload != 0 { return -1 }
            observed = i64(count)
        } else { return -1 }
        if returns_value { checksum += i64(operation + 1) * (observed + 1000000) }
    }
    mut node := head
    mut index := 0
    for node != 256 {
        checksum += (i64(operation_count) + i64(index) + 1) * (node_value[node] + 1000000)
        node = next_node[node]
        index++
    }
    node = tail
    index = 0
    for node != 256 {
        checksum += (i64(operation_count) + i64(count) + i64(index) + 1) * (node_value[node] + 1000000)
        node = prev_node[node]
        index++
    }
    return checksum
}
