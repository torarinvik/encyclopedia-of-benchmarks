from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias TT_LISTS = 3
alias TT_MAX_LIST = 32
alias TT_MAX_VALUES = 48
alias TT_MAX_INPUT = 3 + TT_LISTS * TT_MAX_LIST
alias TT_WHITE = 0
alias TT_GREEN = 1
alias TT_RED = 2

fn tt_put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
        value: Int64) -> None:
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("t_threshold_three_sorted_lists")
fn t_threshold_three_sorted_lists(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > c_size_t(TT_MAX_INPUT + 1):
        return -1
    var base = InlineArray[Int, TT_LISTS](fill=0)
    var sizes = InlineArray[Int, TT_LISTS](fill=0)
    var at = 0
    for id in range(TT_LISTS):
        if at >= Int(length) or input[at] < 1 or input[at] > TT_MAX_LIST:
            return -1
        sizes[id] = Int(input[at])
        at += 1
        if sizes[id] > Int(length) - at:
            return -1
        base[id] = at
        for j in range(sizes[id]):
            let value = input[at + j]
            if value < -2147483648 or value > 2147483647 or (j > 0 and input[at + j - 1] >= value):
                return -1
        at += sizes[id]
    if at != Int(length):
        return -1

    var tails = InlineArray[Int64, TT_LISTS](fill=0)
    var firsts = InlineArray[Int64, TT_LISTS](fill=0)
    for i in range(TT_LISTS):
        tails[i] = input[base[i] + sizes[i] - 1]
        firsts[i] = input[base[i]]
    for i in range(TT_LISTS):
        for j in range(i + 1, TT_LISTS):
            if tails[i] > tails[j]:
                let temp = tails[i]; tails[i] = tails[j]; tails[j] = temp
            if firsts[i] > firsts[j]:
                let temp = firsts[i]; firsts[i] = firsts[j]; firsts[j] = temp
    let maximum_candidate = tails[1]
    var candidate = firsts[1]

    var color = InlineArray[Int, TT_LISTS](fill=TT_WHITE)
    var cursor = InlineArray[Int, TT_LISTS](fill=1)
    var search_base = InlineArray[Int, TT_LISTS](fill=1)
    var search_low = InlineArray[Int, TT_LISTS](fill=1)
    var search_step = InlineArray[Int, TT_LISTS](fill=1)
    var search_probe = InlineArray[Int, TT_LISTS](fill=1)
    var representative = InlineArray[Int, TT_LISTS](fill=0)
    var representative_present = InlineArray[Bool, TT_LISTS](fill=False)
    for i in range(TT_LISTS):
        if input[base[i]] == candidate:
            color[i] = TT_GREEN
        elif input[base[i]] > candidate:
            color[i] = TT_RED
            representative_present[i] = True

    var result = InlineArray[Int64, TT_MAX_VALUES](fill=0)
    var result_count = 0
    var round_robin = 0
    while candidate <= maximum_candidate:
        var green_count = 0
        var red_count = 0
        var white_count = 0
        for i in range(TT_LISTS):
            if color[i] == TT_GREEN:
                green_count += 1
            elif color[i] == TT_RED:
                red_count += 1
            else:
                white_count += 1
        if green_count >= 2 or red_count >= 2:
            if green_count >= 2:
                result[result_count] = candidate
                result_count += 1
            var recolor_count = 0
            if white_count == 0:
                recolor_count = 1
            for i in range(TT_LISTS):
                if recolor_count == 0:
                    break
                if color[i] != TT_GREEN:
                    continue
                color[i] = TT_WHITE
                search_base[i] = cursor[i]
                search_low[i] = cursor[i]
                search_step[i] = 1
                search_probe[i] = cursor[i]
                recolor_count -= 1
            for i in range(TT_LISTS):
                if color[i] != TT_GREEN:
                    continue
                color[i] = TT_RED
                representative[i] = cursor[i]
                representative_present[i] = cursor[i] < sizes[i]

            var found = False
            var next_candidate: Int64 = 9223372036854775807
            for i in range(TT_LISTS):
                if not representative_present[i]:
                    continue
                let value = input[base[i] + representative[i]]
                if not found or value < next_candidate:
                    found = True
                    next_candidate = value
            if not found:
                break
            candidate = next_candidate
            for i in range(TT_LISTS):
                if color[i] != TT_RED or not representative_present[i] or input[base[i] + representative[i]] != candidate:
                    continue
                color[i] = TT_GREEN
                representative_present[i] = False
                cursor[i] = representative[i] + 1
                search_base[i] = cursor[i]
                search_low[i] = cursor[i]
                search_step[i] = 1
                search_probe[i] = cursor[i]
            continue

        var list_id = TT_LISTS
        for offset in range(TT_LISTS):
            let i = (round_robin + offset) % TT_LISTS
            if color[i] == TT_WHITE:
                list_id = i
                break
        if list_id == TT_LISTS:
            break
        round_robin = (list_id + 1) % TT_LISTS
        let probe = min(search_probe[list_id], sizes[list_id] - 1)
        if input[base[list_id] + probe] < candidate:
            search_low[list_id] = probe + 1
            if probe + 1 == sizes[list_id]:
                color[list_id] = TT_RED
                representative[list_id] = sizes[list_id]
                representative_present[list_id] = False
            else:
                search_step[list_id] *= 2
                search_probe[list_id] = min(search_base[list_id] + search_step[list_id] - 1, sizes[list_id] - 1)
            continue
        var low = search_low[list_id]
        var high = probe + 1
        while low < high:
            let middle = low + (high - low) // 2
            if input[base[list_id] + middle] < candidate:
                low = middle + 1
            else:
                high = middle
        if low < sizes[list_id] and input[base[list_id] + low] == candidate:
            color[list_id] = TT_GREEN
            cursor[list_id] = low + 1
        else:
            color[list_id] = TT_RED
            representative[list_id] = low
            representative_present[list_id] = low < sizes[list_id]

    let output_bytes = 8 * (1 + result_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    tt_put_i64_le(output, 0, Int64(result_count))
    for i in range(result_count):
        tt_put_i64_le(output, 8 * (i + 1), result[i])
    return Int64(output_bytes)
