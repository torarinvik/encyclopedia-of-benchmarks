package josephus_batched_small_k

import "core:c"

@(export)
josephus_batched_small_k :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    n0, k := values[0], values[1]
    if n0 < 1 || n0 > 1_000_000 || k < 1 || k > 32 do return -1
    if n0 == 1 do return 0
    if k == 1 do return n0 - 1
    frames: [1024]i64
    depth: usize = 0
    n := n0
    for n > 1 {
        if depth == 1024 do return -1
        frames[depth] = n
        depth += 1
        if n < k do n -= 1 else n -= n / k
    }
    survivor: i64 = 0
    for depth > 0 {
        depth -= 1
        m := frames[depth]
        if m < k do survivor = (survivor + k) % m
        else {
            survivor -= m % k
            if survivor < 0 do survivor += m else survivor += survivor / (k - 1)
        }
    }
    return survivor
}
