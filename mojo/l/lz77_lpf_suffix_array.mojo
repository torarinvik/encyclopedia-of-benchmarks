# K3 suffix-array/PSV/NSV LPF factorization, bounded to 32 bytes.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("lz77_lpf_suffix_array")
fn lz77_lpf_suffix_array(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 34: return -1
    let n64 = input[0]
    if n64 < 0 or n64 > 32: return -1
    let n = Int(n64)
    if length != c_size_t(n + 1): return -1
    var text = List[Int64](capacity=n)
    for i in range(n):
        let value = input[i + 1]
        if value < 0 or value > 255: return -1
        text.append(value)

    var sa = List[Int](capacity=n)
    var inverse = List[Int](capacity=n)
    var previous = List[Int](capacity=n)
    var following = List[Int](capacity=n)
    for i in range(n):
        sa.append(i)
        inverse.append(0)
        previous.append(-1)
        following.append(-1)
    for i in range(1, n):
        let value = sa[i]
        var j = i
        while j > 0:
            let a = value
            let b = sa[j - 1]
            var less = false
            var decided = false
            var x = a
            var y = b
            while x < n and y < n and not decided:
                if text[x] != text[y]:
                    less = text[x] < text[y]
                    decided = true
                else:
                    x += 1
                    y += 1
            if not decided: less = x == n and y != n
            if not less: break
            sa[j] = sa[j - 1]
            j -= 1
        sa[j] = value
    for rank in range(n): inverse[sa[rank]] = rank

    var stack = List[Int](capacity=n)
    for rank in range(n):
        while len(stack) > 0 and sa[stack[len(stack) - 1]] > sa[rank]:
            _ = stack.pop()
        if len(stack) > 0: previous[rank] = stack[len(stack) - 1]
        stack.append(rank)
    var reverse_stack = List[Int](capacity=n)
    for rr in range(n):
        let rank = n - rr - 1
        while len(reverse_stack) > 0 and sa[reverse_stack[len(reverse_stack) - 1]] > sa[rank]:
            _ = reverse_stack.pop()
        if len(reverse_stack) > 0: following[rank] = reverse_stack[len(reverse_stack) - 1]
        reverse_stack.append(rank)

    var staged = List[UInt8](capacity=512)
    for _ in range(512): staged.append(0)
    var pairs = 0
    var pos = 0
    while pos < n:
        let rank = inverse[pos]
        let psv = if previous[rank] >= 0: Int64(sa[previous[rank]]) else: Int64(-1)
        let nsv = if following[rank] >= 0: Int64(sa[following[rank]]) else: Int64(-1)
        var lp = 0
        var ln = 0
        if psv >= 0:
            while pos + lp < n and text[Int(psv) + lp] == text[pos + lp]: lp += 1
        if nsv >= 0:
            while pos + ln < n and text[Int(nsv) + ln] == text[pos + ln]: ln += 1
        var source = psv
        var matched = lp
        if ln > lp:
            source = nsv
            matched = ln
        if matched == 0: source = -1
        let source_bits = if source < 0: UInt64(0xFFFFFFFFFFFFFFFF) else: UInt64(source)
        let match_bits = UInt64(matched)
        for byte in range(8):
            staged[pairs * 16 + byte] = UInt8((source_bits >> (8 * byte)) & 255)
            staged[pairs * 16 + 8 + byte] = UInt8((match_bits >> (8 * byte)) & 255)
        pairs += 1
        pos += if matched > 0: matched else: 1

    let bytes = pairs * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(bytes): output[i] = staged[i]
    return Int64(bytes)
