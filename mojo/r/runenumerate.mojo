from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 24
alias MAX_RUNS = 144

fn runenumerate_store(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("runenumerate")
fn runenumerate(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_N + 1:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N or length != c_size_t(n_value + 1):
        return -1
    let n = Int(n_value)
    var text = InlineArray[Int, MAX_N](fill=0)
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= 26: return -1
        text[i] = Int(input[i + 1])
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2

    let stride = MAX_N + 1
    var lcp = InlineArray[Int, (MAX_N + 1) * (MAX_N + 1)](fill=0)
    for i in range(n - 1, -1, -1):
        for j in range(n - 1, i, -1):
            if text[i] == text[j]: lcp[i * stride + j] = 1 + lcp[(i + 1) * stride + j + 1]
    var periods = InlineArray[Int, MAX_RUNS](fill=0)
    var lefts = InlineArray[Int, MAX_RUNS](fill=0)
    var rights = InlineArray[Int, MAX_RUNS](fill=0)
    var count = 0
    for period in range(1, n // 2 + 1):
        var i = period
        while i < n:
            if text[i] != text[i - period]:
                i += 1
                continue
            let first = i
            while i < n and text[i] == text[i - period]: i += 1
            let left = first - period
            let right = i
            if right - left < 2 * period: continue
            var minimal = True
            for smaller in range(1, period):
                if lcp[left * stride + left + smaller] >= right - left - smaller:
                    minimal = False
                    break
            if minimal and count < MAX_RUNS:
                periods[count] = period
                lefts[count] = left
                rights[count] = right
                count += 1
    for i in range(1, count):
        let p = periods[i]
        let l = lefts[i]
        let r = rights[i]
        var j = i
        while j > 0 and (periods[j - 1] > p or
            (periods[j - 1] == p and lefts[j - 1] > l) or
            (periods[j - 1] == p and lefts[j - 1] == l and rights[j - 1] > r)):
            periods[j] = periods[j - 1]
            lefts[j] = lefts[j - 1]
            rights[j] = rights[j - 1]
            j -= 1
        periods[j] = p
        lefts[j] = l
        rights[j] = r

    let needed = 8 + 24 * count
    if capacity < c_size_t(needed): return -2
    runenumerate_store(output, 0, Int64(count))
    for i in range(count):
        let offset = 8 + 24 * i
        runenumerate_store(output, offset, Int64(periods[i]))
        runenumerate_store(output, offset + 8, Int64(lefts[i]))
        runenumerate_store(output, offset + 16, Int64(rights[i]))
    return Int64(needed)
