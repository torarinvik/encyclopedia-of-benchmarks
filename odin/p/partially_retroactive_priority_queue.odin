package partially_retroactive_priority_queue

import "core:c"

Max_N :: 64
Max_Q :: 64
Max_Input :: 323
Base :: 128
Tree_Size :: 256

Segment :: struct {
    balance, prefix_min, suffix_max: i64,
    min_insert, max_delete: i64,
}

Retro_Queue :: struct {
    types: [65]i64,
    values: [65]i64,
    tree: [Tree_Size]Segment,
    live_count, live_sum: i64,
}

pick_min_insert :: proc(q: ^Retro_Queue, a, b: i64) -> i64 {
    if a == 0 do return b
    if b == 0 do return a
    if q.values[int(a)] != q.values[int(b)] {
        if q.values[int(a)] < q.values[int(b)] do return a
        return b
    }
    if a > b do return a
    return b
}

pick_max_delete :: proc(q: ^Retro_Queue, a, b: i64) -> i64 {
    if a == -1 do return b
    if b == -1 do return a
    if a == 0 || b == 0 do return 0
    if q.values[int(a)] != q.values[int(b)] {
        if q.values[int(a)] > q.values[int(b)] do return a
        return b
    }
    if a < b do return a
    return b
}

pull :: proc(q: ^Retro_Queue, i: int) {
    p := (Base + i) / 2
    for p > 0 {
        left := q.tree[2 * p]
        right := q.tree[2 * p + 1]
        q.tree[p].balance = left.balance + right.balance
        across_min := left.balance + right.prefix_min
        if left.prefix_min < across_min do q.tree[p].prefix_min = left.prefix_min else q.tree[p].prefix_min = across_min
        across_max := left.suffix_max + right.balance
        if across_max > right.suffix_max do q.tree[p].suffix_max = across_max else q.tree[p].suffix_max = right.suffix_max
        q.tree[p].min_insert = pick_min_insert(q, left.min_insert, right.min_insert)
        q.tree[p].max_delete = pick_max_delete(q, left.max_delete, right.max_delete)
        p /= 2
    }
}

next_bridge :: proc(q: ^Retro_Queue, i: int) -> int {
    left, right := Base, Base + i + 1
    acc: i64 = 0
    for left < right {
        if (left & 1) == 1 { acc += q.tree[left].balance; left += 1 }
        if (right & 1) == 1 { right -= 1; acc += q.tree[right].balance }
        left /= 2
        right /= 2
    }
    if acc == 0 do return i + 1
    node := Base + i + 1
    for {
        for (node & 1) == 0 { node /= 2 }
        if acc + q.tree[node].prefix_min == 0 {
            for node < Base {
                node *= 2
                if acc + q.tree[node].prefix_min > 0 { acc += q.tree[node].balance; node += 1 }
            }
            return node - Base
        }
        acc += q.tree[node].balance
        node += 1
        if (node & -node) == node do return Base
    }
    return Base
}

prev_bridge :: proc(q: ^Retro_Queue, i: int) -> int {
    left, right := Base + i, Base * 2
    acc: i64 = 0
    for left < right {
        if (left & 1) == 1 { acc += q.tree[left].balance; left += 1 }
        if (right & 1) == 1 { right -= 1; acc += q.tree[right].balance }
        left /= 2
        right /= 2
    }
    if acc == 0 do return i
    node := Base + i
    for {
        node -= 1
        for node > 1 && (node & 1) == 1 { node /= 2 }
        if q.tree[node].suffix_max + acc == 0 {
            for node < Base {
                node = node * 2 + 1
                if q.tree[node].suffix_max + acc < 0 { acc += q.tree[node].balance; node -= 1 }
            }
            return node - Base
        }
        acc += q.tree[node].balance
        if (node & -node) == node do return 0
    }
    return 0
}

find_min_insert :: proc(q: ^Retro_Queue, i: int) -> i64 {
    left, right := Base, Base + next_bridge(q, i)
    answer: i64 = 0
    for left < right {
        if (left & 1) == 1 { answer = pick_min_insert(q, answer, q.tree[left].min_insert); left += 1 }
        if (right & 1) == 1 { right -= 1; answer = pick_min_insert(q, answer, q.tree[right].min_insert) }
        left /= 2
        right /= 2
    }
    return answer
}

find_max_delete :: proc(q: ^Retro_Queue, i: int) -> i64 {
    left, right := Base + prev_bridge(q, i), Base * 2
    answer: i64 = -1
    for left < right {
        if (left & 1) == 1 { answer = pick_max_delete(q, answer, q.tree[left].max_delete); left += 1 }
        if (right & 1) == 1 { right -= 1; answer = pick_max_delete(q, answer, q.tree[right].max_delete) }
        left /= 2
        right /= 2
    }
    return answer
}

