module linked_list

// Bounded singly linked list with a portable index-based node pool.
@[export: 'linked_list_benchmark']
pub fn linked_list_benchmark(values &i64, length usize) i64 {
    if length > 1024 || length % 2 != 0 { return -1 }
    operation_count := length / 2
    mut node_value := [256]i64{init: 0}
    mut next_node := [256]int{init: 0}
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
            if opcode == 0 {
                if tail == 256 { head = node } else { next_node[tail] = node }
                tail = node
                next_node[node] = 256
            } else {
                next_node[node] = head
                head = node
                if tail == 256 { tail = node }
            }
            count++
            returns_value = false
        } else if opcode == 2 {
            if payload != 0 || count == 0 { return -1 }
            node := head
            observed = node_value[node]
            head = next_node[node]
            if head == 256 { tail = 256 }
            next_node[node] = free_head
            free_head = node
            count--
        } else if opcode == 3 {
            if payload != 0 || count == 0 { return -1 }
            node := tail
            observed = node_value[node]
            if head == tail {
                head = 256
                tail = 256
            } else {
                mut before := head
                for next_node[before] != tail { before = next_node[before] }
                tail = before
                next_node[before] = 256
            }
            next_node[node] = free_head
            free_head = node
            count--
        } else if opcode == 4 || opcode == 5 {
            if payload < -1000000 || payload > 1000000 { return -1 }
            mut before := 256
            mut node := head
            for node != 256 && node_value[node] != payload {
                before = node
                node = next_node[node]
            }
            if node == 256 { observed = 0 } else { observed = 1 }
            if opcode == 4 && node != 256 {
                if before == 256 { head = next_node[node] } else { next_node[before] = next_node[node] }
                if tail == node { tail = before }
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
    return checksum
}
