package binary_search_tree

import "core:c"

// Bounded unbalanced binary search tree with an index-based node pool.
@(export)
binary_search_tree_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || length % 2 != 0 do return -1
    operation_count := length / 2
    key: [256]i64
    left: [256]c.size_t
    right: [256]c.size_t
    free_next: [256]c.size_t
    for i := c.size_t(0); i < 256; i += 1 { free_next[i] = i + 1 }
    free_head: c.size_t = 0
    root: c.size_t = 256
    count: c.size_t = 0
    checksum: i64 = 0
    for operation := c.size_t(0); operation < operation_count; operation += 1 {
        opcode := values[2 * operation]
        payload := values[2 * operation + 1]
        observed: i64 = 0
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 do return -1
            parent: c.size_t = 256
            node := root
            for node != 256 && key[node] != payload {
                parent = node
                if payload < key[node] { node = left[node] } else { node = right[node] }
            }
            if node == 256 {
                if count == 256 || free_head == 256 do return -1
                node = free_head
                free_head = free_next[node]
                key[node] = payload
                left[node] = 256
                right[node] = 256
                if parent == 256 do root = node
                else if payload < key[parent] { left[parent] = node }
                else { right[parent] = node }
                count += 1
                observed = 1
            }
        } else if opcode == 1 {
            if payload < -1000000 || payload > 1000000 do return -1
            parent: c.size_t = 256
            node := root
            for node != 256 && key[node] != payload {
                parent = node
                if payload < key[node] { node = left[node] } else { node = right[node] }
            }
            if node != 256 { observed = 1 }
            if node != 256 {
                if left[node] != 256 && right[node] != 256 {
                    pred_parent := node
                    pred := left[node]
                    for right[pred] != 256 { pred_parent = pred; pred = right[pred] }
                    key[node] = key[pred]
                    parent = pred_parent
                    node = pred
                }
                child := left[node]
                if child == 256 do child = right[node]
                if parent == 256 do root = child
                else if left[parent] == node { left[parent] = child }
                else { right[parent] = child }
                free_next[node] = free_head
                free_head = node
                count -= 1
            }
        } else if opcode == 2 {
            if payload < -1000000 || payload > 1000000 do return -1
            node := root
            for node != 256 && key[node] != payload {
                if payload < key[node] { node = left[node] } else { node = right[node] }
            }
            if node != 256 { observed = 1 }
        } else if opcode == 3 || opcode == 4 {
            if payload != 0 || root == 256 do return -1
            node := root
            if opcode == 3 { for left[node] != 256 { node = left[node] } }
            else { for right[node] != 256 { node = right[node] } }
            observed = key[node]
        } else if opcode == 5 {
            if payload != 0 do return -1
            observed = i64(count)
        } else {
            return -1
        }
        checksum += i64(operation + 1) * (observed + 1000000)
    }
    stack: [256]c.size_t
    top: c.size_t = 0
    node := root
    index: c.size_t = 0
    for node != 256 || top != 0 {
        for node != 256 { stack[top] = node; top += 1; node = left[node] }
        top -= 1
        node = stack[top]
        checksum += i64(operation_count + index + 1) * (key[node] + 1000000)
        index += 1
        node = right[node]
    }
    return checksum
}