add_operation :: proc(q: ^Retro_Queue, i: int) {
    k := find_max_delete(q, i)
    leaf := Base + i
    if pick_max_delete(q, i64(i), k) == i64(i) {
        q.live_sum += q.values[i]
        q.live_count += 1
        q.tree[leaf].min_insert = i64(i)
        pull(q, i)
        return
    }
    q.tree[leaf].max_delete = i64(i)
    q.tree[leaf].balance = 1
    q.tree[leaf].suffix_max = 1
    pull(q, i)
    mate := Base + int(k)
    if k == 0 {
        q.tree[mate].balance -= 1
        q.tree[mate].suffix_max -= 1
        if q.tree[mate].balance == 0 do q.tree[mate].max_delete = -1
    } else {
        q.live_sum += q.values[int(k)]
        q.live_count += 1
        q.tree[mate].min_insert = k
        q.tree[mate].max_delete = -1
        q.tree[mate].balance = 0
        q.tree[mate].suffix_max = 0
    }
    pull(q, int(k))
}

remove_insert :: proc(q: ^Retro_Queue, i: int) {
    leaf := Base + i
    if q.tree[leaf].balance == 0 {
        q.live_sum -= q.values[i]
        q.live_count -= 1
        q.tree[leaf].min_insert = 0
        pull(q, i)
        return
    }
    k := find_min_insert(q, i)
    q.tree[leaf].max_delete = -1
    q.tree[leaf].balance = 0
    q.tree[leaf].suffix_max = 0
    pull(q, i)
    mate := Base + int(k)
    if k > 0 { q.live_sum -= q.values[int(k)]; q.live_count -= 1 }
    q.tree[mate].min_insert = 0
    q.tree[mate].max_delete = k
    q.tree[mate].balance += 1
    q.tree[mate].suffix_max += 1
    pull(q, int(k))
}

remove_minimum :: proc(q: ^Retro_Queue, i: int) {
    k := find_min_insert(q, i)
    leaf := Base + i
    q.tree[leaf].balance = -1
    q.tree[leaf].prefix_min = -1
    pull(q, i)
    if k > 0 { q.live_sum -= q.values[int(k)]; q.live_count -= 1 }
    mate := Base + int(k)
    q.tree[mate].min_insert = 0
    q.tree[mate].max_delete = k
    q.tree[mate].balance += 1
    q.tree[mate].suffix_max += 1
    pull(q, int(k))
}

restore_minimum :: proc(q: ^Retro_Queue, i: int) {
    k := find_max_delete(q, i)
    leaf := Base + i
    q.tree[leaf].balance = 0
    q.tree[leaf].prefix_min = 0
    pull(q, i)
    mate := Base + int(k)
    if k == 0 {
        q.tree[mate].balance -= 1
        q.tree[mate].suffix_max -= 1
        if q.tree[mate].balance == 0 do q.tree[mate].max_delete = -1
    } else {
        q.live_sum += q.values[int(k)]
        q.live_count += 1
        q.tree[mate].min_insert = k
        q.tree[mate].max_delete = -1
        q.tree[mate].balance = 0
        q.tree[mate].suffix_max = 0
    }
    pull(q, int(k))
}

set_operation :: proc(q: ^Retro_Queue, index: int, kind, value: i64) {
    i := index + 1
    if q.types[i] == 0 do remove_insert(q, i)
    else if q.types[i] == 1 do restore_minimum(q, i)
    q.types[i] = kind
    q.values[i] = value
    if kind == 0 do add_operation(q, i)
    else if kind == 1 do remove_minimum(q, i)
}

store_i64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
partially_retroactive_priority_queue :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > c.size_t(Max_Input) do return -1
    if input[0] < 1 || input[0] > i64(Max_N) || input[1] < 1 || input[1] > i64(Max_Q) do return -1
    n, qn := int(input[0]), int(input[1])
    if int(input_length) != 2 + 2*n + 3*qn do return -1
    at := 2
    for _ := 0; _ < n; _ += 1 {
        kind, value := input[at], input[at+1]
        at += 2
        if kind == 0 {
            if value < 0 || value > 1_000_000 do return -1
        } else if !((kind == 1 || kind == 2) && value == -1) do return -1
    }
    for _ := 0; _ < qn; _ += 1 {
        index, kind, value := input[at], input[at+1], input[at+2]
        at += 3
        if index < 0 || index >= i64(n) do return -1
        if kind == 0 {
            if value < 0 || value > 1_000_000 do return -1
        } else if !((kind == 1 || kind == 2) && value == -1) do return -1
    }
    output_size := 16*qn
    if output == nil || int(capacity) < output_size do return -2
    queue := Retro_Queue{}
    queue.live_count, queue.live_sum = 0, 0
    for i := 0; i <= n; i += 1 { queue.types[i] = 2; queue.values[i] = -1 }
    for i := 0; i < Tree_Size; i += 1 { queue.tree[i].max_delete = -1 }
    at = 2
    for i := 0; i < n; i += 1 {
        kind, value := input[at], input[at+1]
        at += 2
        set_operation(&queue, i, kind, value)
    }
    written := 0
    for _ := 0; _ < qn; _ += 1 {
        index, kind, value := input[at], input[at+1], input[at+2]
        at += 3
        set_operation(&queue, int(index), kind, value)
        store_i64(output, written, queue.live_count)
        store_i64(output, written+8, queue.live_sum)
        written += 16
    }
    return i64(written)
}
