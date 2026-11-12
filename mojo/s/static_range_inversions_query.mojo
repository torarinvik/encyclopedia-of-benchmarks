from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 128
comptime MAX_Q = 32
comptime MAX_INPUT = 195

fn srin_lower(values: InlineArray[Int64, MAX_N], count: Int, target: Int64) -> Int:
    var lo = 0
    var hi = count
    while lo < hi:
        let mid = lo + (hi - lo) // 2
        if values[mid] < target: lo = mid + 1
        else: hi = mid
    return lo

fn srin_bit_sum(bit: InlineArray[Int64, MAX_N + 1], count: Int) -> Int64:
    var i = count
    var total: Int64 = 0
    while i > 0:
        total += bit[i]
        i -= i & -i
    return total

fn srin_bit_add(mut bit: InlineArray[Int64, MAX_N + 1], rank: Int, delta: Int64):
    var i = rank + 1
    while i <= MAX_N:
        bit[i] += delta
        i += i & -i

fn srin_before(a: Int, b: Int, left: InlineArray[Int64, MAX_Q],
    right: InlineArray[Int64, MAX_Q], block_size: Int) -> Bool:
    let ba = Int(left[a]) // block_size
    let bb = Int(left[b]) // block_size
    if ba != bb: return ba < bb
    if right[a] != right[b]:
        if ba % 2 == 1: return right[a] > right[b]
        return right[a] < right[b]
    return a < b

fn srin_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("static_range_inversions_query")
fn static_range_inversions_query(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT): return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 2 * q): return -1
    var values = InlineArray[Int64, MAX_N]()
    var sorted = InlineArray[Int64, MAX_N]()
    for i in range(n):
        values[i] = input[2 + i]
        if values[i] < 0 or values[i] > 1_000_000_000: return -1
        sorted[i] = values[i]
    for i in range(1, n):
        let value = sorted[i]
        var j = i
        while j > 0 and sorted[j - 1] > value:
            sorted[j] = sorted[j - 1]
            j -= 1
        sorted[j] = value
    var distinct = 0
    for i in range(n):
        if distinct == 0 or sorted[i] != sorted[distinct - 1]:
            sorted[distinct] = sorted[i]
            distinct += 1
    var ranks = InlineArray[Int, MAX_N]()
    for i in range(n): ranks[i] = srin_lower(sorted, distinct, values[i])
    var block_size = 1
    while (block_size + 1) * (block_size + 1) <= n: block_size += 1
    var left = InlineArray[Int64, MAX_Q]()
    var right = InlineArray[Int64, MAX_Q]()
    var order = InlineArray[Int, MAX_Q]()
    var offset = 2 + n
    for k in range(q):
        left[k] = input[offset]
        right[k] = input[offset + 1]
        offset += 2
        if left[k] < 0 or left[k] >= right[k] or right[k] > n_value: return -1
        order[k] = k
    for i in range(1, q):
        let value = order[i]
        var j = i
        while j > 0 and srin_before(value, order[j - 1], left, right, block_size):
            order[j] = order[j - 1]
            j -= 1
        order[j] = value
    var bit = InlineArray[Int64, MAX_N + 1]()
    var answers = InlineArray[Int64, MAX_Q]()
    var current_left = 0
    var current_right = 0
    var window_size = 0
    var inversions: Int64 = 0
    for qi in range(q):
        let id = order[qi]
        let target_left = Int(left[id])
        let target_right = Int(right[id])
        while current_left > target_left:
            current_left -= 1
            let rank = ranks[current_left]
            inversions += srin_bit_sum(bit, rank)
            srin_bit_add(mut bit, rank, 1)
            window_size += 1
        while current_right < target_right:
            let rank = ranks[current_right]
            inversions += Int64(window_size) - srin_bit_sum(bit, rank + 1)
            srin_bit_add(mut bit, rank, 1)
            window_size += 1
            current_right += 1
        while current_left < target_left:
            let rank = ranks[current_left]
            inversions -= srin_bit_sum(bit, rank)
            srin_bit_add(mut bit, rank, -1)
            window_size -= 1
            current_left += 1
        while current_right > target_right:
            current_right -= 1
            let rank = ranks[current_right]
            inversions -= Int64(window_size) - srin_bit_sum(bit, rank + 1)
            srin_bit_add(mut bit, rank, -1)
            window_size -= 1
        answers[id] = inversions
    let bytes = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for k in range(q): srin_store(output, 8 * k, answers[k])
    return Int64(bytes)
