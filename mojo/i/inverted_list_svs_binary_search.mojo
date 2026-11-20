from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MIN_LISTS = 2
const MAX_LISTS = 8
const MAX_LIST_LENGTH = 32
const MAX_INPUT_LENGTH = 266
const BYTES_PER_VALUE = 4

fn store_i32_le(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int64):
    let bits = value.u32()
    output[position] = ((bits & 255).u8())
    output[position + 1] = (((bits >> 8) & 255).u8())
    output[position + 2] = (((bits >> 16) & 255).u8())
    output[position + 3] = (((bits >> 24) & 255).u8())

@export("inverted_list_svs_binary_search")
fn inverted_list_svs_binary_search(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t,
        o: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3 or n > MAX_INPUT_LENGTH:
        return -1
    if v[0] < Int64(MIN_LISTS) or v[0] > Int64(MAX_LISTS):
        return -1
    let input_length = Int(n)
    let count = Int(v[0])
    var starts = InlineArray[Int, MAX_LISTS](fill=0)
    var sizes = InlineArray[Int, MAX_LISTS](fill=0)
    var order = InlineArray[Int, MAX_LISTS](fill=0)
    var position = 1
    for list in range(count):
        if position >= input_length or v[position] < 0 or v[position] > Int64(MAX_LIST_LENGTH):
            return -1
        let size = v[position].int()
        position += 1
        if size > input_length - position:
            return -1
        starts[list] = position
        sizes[list] = size
        order[list] = list
        for i in range(size):
            let value = v[position + i]
            if value < -2147483648 or value > 2147483647:
                return -1
            if i > 0 and v[position + i - 1] >= value:
                return -1
        position += size
    if position != input_length:
        return -1
    for i in range(1, count):
        let key = order[i]
        var j = i
        while j > 0 and sizes[order[j - 1]] > sizes[key]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    let maximum_result = sizes[order[0]]
    if cap < c_size_t(maximum_result * BYTES_PER_VALUE) or (maximum_result > 0 and o == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2

    var candidates = InlineArray[Int64, MAX_LIST_LENGTH](fill=0)
    var candidate_count = maximum_result
    for i in range(candidate_count):
        candidates[i] = v[starts[order[0]] + i]
    for rank in range(1, count):
        if candidate_count == 0:
            break
        let list_id = order[rank]
        let start = starts[list_id]
        let size = sizes[list_id]
        var cursor = 0
        var kept = 0
        for i in range(candidate_count):
            let candidate = candidates[i]
            var low = cursor
            var high = size
            while low < high:
                let middle = low + (high - low) // 2
                if v[start + middle] < candidate:
                    low = middle + 1
                else:
                    high = middle
            if low < size and v[start + low] == candidate:
                candidates[kept] = candidate
                kept += 1
                cursor = low + 1
            else:
                cursor = low
        candidate_count = kept
    for i in range(candidate_count):
        store_i32_le(o, i * BYTES_PER_VALUE, candidates[i])
    return candidate_count
