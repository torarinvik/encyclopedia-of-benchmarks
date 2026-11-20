from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INPUT: Int = 274
const MAX_TEXT: Int = 256
const MAX_PATTERN: Int = 16

@export("optimal_mismatch")
fn optimal_mismatch(a: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if a == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > MAX_INPUT:
        return -2
    let raw_n = a[0]
    let raw_m = a[1]
    if raw_n < 0 or raw_n > MAX_TEXT or raw_m < 1 or raw_m > MAX_PATTERN:
        return -2
    let text_n = Int(raw_n)
    let pattern_n = Int(raw_m)
    if n != c_size_t(2 + text_n + pattern_n):
        return -2
    let pattern_start = 2 + text_n
    for i in range(text_n + pattern_n):
        if a[i + 2] < 0 or a[i + 2] > 127:
            return -2
    if pattern_n > text_n:
        return -1

    var frequency = InlineArray[Int, 128](fill=0)
    for i in range(text_n):
        frequency[Int(a[2 + i])] += 1
    var order = InlineArray[Int, 16](fill=0)
    for i in range(pattern_n):
        order[i] = i
    for i in range(1, pattern_n):
        let selected = order[i]
        var cursor = i
        while cursor > 0:
            let previous = order[cursor - 1]
            let pf = frequency[Int(a[pattern_start + previous])]
            let sf = frequency[Int(a[pattern_start + selected])]
            if pf < sf or (pf == sf and previous > selected):
                break
            order[cursor] = previous
            cursor -= 1
        order[cursor] = selected

    var quick_shift = InlineArray[Int, 128](fill=pattern_n + 1)
    for i in range(pattern_n):
        quick_shift[Int(a[pattern_start + i])] = pattern_n - i
    var adapted_shift = InlineArray[Int, 16](fill=pattern_n)
    for rank in range(pattern_n):
        let mismatch = order[rank]
        for shift in range(1, pattern_n + 1):
            var compatible = True
            for prior in range(rank):
                let position = order[prior]
                if position >= shift and a[pattern_start + position] != a[pattern_start + position - shift]:
                    compatible = False
                    break
            if not compatible:
                continue
            if mismatch >= shift and a[pattern_start + mismatch - shift] == a[pattern_start + mismatch]:
                continue
            adapted_shift[rank] = shift
            break

    var start = 0
    let last_start = text_n - pattern_n
    while start <= last_start:
        var rank = 0
        while rank < pattern_n and a[2 + start + order[rank]] == a[pattern_start + order[rank]]:
            rank += 1
        if rank == pattern_n:
            return Int64(start)
        if start + pattern_n == text_n:
            break
        let quick = quick_shift[Int(a[2 + start + pattern_n])]
        let advance = if adapted_shift[rank] > quick: adapted_shift[rank] else: quick
        start += advance
    return -1
