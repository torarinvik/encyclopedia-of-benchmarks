from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 16
comptime MAX_BLOCKS = 6
comptime MAX_INPUT = 66

fn srm_lower_value(values: InlineArray[Int64, MAX_N], count: Int, target: Int64) -> Int:
    var lo = 0
    var hi = count
    while lo < hi:
        let mid = lo + (hi - lo) // 2
        if values[mid] < target: lo = mid + 1
        else: hi = mid
    return lo

fn srm_lower_position(values: InlineArray[Int, MAX_N], begin: Int, end: Int, target: Int) -> Int:
    var lo = begin
    var hi = end
    while lo < hi:
        let mid = lo + (hi - lo) // 2
        if values[mid] < target: lo = mid + 1
        else: hi = mid
    return lo

fn srm_frequency(occurrences: InlineArray[Int, MAX_N], offsets: InlineArray[Int, MAX_N + 1],
                 id: Int, left: Int, right: Int) -> Int:
    let begin = offsets[id]
    let end = offsets[id + 1]
    return srm_lower_position(occurrences, begin, end, right) - srm_lower_position(occurrences, begin, end, left)

fn srm_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("static_range_mode_query")
fn static_range_mode_query(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 2 * q):
        return -1
    for index in range(n):
        let value = input[2 + index]
        if value < 0 or value > 1_000_000_000:
            return -1
    for query in range(q):
        let left = input[2 + n + 2 * query]
        let right = input[3 + n + 2 * query]
        if left < 0 or right <= left or right > n_value:
            return -1

    var sorted = InlineArray[Int64, MAX_N](fill=0)
    var unique_values = InlineArray[Int64, MAX_N](fill=0)
    var compressed = InlineArray[Int, MAX_N](fill=0)
    var frequencies = InlineArray[Int, MAX_N](fill=0)
    var offsets = InlineArray[Int, MAX_N + 1](fill=0)
    var cursor = InlineArray[Int, MAX_N](fill=0)
    var occurrences = InlineArray[Int, MAX_N](fill=0)
    var block_modes = InlineArray[Int, MAX_BLOCKS * MAX_BLOCKS](fill=0)

    for index in range(n):
        let value = input[2 + index]
        var position = index
        while position > 0 and sorted[position - 1] > value:
            sorted[position] = sorted[position - 1]
            position -= 1
        sorted[position] = value

    var distinct = 0
    for index in range(n):
        if distinct == 0 or sorted[index] != unique_values[distinct - 1]:
            unique_values[distinct] = sorted[index]
            distinct += 1

    for index in range(n):
        let id = srm_lower_value(unique_values, distinct, input[2 + index])
        compressed[index] = id
        frequencies[id] += 1
    for id in range(distinct):
        offsets[id + 1] = offsets[id] + frequencies[id]
        cursor[id] = offsets[id]
    for index in range(n):
        let id = compressed[index]
        occurrences[cursor[id]] = index
        cursor[id] += 1

    var block_size = 1
    while block_size * block_size < n:
        block_size += 1
    let block_count = (n + block_size - 1) // block_size
    for first in range(block_count):
        var block_frequency = InlineArray[Int, MAX_N](fill=0)
        var best_id = 0
        var best_count = 0
        for last in range(first, block_count):
            let block_begin = last * block_size
            var block_end = block_begin + block_size
            if block_end > n: block_end = n
            for index in range(block_begin, block_end):
                let id = compressed[index]
                block_frequency[id] += 1
                let count = block_frequency[id]
                if count > best_count or (count == best_count and id < best_id):
                    best_id = id
                    best_count = count
            block_modes[first * MAX_BLOCKS + last] = best_id

    let bytes = 16 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    for query in range(q):
        let left = Int(input[2 + n + 2 * query])
        let right = Int(input[3 + n + 2 * query])
        let first_full = (left + block_size - 1) // block_size
        let after_full = right // block_size
        var best_id = 0
        var best_count = 0
        if first_full < after_full:
            best_id = block_modes[first_full * MAX_BLOCKS + after_full - 1]
            best_count = srm_frequency(occurrences, offsets, best_id, left, right)
            let span_begin = first_full * block_size
            let span_end = after_full * block_size
            for index in range(left, span_begin):
                let id = compressed[index]
                let count = srm_frequency(occurrences, offsets, id, left, right)
                if count > best_count or (count == best_count and id < best_id):
                    best_id = id
                    best_count = count
            for index in range(span_end, right):
                let id = compressed[index]
                let count = srm_frequency(occurrences, offsets, id, left, right)
                if count > best_count or (count == best_count and id < best_id):
                    best_id = id
                    best_count = count
        else:
            for index in range(left, right):
                let id = compressed[index]
                let count = srm_frequency(occurrences, offsets, id, left, right)
                if count > best_count or (count == best_count and id < best_id):
                    best_id = id
                    best_count = count
        srm_write_i64(output, 16 * query, unique_values[best_id])
        srm_write_i64(output, 16 * query + 8, Int64(best_count))
    return Int64(bytes)
