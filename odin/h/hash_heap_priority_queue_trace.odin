package hash_heap_priority_queue_trace

import "core:c"

Item :: struct { key: u8, insertion: u8 }
MaxOps :: 64
MaxBuckets :: 8

before :: proc(a, b: Item) -> bool { return a.key < b.key || (a.key == b.key && a.insertion < b.insertion) }
write_i64 :: proc(output: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[at+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
hash_heap_priority_queue_trace :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 132 do return -1
    u, b, qv := input[0], input[1], input[2]
    if u < 1 || u > 128 || b < 1 || b > 8 || b > u || qv < 0 || qv > MaxOps do return -1
    universe, bucket_count, q := int(u), int(b), int(qv)
    if length != c.size_t(3 + 2*q) do return -1
    ops: [MaxOps]u8
    args: [MaxOps]u8
    for op := 0; op < q; op += 1 {
        opcode, argument := input[3+2*op], input[4+2*op]
        if opcode == 0 { if argument < 0 || argument >= u do return -1 }
        else if opcode == 1 || opcode == 2 { if argument != 0 do return -1 }
        else { return -1 }
        ops[op], args[op] = u8(opcode), u8(argument)
    }
    heaps: [MaxBuckets][MaxOps]Item
    sizes: [MaxBuckets]int
    words: [MaxOps+1]i64
    words[0] = i64(q)
    for op := 0; op < q; op += 1 {
        if ops[op] == 0 {
            bucket := int(args[op])*bucket_count/universe
            child := sizes[bucket]
            sizes[bucket] += 1
            heaps[bucket][child] = Item{args[op], u8(op)}
            for child > 0 {
                parent := (child-1)/2
                if !before(heaps[bucket][child], heaps[bucket][parent]) do break
                heaps[bucket][child], heaps[bucket][parent] = heaps[bucket][parent], heaps[bucket][child]
                child = parent
            }
            words[op+1] = -2
        } else {
            bucket := 0
            for bucket < bucket_count && sizes[bucket] == 0 { bucket += 1 }
            if bucket == bucket_count { words[op+1] = -1; continue }
            item := heaps[bucket][0]
            words[op+1] = (i64(item.insertion)<<8) | i64(item.key)
            if ops[op] == 2 {
                sizes[bucket] -= 1
                last := sizes[bucket]
                if last > 0 {
                    heaps[bucket][0] = heaps[bucket][last]
                    parent := 0
                    for {
                        left := parent*2+1
                        if left >= sizes[bucket] do break
                        child := left; right := left+1
                        if right < sizes[bucket] && before(heaps[bucket][right], heaps[bucket][left]) do child = right
                        if !before(heaps[bucket][child], heaps[bucket][parent]) do break
                        heaps[bucket][child], heaps[bucket][parent] = heaps[bucket][parent], heaps[bucket][child]
                        parent = child
                    }
                }
            }
        }
    }
    required := (q+1)*8
    if output == nil || capacity < c.size_t(required) do return -2
    staged: [520]u8
    for index := 0; index <= q; index += 1 { write_i64(&staged[0], index*8, words[index]) }
    for byte := 0; byte < required; byte += 1 { output[byte] = staged[byte] }
    return i64(required)
}
