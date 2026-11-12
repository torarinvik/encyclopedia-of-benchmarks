from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_M = 32
alias MAX_N = 32
alias MAX_Q = 64
alias STRIDE = 33
alias MAX_INPUT = 259

fn pslcs_add(inout tree: InlineArray[Int, 34], position: Int, count: Int):
    var index = position + 1
    while index <= count:
        tree[index] += 1
        index += index & -index

fn pslcs_prefix(tree: InlineArray[Int, 34], exclusive: Int) -> Int:
    var total = 0
    var index = exclusive
    while index > 0:
        total += tree[index]
        index -= index & -index
    return total

fn pslcs_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("prefix_substring_lcs")
fn prefix_substring_lcs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT):
        return -1
    let m_value = input[0]
    let n_value = input[1]
    let q_value = input[2]
    if m_value < 1 or m_value > MAX_M or n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let m = Int(m_value)
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(3 + m + n + 3 * q): return -1

    var s = InlineArray[Int, 32](fill=0)
    var t = InlineArray[Int, 32](fill=0)
    var offset = 3
    for i in range(m):
        let code = input[offset]
        if code < 97 or code > 122: return -1
        s[i] = Int(code)
        offset += 1
    for j in range(n):
        let code = input[offset]
        if code < 97 or code > 122: return -1
        t[j] = Int(code)
        offset += 1

    var query_a = InlineArray[Int, 64](fill=0)
    var query_b = InlineArray[Int, 64](fill=0)
    var query_c = InlineArray[Int, 64](fill=0)
    var query_head = InlineArray[Int, 1089](fill=-1)
    var query_next = InlineArray[Int, 64](fill=-1)
    for index in range(q):
        let a_value = input[offset]
        let b_value = input[offset + 1]
        let c_value = input[offset + 2]
        if a_value < 0 or a_value > m_value or b_value < 0 or b_value > c_value or c_value > n_value:
            return -1
        query_a[index] = Int(a_value)
        query_b[index] = Int(b_value)
        query_c[index] = Int(c_value)
        let key = query_a[index] * STRIDE + query_b[index]
        query_next[index] = query_head[key]
        query_head[key] = index
        offset += 3
    let output_bytes = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var horizontal = InlineArray[Int, 1089](fill=0)
    var vertical = InlineArray[Int, 1089](fill=0)
    for j in range(n + 1): horizontal[j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            let above = horizontal[(i - 1) * STRIDE + j]
            let left = vertical[i * STRIDE + j - 1]
            if s[i - 1] == t[j - 1]:
                horizontal[i * STRIDE + j] = left
                vertical[i * STRIDE + j] = above
            else:
                horizontal[i * STRIDE + j] = max(above, left)
                vertical[i * STRIDE + j] = min(above, left)

    var answers = InlineArray[Int, 64](fill=0)
    for a in range(m + 1):
        var value_head = InlineArray[Int, 33](fill=-1)
        var value_next = InlineArray[Int, 33](fill=-1)
        for position in range(n + 1):
            let value = horizontal[a * STRIDE + position]
            value_next[position] = value_head[value]
            value_head[value] = position
        var fenwick = InlineArray[Int, 34](fill=0)
        for b in range(n + 1):
            var position = value_head[b]
            while position >= 0:
                pslcs_add(fenwick, position, n + 1)
                position = value_next[position]
            var qi = query_head[a * STRIDE + b]
            while qi >= 0:
                answers[qi] = pslcs_prefix(fenwick, query_c[qi] + 1) - pslcs_prefix(fenwick, query_b[qi] + 1)
                qi = query_next[qi]
    for index in range(q): pslcs_store(output, 8 * index, answers[index])
    return Int64(output_bytes)
