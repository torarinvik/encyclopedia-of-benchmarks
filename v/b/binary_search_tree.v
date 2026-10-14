module binary_search_tree

// Bounded unbalanced binary search tree with an index-based node pool.
@[export: 'binary_search_tree_benchmark']
pub fn binary_search_tree_benchmark(values &i64, length usize) i64 {
    if length > 1024 || length % 2 != 0 { return -1 }
    operation_count := length / 2
    mut key := [256]i64{init: 0}
    mut left := [256]int{init: 256}
    mut right := [256]int{init: 256}
    mut free_next := [256]int{init: 0}
    for i in 0 .. 256 { free_next[i] = i + 1 }
    mut free_head := 0
    mut root := 256
    mut count := 0
    mut checksum := i64(0)
    for operation in 0 .. operation_count {
        opcode := unsafe { values[2 * operation] }
        payload := unsafe { values[2 * operation + 1] }
        mut observed := i64(0)
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 { return -1 }
            mut parent := 256
            mut node := root
            for node != 256 && key[node] != payload {
                parent = node
                if payload < key[node] { node = left[node] } else { node = right[node] }
            }
            if node == 256 {
                if count == 256 || free_head == 256 { return -1 }
                node = free_head
                free_head = free_next[node]
                key[node] = payload
                left[node] = 256
                right[node] = 256
                if parent == 256 { root = node } else if payload < key[parent] { left[parent] = node } else { right[parent] = node }
                count++
                observed = 1
            }
        } else if opcode == 1 {
            if payload < -1000000 || payload > 1000000 { return -1 }
            mut parent := 256
            mut node := root
            for node != 256 && key[node] != payload {
                parent = node
                if payload < key[node] { node = left[node] } else { node = right[node] }
            }
            if node != 256 { observed = 1 }
            if node != 256 {
                if left[node] != 256 && right[node] != 256 {
                    mut pred_parent := node
                    mut pred := left[node]
                    for right[pred] != 256 { pred_parent = pred; pred = right[pred] }
                    key[node] = key[pred]
                    parent = pred_parent
                    node = pred
                }
                child := if left[node] != 256 { left[node] } else { right[node] }
                if parent == 256 { root = child } else if left[parent] == node { left[parent] = child } else { right[parent] = child }
                free_next[node] = free_head
                free_head = node
                count--
            }
        } else if opcode == 2 {
            if payload < -1000000 || payload > 1000000 { return -1 }
            mut node := root
            for node != 256 && key[node] != payload {
                if payload < key[node] { node = left[node] } else { node = right[node] }
            }
            if node != 256 { observed = 1 }
        } else if opcode == 3 || opcode == 4 {
            if payload != 0 || root == 256 { return -1 }
            mut node := root
            if opcode == 3 { for left[node] != 256 { node = left[node] } }
            else { for right[node] != 256 { node = right[node] } }
            observed = key[node]
        } else if opcode == 5 {
            if payload != 0 { return -1 }
            observed = i64(count)
        } else { return -1 }
        checksum += i64(operation + 1) * (observed + 1000000)
    }
    mut stack := [256]int{init: 0}
    mut top := 0
    mut node := root
    mut index := 0
    for node != 256 || top != 0 {
        for node != 256 { stack[top] = node; top++; node = left[node] }
        top--
        node = stack[top]
        checksum += (i64(operation_count) + i64(index) + 1) * (key[node] + 1000000)
        index++
        node = right[node]
    }
    return checksum
}
