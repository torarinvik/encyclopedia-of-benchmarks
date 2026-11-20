from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_Q = 48
comptime MAX_CONS = 32
comptime MAX_ROOTS = 49
comptime MAX_BLOCKS = 6
comptime MAX_SLOTS = 63
comptime MAX_PARSEABLE = 146

fn vlist_length(previous_block: UnsafePointer[Int32, MutAnyOrigin],
                previous_offset: UnsafePointer[Int32, MutAnyOrigin],
                last_used: UnsafePointer[Int32, MutAnyOrigin],
                root_block: UnsafePointer[Int32, MutAnyOrigin],
                root_offset: UnsafePointer[Int32, MutAnyOrigin], root: Int) -> Int:
    var block_id = root_block[root]
    var offset = root_offset[root]
    var total = 0
    while block_id >= 0:
        if block_id >= MAX_BLOCKS or offset < 0 or offset > last_used[block_id]: return -1
        total += offset + 1
        offset = previous_offset[block_id]
        block_id = previous_block[block_id]
    return total

fn vlist_nth(data: UnsafePointer[Int64, MutAnyOrigin], base: UnsafePointer[Int32, MutAnyOrigin],
              previous_block: UnsafePointer[Int32, MutAnyOrigin],
              previous_offset: UnsafePointer[Int32, MutAnyOrigin],
              last_used: UnsafePointer[Int32, MutAnyOrigin],
              root_block: UnsafePointer[Int32, MutAnyOrigin],
              root_offset: UnsafePointer[Int32, MutAnyOrigin], root: Int, index: Int) -> Int64:
    var block_id = root_block[root]
    var offset = root_offset[root]
    var remaining = index
    while block_id >= 0:
        if block_id >= MAX_BLOCKS or offset < 0 or offset > last_used[block_id]: return -1000001
        if remaining <= offset: return data[base[block_id] + offset - remaining]
        remaining -= offset + 1
        offset = previous_offset[block_id]
        block_id = previous_block[block_id]
    return -1000001

fn vlist_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("vlist_persistent_sequence")
fn vlist_persistent_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(1) or length > c_size_t(MAX_PARSEABLE): return -1
    let q_word = input[0]
    if q_word < 1 or q_word > MAX_Q or length != c_size_t(1 + 3 * Int(q_word)): return -1
    let q = Int(q_word)

    var previous_block = InlineArray[Int32, MAX_BLOCKS](fill=-1)
    var previous_offset = InlineArray[Int32, MAX_BLOCKS](fill=-1)
    var block_capacity = InlineArray[Int32, MAX_BLOCKS](fill=0)
    var last_used = InlineArray[Int32, MAX_BLOCKS](fill=-1)
    var block_base = InlineArray[Int32, MAX_BLOCKS](fill=0)
    var data = InlineArray[Int64, MAX_SLOTS](fill=0)
    var root_block = InlineArray[Int32, MAX_ROOTS](fill=-1)
    var root_offset = InlineArray[Int32, MAX_ROOTS](fill=-1)
    var results = InlineArray[Int64, MAX_Q](fill=0)
    var block_count = 0
    var root_count = 1
    var slot_count = 0
    var cons_count = 0
    var query_phase = False
    var at = 1
    for op in range(q):
        let tag = input[at]
        let root_word = input[at + 1]
        let arg = input[at + 2]
        at += 3
        if tag < 0 or tag > 3 or root_word < 0 or root_word >= root_count: return -1
        let root = Int(root_word)
        if tag == 0:
            if query_phase or root != root_count - 1 or cons_count >= MAX_CONS or arg < -1000000 or arg > 1000000: return -1
            var block_id = Int(root_block[root])
            var offset = Int(root_offset[root])
            if block_id < 0:
                if cons_count != 0 or block_count != 0 or slot_count >= MAX_SLOTS: return -1
                previous_block[block_count] = -1
                previous_offset[block_count] = -1
                block_capacity[block_count] = 1
                last_used[block_count] = 0
                block_base[block_count] = slot_count
                data[slot_count] = arg
                block_id = block_count
                offset = 0
                block_count += 1
                slot_count += 1
            else:
                if block_id >= block_count or offset != last_used[block_id]: return -1
                if offset + 1 < block_capacity[block_id]:
                    offset += 1
                    data[block_base[block_id] + offset] = arg
                    last_used[block_id] = offset
                else:
                    let next_capacity = block_capacity[block_id] * 2
                    if block_count >= MAX_BLOCKS or slot_count + next_capacity > MAX_SLOTS: return -1
                    previous_block[block_count] = block_id
                    previous_offset[block_count] = offset
                    block_capacity[block_count] = next_capacity
                    last_used[block_count] = 0
                    block_base[block_count] = slot_count
                    data[slot_count] = arg
                    block_id = block_count
                    offset = 0
                    block_count += 1
                    slot_count += next_capacity
            if root_count >= MAX_ROOTS: return -1
            root_block[root_count] = Int32(block_id)
            root_offset[root_count] = Int32(offset)
            results[op] = Int64(root_count)
            root_count += 1
            cons_count += 1
        else:
            query_phase = True
            if tag == 1:
                if arg != -1 or vlist_length(previous_block.unsafe_ptr(), previous_offset.unsafe_ptr(),
                    last_used.unsafe_ptr(), root_block.unsafe_ptr(), root_offset.unsafe_ptr(), root) <= 0: return -1
                var block_id = Int(root_block[root])
                var offset = Int(root_offset[root])
                if offset > 0:
                    offset -= 1
                else:
                    offset = Int(previous_offset[block_id])
                    block_id = Int(previous_block[block_id])
                if root_count >= MAX_ROOTS: return -1
                root_block[root_count] = Int32(block_id)
                root_offset[root_count] = Int32(offset)
                results[op] = Int64(root_count)
                root_count += 1
            elif tag == 2:
                let n = vlist_length(previous_block.unsafe_ptr(), previous_offset.unsafe_ptr(),
                    last_used.unsafe_ptr(), root_block.unsafe_ptr(), root_offset.unsafe_ptr(), root)
                if n < 0 or arg < 0 or arg >= n: return -1
                let value = vlist_nth(data.unsafe_ptr(), block_base.unsafe_ptr(), previous_block.unsafe_ptr(),
                    previous_offset.unsafe_ptr(), last_used.unsafe_ptr(), root_block.unsafe_ptr(),
                    root_offset.unsafe_ptr(), root, Int(arg))
                if value == -1000001: return -1
                results[op] = value
            else:
                if arg != -1: return -1
                let n = vlist_length(previous_block.unsafe_ptr(), previous_offset.unsafe_ptr(),
                    last_used.unsafe_ptr(), root_block.unsafe_ptr(), root_offset.unsafe_ptr(), root)
                if n < 0: return -1
                results[op] = Int64(n)
    let bytes = q * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(q): vlist_store_i64_le(output, i * 8, results[i])
    return Int64(bytes)
