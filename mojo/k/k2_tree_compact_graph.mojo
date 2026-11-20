from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 32
alias MAX_Q = 128
alias MAX_INPUT = 419
alias T_BYTES = 43
alias L_BYTES = 128
alias T_MAX_BITS = 340
alias NODE_CAP = 256

fn bit_get_t(inout bits: InlineArray[UInt8, T_BYTES], index: Int) -> UInt8:
    (bits[index / 8] >> UInt(index % 8)) & UInt8(1)

fn bit_get_l(inout bits: InlineArray[UInt8, L_BYTES], index: Int) -> UInt8:
    (bits[index / 8] >> UInt(index % 8)) & UInt8(1)

fn bit_set_t(inout bits: InlineArray[UInt8, T_BYTES], index: Int):
    bits[index / 8] |= UInt8(1) << UInt(index % 8)

fn bit_set_l(inout bits: InlineArray[UInt8, L_BYTES], index: Int):
    bits[index / 8] |= UInt8(1) << UInt(index % 8)

fn block_nonempty(rows: UnsafePointer[Int64, ImmutAnyOrigin], row_offset: Int, n: Int,
    row_start: Int, col_start: Int, side: Int) -> Bool:
    let mask = ((Int64(1) << side) - 1) << col_start
    for row in range(row_start, row_start + side):
        if row < n and (rows[row_offset + row] & mask) != 0: return True
    False

fn build_tree(rows: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
    inout t_bits: InlineArray[UInt8, T_BYTES],
    inout l_bits: InlineArray[UInt8, L_BYTES],
    inout rank_prefix: InlineArray[UInt16, T_MAX_BITS + 1],
    inout current_rows: InlineArray[UInt8, NODE_CAP],
    inout current_cols: InlineArray[UInt8, NODE_CAP],
    inout next_rows: InlineArray[UInt8, NODE_CAP],
    inout next_cols: InlineArray[UInt8, NODE_CAP],
    inout t_len: Int, inout l_len: Int, inout height: Int):
    var side = 2
    height = 1
    while side < n:
        side *= 2
        height += 1
    var current_count = 1
    var current_side = side
    t_len = 0
    l_len = 0
    current_rows[0] = UInt8(0)
    current_cols[0] = UInt8(0)
    for level in range(1, height + 1):
        let child_side = current_side / 2
        var next_count = 0
        for parent in range(current_count):
            let parent_row = Int(current_rows[parent])
            let parent_col = Int(current_cols[parent])
            for quadrant in range(4):
                let child_row = parent_row + (quadrant / 2) * child_side
                let child_col = parent_col + (quadrant % 2) * child_side
                let occupied = block_nonempty(rows, 1, n, child_row, child_col, child_side)
                if level < height:
                    if occupied:
                        bit_set_t(inout t_bits, t_len)
                        next_rows[next_count] = UInt8(child_row)
                        next_cols[next_count] = UInt8(child_col)
                        next_count += 1
                    t_len += 1
                else:
                    if occupied: bit_set_l(inout l_bits, l_len)
                    l_len += 1
        if level < height:
            for i in range(next_count):
                current_rows[i] = next_rows[i]
                current_cols[i] = next_cols[i]
            current_count = next_count
            current_side = child_side
    rank_prefix[0] = UInt16(0)
    for i in range(t_len):
        rank_prefix[i + 1] = rank_prefix[i] + UInt16(bit_get_t(inout t_bits, i))

fn edge_query(inout t_bits: InlineArray[UInt8, T_BYTES],
    inout l_bits: InlineArray[UInt8, L_BYTES], t_len: Int,
    inout rank_prefix: InlineArray[UInt16, T_MAX_BITS + 1],
    height: Int, u: Int, v: Int) -> Bool:
    var parent = -1
    var row_start = 0
    var col_start = 0
    var side = 1 << height
    for _ in range(height):
        let child_side = side / 2
        let row_bit = 1 if u >= row_start + child_side else 0
        let col_bit = 1 if v >= col_start + child_side else 0
        let quadrant = 2 * row_bit + col_bit
        let child_base = 0 if parent < 0 else 4 * Int(rank_prefix[parent + 1])
        let child = child_base + quadrant
        if row_bit != 0: row_start += child_side
        if col_bit != 0: col_start += child_side
        if child < t_len:
            if bit_get_t(inout t_bits, child) == UInt8(0): return False
            parent = child
        else:
            return bit_get_l(inout l_bits, child - t_len) != UInt8(0)
        side = child_side
    False

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt64):
    var bits = value
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits >>= 8

@export("k2_tree_compact_graph")
fn k2_tree_compact_graph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N or length < c_size_t(n_value + 2): return -1
    let n = Int(n_value)
    let row_limit = (Int64(1) << n) - 1
    for row in range(n):
        if input[1 + row] < 0 or input[1 + row] > row_limit: return -1
    let q_index = n + 1
    let q_value = input[q_index]
    if q_value < 0 or q_value > MAX_Q: return -1
    let q = Int(q_value)
    if length != c_size_t(n + 2 + 3 * q): return -1
    let query_start = n + 2
    for j in range(q):
        let op = input[query_start + 3 * j]
        let u = input[query_start + 3 * j + 1]
        let v = input[query_start + 3 * j + 2]
        if u < 0 or u >= n_value: return -1
        if op == 0:
            if v < 0 or v >= n_value: return -1
        elif op == 1:
            if v != 0: return -1
        else:
            return -1
    let output_bytes = 8 * (q + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var t_bits = InlineArray[UInt8, T_BYTES](fill=0)
    var l_bits = InlineArray[UInt8, L_BYTES](fill=0)
    var rank_prefix = InlineArray[UInt16, T_MAX_BITS + 1](fill=0)
    var current_rows = InlineArray[UInt8, NODE_CAP](fill=0)
    var current_cols = InlineArray[UInt8, NODE_CAP](fill=0)
    var next_rows = InlineArray[UInt8, NODE_CAP](fill=0)
    var next_cols = InlineArray[UInt8, NODE_CAP](fill=0)
    var t_len = 0
    var l_len = 0
    var height = 0
    build_tree(input, n, inout t_bits, inout l_bits, inout rank_prefix,
        inout current_rows, inout current_cols, inout next_rows, inout next_cols,
        inout t_len, inout l_len, inout height)
    put_i64_le(output, 0, UInt64(q))
    for j in range(q):
        let op = input[query_start + 3 * j]
        let u = Int(input[query_start + 3 * j + 1])
        let v = Int(input[query_start + 3 * j + 2])
        var result = UInt64(0)
        if op == 0:
            result = UInt64(1) if edge_query(inout t_bits, inout l_bits, t_len,
                inout rank_prefix, height, u, v) else UInt64(0)
        else:
            for successor in range(n):
                if edge_query(inout t_bits, inout l_bits, t_len, inout rank_prefix,
                    height, u, successor):
                    result |= UInt64(1) << UInt(successor)
        put_i64_le(output, 8 * (j + 1), result)
    Int64(output_bytes)
