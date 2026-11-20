from memory import UnsafePointer
from sys.ffi import c_size_t

comptime MAX_N = 8
comptime MAX_M = 20
comptime MAX_INPUT = 63

fn rd_connected(n: Int, m: Int, left: InlineArray[Int32, MAX_M],
                right: InlineArray[Int32, MAX_M], active: UInt32) -> Bool:
    var seen = InlineArray[Bool, MAX_N](fill=False)
    var queue = InlineArray[Int32, MAX_N](fill=0)
    var head = 0
    var tail = 1
    seen[0] = True
    queue[0] = 0
    while head < tail:
        let vertex = queue[head]
        head += 1
        for id in range(m):
            if ((active >> id) & 1) == 0: continue
            var neighbor = -1
            if Int(left[id]) == vertex: neighbor = Int(right[id])
            elif Int(right[id]) == vertex: neighbor = Int(left[id])
            if neighbor >= 0 and not seen[neighbor]:
                seen[neighbor] = True
                queue[tail] = Int32(neighbor)
                tail += 1
    for vertex in range(n):
        if not seen[vertex]: return False
    return True

fn rd_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("reverse_delete_mst")
fn reverse_delete_mst(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_INPUT): return -1
    let n_word = input[0]
    let m_word = input[1]
    if n_word < 2 or n_word > MAX_N or m_word < n_word - 1 or m_word > MAX_M: return -1
    let n = Int(n_word)
    let m = Int(m_word)
    if length != c_size_t(2 + 3 * m): return -1

    var left = InlineArray[Int32, MAX_M](fill=0)
    var right = InlineArray[Int32, MAX_M](fill=0)
    var weights = InlineArray[Int32, MAX_M](fill=0)
    var order = InlineArray[Int32, MAX_M](fill=0)
    for id in range(m):
        let u = input[2 + 3 * id]
        let v = input[3 + 3 * id]
        let weight = input[4 + 3 * id]
        if u < 0 or u >= n or v < 0 or v >= n or u == v or weight < 0 or weight > 1000: return -1
        left[id] = Int32(u)
        right[id] = Int32(v)
        weights[id] = Int32(weight)
        order[id] = Int32(id)
        let low = min(u, v)
        let high = max(u, v)
        for prior in range(id):
            let prior_low = min(Int64(left[prior]), Int64(right[prior]))
            let prior_high = max(Int64(left[prior]), Int64(right[prior]))
            if low == prior_low and high == prior_high: return -1
    for i in range(1, m):
        let item = order[i]
        var j = i
        while j > 0 and (weights[order[j - 1]] < weights[item] or
                (weights[order[j - 1]] == weights[item] and order[j - 1] < item)):
            order[j] = order[j - 1]
            j -= 1
        order[j] = item

    var active = (UInt32(1) << UInt32(m)) - 1
    if not rd_connected(n, m, left, right, active): return -1
    for position in range(m):
        let candidate = active & ~(UInt32(1) << UInt32(order[position]))
        if rd_connected(n, m, left, right, candidate): active = candidate
    var total_weight: Int64 = 0
    for id in range(m):
        if ((active >> id) & 1) != 0: total_weight += Int64(weights[id])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16): return -2
    rd_store_i64_le(output, 0, Int64(active))
    rd_store_i64_le(output, 8, total_weight)
    return 16
