from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 64
comptime MAX_INPUT = 323
comptime BASE = 128
comptime TREE_SIZE = 256

struct RetroQueue:
    var types: InlineArray[Int64, MAX_N + 1]
    var values: InlineArray[Int64, MAX_N + 1]
    var balance: InlineArray[Int64, TREE_SIZE]
    var prefix_min: InlineArray[Int64, TREE_SIZE]
    var suffix_max: InlineArray[Int64, TREE_SIZE]
    var min_insert: InlineArray[Int64, TREE_SIZE]
    var max_delete: InlineArray[Int64, TREE_SIZE]
    var live_count: Int64
    var live_sum: Int64

    fn __init__(out self):
        self.types = InlineArray[Int64, MAX_N + 1](fill=2)
        self.values = InlineArray[Int64, MAX_N + 1](fill=-1)
        self.balance = InlineArray[Int64, TREE_SIZE](fill=0)
        self.prefix_min = InlineArray[Int64, TREE_SIZE](fill=0)
        self.suffix_max = InlineArray[Int64, TREE_SIZE](fill=0)
        self.min_insert = InlineArray[Int64, TREE_SIZE](fill=0)
        self.max_delete = InlineArray[Int64, TREE_SIZE](fill=-1)
        self.live_count = 0
        self.live_sum = 0

fn retro_pick_min(inout q: RetroQueue, a: Int64, b: Int64) -> Int64:
    if a == 0: return b
    if b == 0: return a
    if q.values[Int(a)] != q.values[Int(b)]:
        return if q.values[Int(a)] < q.values[Int(b)]: a else: b
    return if a > b: a else: b

fn retro_pick_max(inout q: RetroQueue, a: Int64, b: Int64) -> Int64:
    if a == -1: return b
    if b == -1: return a
    if a == 0 or b == 0: return 0
    if q.values[Int(a)] != q.values[Int(b)]:
        return if q.values[Int(a)] > q.values[Int(b)]: a else: b
    return if a < b: a else: b

fn retro_pull(inout q: RetroQueue, i: Int):
    var p = (BASE + i) // 2
    while p > 0:
        let left = 2 * p
        let right = left + 1
        q.balance[p] = q.balance[left] + q.balance[right]
        q.prefix_min[p] = min(q.prefix_min[left], q.balance[left] + q.prefix_min[right])
        q.suffix_max[p] = max(q.suffix_max[left] + q.balance[right], q.suffix_max[right])
        q.min_insert[p] = retro_pick_min(q, q.min_insert[left], q.min_insert[right])
        q.max_delete[p] = retro_pick_max(q, q.max_delete[left], q.max_delete[right])
        p //= 2

fn retro_next_bridge(q: RetroQueue, i: Int) -> Int:
    var left = BASE
    var right = BASE + i + 1
    var acc: Int64 = 0
    while left < right:
        if left % 2 == 1:
            acc += q.balance[left]
            left += 1
        if right % 2 == 1:
            right -= 1
            acc += q.balance[right]
        left //= 2
        right //= 2
    if acc == 0: return i + 1
    var node = BASE + i + 1
    while True:
        while node % 2 == 0: node //= 2
        if acc + q.prefix_min[node] == 0:
            while node < BASE:
                node *= 2
                if acc + q.prefix_min[node] > 0:
                    acc += q.balance[node]
                    node += 1
            return node - BASE
        acc += q.balance[node]
        node += 1
        if (node & -node) == node: return BASE
    return BASE

fn retro_prev_bridge(q: RetroQueue, i: Int) -> Int:
    var left = BASE + i
    var right = BASE * 2
    var acc: Int64 = 0
    while left < right:
        if left % 2 == 1:
            acc += q.balance[left]
            left += 1
        if right % 2 == 1:
            right -= 1
            acc += q.balance[right]
        left //= 2
        right //= 2
    if acc == 0: return i
    var node = BASE + i
    while True:
        node -= 1
        while node > 1 and node % 2 == 1: node //= 2
        if q.suffix_max[node] + acc == 0:
            while node < BASE:
                node = node * 2 + 1
                if q.suffix_max[node] + acc < 0:
                    acc += q.balance[node]
                    node -= 1
            return node - BASE
        acc += q.balance[node]
        if (node & -node) == node: return 0
    return 0

fn retro_find_min_insert(inout q: RetroQueue, i: Int) -> Int64:
    var left = BASE
    var right = BASE + retro_next_bridge(q, i)
    var answer: Int64 = 0
    while left < right:
        if left % 2 == 1:
            answer = retro_pick_min(q, answer, q.min_insert[left])
            left += 1
        if right % 2 == 1:
            right -= 1
            answer = retro_pick_min(q, answer, q.min_insert[right])
        left //= 2
        right //= 2
    return answer

fn retro_find_max_delete(inout q: RetroQueue, i: Int) -> Int64:
    var left = BASE + retro_prev_bridge(q, i)
    var right = BASE * 2
    var answer: Int64 = -1
    while left < right:
        if left % 2 == 1:
            answer = retro_pick_max(q, answer, q.max_delete[left])
            left += 1
        if right % 2 == 1:
            right -= 1
            answer = retro_pick_max(q, answer, q.max_delete[right])
        left //= 2
        right //= 2
    return answer

