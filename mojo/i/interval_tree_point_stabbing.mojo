from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime IT_MAX_N = 16
comptime IT_MAX_Q = 8
comptime IT_TREE_CAP = 32
comptime IT_MAX_OUTPUT = 72

@export("interval_tree_point_stabbing")
fn interval_tree_point_stabbing(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 43:
        return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 0 or n64 > IT_MAX_N or q64 < 0 or q64 > IT_MAX_Q:
        return -1
    let n = Int(n64)
    let q = Int(q64)
    if Int(length) != 2 + 2 * n + q:
        return -1
    var sorted_low = InlineArray[Int64, IT_MAX_N]()
    var sorted_high = InlineArray[Int64, IT_MAX_N]()
    var sorted_id = InlineArray[Int, IT_MAX_N]()
    var cursor = 2
    for index in range(n):
        let low = input[cursor]
        let high = input[cursor + 1]
        cursor += 2
        if low < -32 or low > 32 or high < -32 or high > 32 or low > high:
            return -1
        sorted_low[index] = low
        sorted_high[index] = high
        sorted_id[index] = index
    var points = InlineArray[Int64, IT_MAX_Q]()
    for index in range(q):
        points[index] = input[cursor]
        cursor += 1
        if points[index] < -32 or points[index] > 32:
            return -1
    for index in range(1, n):
        let low = sorted_low[index]
        let high = sorted_high[index]
        let ident = sorted_id[index]
        var position = index
        while position > 0:
            let previous = position - 1
            let greater = sorted_low[previous] > low or (
                sorted_low[previous] == low and sorted_high[previous] > high
            ) or (
                sorted_low[previous] == low and sorted_high[previous] == high and
                sorted_id[previous] > ident
            )
            if not greater:
                break
            sorted_low[position] = sorted_low[previous]
            sorted_high[position] = sorted_high[previous]
            sorted_id[position] = sorted_id[previous]
            position -= 1
        sorted_low[position] = low
        sorted_high[position] = high
        sorted_id[position] = ident
    var tree_low = InlineArray[Int64, IT_TREE_CAP]()
    var tree_high = InlineArray[Int64, IT_TREE_CAP]()
    var tree_id = InlineArray[Int, IT_TREE_CAP]()
    var used = InlineArray[Bool, IT_TREE_CAP]()
    var maximum = InlineArray[Int64, IT_TREE_CAP]()
    var firsts = InlineArray[Int, IT_MAX_N]()
    var lasts = InlineArray[Int, IT_MAX_N]()
    var nodes = InlineArray[Int, IT_MAX_N]()
    for node in range(IT_TREE_CAP):
        maximum[node] = -9223372036854775807 - 1
        used[node] = False
    if n > 0:
        var top = 1
        firsts[0] = 0
        lasts[0] = n - 1
        nodes[0] = 0
        while top > 0:
            top -= 1
            let first = firsts[top]
            let last = lasts[top]
            let node = nodes[top]
            if first > last or node >= IT_TREE_CAP:
                continue
            let middle = first + (last - first) // 2
            tree_low[node] = sorted_low[middle]
            tree_high[node] = sorted_high[middle]
            tree_id[node] = sorted_id[middle]
            used[node] = True
            if middle + 1 <= last:
                firsts[top] = middle + 1
                lasts[top] = last
                nodes[top] = 2 * node + 2
                top += 1
            if first <= middle - 1:
                firsts[top] = first
                lasts[top] = middle - 1
                nodes[top] = 2 * node + 1
                top += 1
    for node in range(IT_TREE_CAP - 1, -1, -1):
        if not used[node]:
            continue
        maximum[node] = tree_high[node]
        let left = 2 * node + 1
        let right = left + 1
        if left < IT_TREE_CAP and used[left] and maximum[left] > maximum[node]:
            maximum[node] = maximum[left]
        if right < IT_TREE_CAP and used[right] and maximum[right] > maximum[node]:
            maximum[node] = maximum[right]
    var masks = InlineArray[Int64, IT_MAX_Q]()
    for query_index in range(q):
        var stack = InlineArray[Int, IT_TREE_CAP]()
        var top = 0
        if n > 0:
            stack[0] = 0
            top = 1
        while top > 0:
            top -= 1
            let node = stack[top]
            if not used[node] or maximum[node] < points[query_index]:
                continue
            let left = 2 * node + 1
            let right = left + 1
            if left < IT_TREE_CAP and used[left] and maximum[left] >= points[query_index]:
                stack[top] = left
                top += 1
            if tree_low[node] <= points[query_index] and points[query_index] <= tree_high[node]:
                masks[query_index] |= Int64(1) << tree_id[node]
            if tree_low[node] <= points[query_index] and right < IT_TREE_CAP and used[right] and maximum[right] >= points[query_index]:
                stack[top] = right
                top += 1
    let byte_count = (q + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < byte_count:
        return -2
    var staged = InlineArray[UInt8, IT_MAX_OUTPUT]()
    let header = Int64(q).bitcast[UInt64]()
    for byte in range(8):
        staged[byte] = UInt8((header >> (byte * 8)) & 255)
    for query_index in range(q):
        let bits = masks[query_index].bitcast[UInt64]()
        for byte in range(8):
            staged[(query_index + 1) * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    for byte in range(byte_count):
        output[byte] = staged[byte]
    Int64(byte_count)
