from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_N = 16
comptime MAX_EVENTS = 32
comptime MAX_QUERIES = 32
comptime MAX_PARSEABLE_LENGTH = 196

@export("parallel_binary_search_range_threshold")
fn parallel_binary_search_range_threshold(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 0 or input[1] > MAX_EVENTS or
            input[2] < 0 or input[2] > MAX_QUERIES:
        return -1
    let n = Int(input[0])
    let event_count = Int(input[1])
    let query_count = Int(input[2])
    if Int(length) != 3 + 3 * event_count + 3 * query_count:
        return -1

    var event_left = InlineArray[Int, MAX_EVENTS]()
    var event_right = InlineArray[Int, MAX_EVENTS]()
    var event_delta = InlineArray[Int64, MAX_EVENTS]()
    var query_left = InlineArray[Int, MAX_QUERIES]()
    var query_right = InlineArray[Int, MAX_QUERIES]()
    var query_target = InlineArray[Int64, MAX_QUERIES]()
    var cursor = 3
    for event in range(event_count):
        let left = input[cursor]
        let right = input[cursor + 1]
        let delta = input[cursor + 2]
        cursor += 3
        if left < 0 or left > right or right >= n or delta < 0 or delta > 1000:
            return -1
        event_left[event] = Int(left)
        event_right[event] = Int(right)
        event_delta[event] = delta
    for query in range(query_count):
        let left = input[cursor]
        let right = input[cursor + 1]
        let target = input[cursor + 2]
        cursor += 3
        if left < 0 or left > right or right >= n or target < 1 or target > 512000:
            return -1
        query_left[query] = Int(left)
        query_right[query] = Int(right)
        query_target[query] = target

    var low = InlineArray[Int64, MAX_QUERIES]()
    var high = InlineArray[Int64, MAX_QUERIES]()
    var next_query = InlineArray[Int64, MAX_QUERIES]()
    for query in range(query_count):
        high[query] = Int64(event_count + 1)

    while True:
        var heads = InlineArray[Int64, MAX_EVENTS + 1]()
        for time in range(MAX_EVENTS + 1):
            heads[time] = -1
        for query in range(query_count):
            next_query[query] = -1
        var active = False
        for query in range(query_count):
            if high[query] - low[query] > 1:
                active = True
                let middle = Int((low[query] + high[query]) / 2)
                next_query[query] = heads[middle]
                heads[middle] = Int64(query)
        if not active:
            break

        var bit1 = InlineArray[Int64, MAX_N + 2]()
        var bit2 = InlineArray[Int64, MAX_N + 2]()
        var applied = 0
        for middle in range(event_count + 1):
            while applied < middle:
                let left = event_left[applied] + 1
                let right = event_right[applied] + 1
                let delta = event_delta[applied]
                var index = left
                while index <= n + 1:
                    bit1[index] += delta
                    index += index & -index
                index = right + 1
                while index <= n + 1:
                    bit1[index] -= delta
                    index += index & -index
                index = left
                while index <= n + 1:
                    bit2[index] += delta * Int64(left - 1)
                    index += index & -index
                index = right + 1
                while index <= n + 1:
                    bit2[index] -= delta * Int64(right)
                    index += index & -index
                applied += 1

            var query_id = heads[middle]
            while query_id >= 0:
                let id = Int(query_id)
                let left = query_left[id]
                let right = query_right[id]
                var index = right + 1
                var sum_right_1: Int64 = 0
                var sum_right_2: Int64 = 0
                while index > 0:
                    sum_right_1 += bit1[index]
                    sum_right_2 += bit2[index]
                    index -= index & -index
                let prefix_right = Int64(right + 1) * sum_right_1 - sum_right_2
                index = left
                var sum_left_1: Int64 = 0
                var sum_left_2: Int64 = 0
                while index > 0:
                    sum_left_1 += bit1[index]
                    sum_left_2 += bit2[index]
                    index -= index & -index
                let prefix_left = Int64(left) * sum_left_1 - sum_left_2
                if prefix_right - prefix_left >= query_target[id]:
                    high[id] = Int64(middle)
                else:
                    low[id] = Int64(middle)
                query_id = next_query[id]

    var result: Int64 = 0
    for query in range(query_count):
        result += Int64(query + 1) * (high[query] + 1)
    return result