fn retro_add(inout q: RetroQueue, i: Int):
    let k = retro_find_max_delete(q, i)
    let leaf = BASE + i
    if retro_pick_max(q, Int64(i), k) == Int64(i):
        q.live_sum += q.values[i]
        q.live_count += 1
        q.min_insert[leaf] = Int64(i)
        retro_pull(q, i)
        return
    q.max_delete[leaf] = Int64(i)
    q.balance[leaf] = 1
    q.suffix_max[leaf] = 1
    retro_pull(q, i)
    let mate = BASE + Int(k)
    if k == 0:
        q.balance[mate] -= 1
        q.suffix_max[mate] -= 1
        if q.balance[mate] == 0: q.max_delete[mate] = -1
    else:
        q.live_sum += q.values[Int(k)]
        q.live_count += 1
        q.min_insert[mate] = k
        q.max_delete[mate] = -1
        q.balance[mate] = 0
        q.suffix_max[mate] = 0
    retro_pull(q, mate - BASE)

fn retro_unadd(inout q: RetroQueue, i: Int):
    let leaf = BASE + i
    if q.balance[leaf] == 0:
        q.live_sum -= q.values[i]
        q.live_count -= 1
        q.min_insert[leaf] = 0
        retro_pull(q, i)
        return
    let k = retro_find_min_insert(q, i)
    q.max_delete[leaf] = -1
    q.balance[leaf] = 0
    q.suffix_max[leaf] = 0
    retro_pull(q, i)
    let mate = BASE + Int(k)
    if k > 0:
        q.live_sum -= q.values[Int(k)]
        q.live_count -= 1
    q.min_insert[mate] = 0
    q.max_delete[mate] = k
    q.balance[mate] += 1
    q.suffix_max[mate] += 1
    retro_pull(q, mate - BASE)

fn retro_pop(inout q: RetroQueue, i: Int):
    let k = retro_find_min_insert(q, i)
    let leaf = BASE + i
    q.balance[leaf] = -1
    q.prefix_min[leaf] = -1
    retro_pull(q, i)
    if k > 0:
        q.live_sum -= q.values[Int(k)]
        q.live_count -= 1
    let mate = BASE + Int(k)
    q.min_insert[mate] = 0
    q.max_delete[mate] = k
    q.balance[mate] += 1
    q.suffix_max[mate] += 1
    retro_pull(q, mate - BASE)

fn retro_unpop(inout q: RetroQueue, i: Int):
    let k = retro_find_max_delete(q, i)
    let leaf = BASE + i
    q.balance[leaf] = 0
    q.prefix_min[leaf] = 0
    retro_pull(q, i)
    let mate = BASE + Int(k)
    if k == 0:
        q.balance[mate] -= 1
        q.suffix_max[mate] -= 1
        if q.balance[mate] == 0: q.max_delete[mate] = -1
    else:
        q.live_sum += q.values[Int(k)]
        q.live_count += 1
        q.min_insert[mate] = k
        q.max_delete[mate] = -1
        q.balance[mate] = 0
        q.suffix_max[mate] = 0
    retro_pull(q, mate - BASE)

fn retro_set(inout q: RetroQueue, index: Int, kind: Int64, value: Int64):
    let i = index + 1
    if q.types[i] == 0: retro_unadd(q, i)
    elif q.types[i] == 1: retro_unpop(q, i)
    q.types[i] = kind
    q.values[i] = value
    if kind == 0: retro_add(q, i)
    elif kind == 1: retro_pop(q, i)

fn retro_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("partially_retroactive_priority_queue")
fn partially_retroactive_priority_queue(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 1 or n64 > MAX_N or q64 < 1 or q64 > MAX_Q: return -1
    let n = Int(n64)
    let qn = Int(q64)
    if Int(length) != 2 + 2 * n + 3 * qn: return -1
    var at = 2
    for _ in range(n):
        let kind = input[at]
        let value = input[at + 1]
        at += 2
        if kind == 0:
            if value < 0 or value > 1_000_000: return -1
        elif not ((kind == 1 or kind == 2) and value == -1): return -1
    for _ in range(qn):
        let index = input[at]
        let kind = input[at + 1]
        let value = input[at + 2]
        at += 3
        if index < 0 or index >= n64: return -1
        if kind == 0:
            if value < 0 or value > 1_000_000: return -1
        elif not ((kind == 1 or kind == 2) and value == -1): return -1
    let output_size = 16 * qn
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_size): return -2
    var queue = RetroQueue()
    at = 2
    for i in range(n):
        let kind = input[at]
        let value = input[at + 1]
        at += 2
        retro_set(queue, i, kind, value)
    var written = 0
    for _ in range(qn):
        let index = Int(input[at])
        let kind = input[at + 1]
        let value = input[at + 2]
        at += 3
        retro_set(queue, index, kind, value)
        retro_store(output, written, queue.live_count)
        retro_store(output, written + 8, queue.live_sum)
        written += 16
    return Int64(written)
