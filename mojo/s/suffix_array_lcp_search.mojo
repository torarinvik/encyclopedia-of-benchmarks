from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn suffix_less(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, a: Int, b: Int) -> Bool:
    var i = a
    var j = b
    while i < n and j < n:
        if input[1 + i] != input[1 + j]: return input[1 + i] < input[1 + j]
        i += 1
        j += 1
    return i == n and j != n

fn suffix_pattern_cmp(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int,
                      start: Int, offset: Int, prefix_equal: Bool, inout matched: Int) -> Int:
    matched = offset
    while matched < m and start + matched < n and input[1 + start + matched] == input[n + 2 + matched]:
        matched += 1
    if matched == m:
        if prefix_equal or start + matched == n: return 0
        return 1
    if start + matched == n: return -1
    if input[1 + start + matched] < input[n + 2 + matched]: return -1
    return 1

fn suffix_bound(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int,
                suffix: InlineArray[Int, 32], left_q: InlineArray[Int, 1024],
                right_q: InlineArray[Int, 1024], prefix_equal: Bool) -> Int:
    var left_match = 0
    let first = suffix_pattern_cmp(input, n, m, suffix[0], 0, prefix_equal, left_match)
    if first > 0 or (not prefix_equal and first == 0): return 0
    var right_match = 0
    let last = suffix_pattern_cmp(input, n, m, suffix[n - 1], 0, prefix_equal, right_match)
    if last < 0 or (prefix_equal and last == 0): return n
    var lo = 0
    var hi = n - 1
    while hi - lo > 1:
        let mid = (lo + hi + 1) // 2
        var compare = False
        var offset = 0
        if left_match == right_match:
            compare = True
            offset = left_match
        elif left_match > right_match:
            let q = left_q[lo * 32 + hi]
            if left_match < q: lo = mid
            elif left_match > q:
                hi = mid
                right_match = q
            else:
                compare = True
                offset = left_match
        else:
            let q = right_q[lo * 32 + hi]
            if right_match < q: hi = mid
            elif right_match > q:
                lo = mid
                left_match = q
            else:
                compare = True
                offset = right_match
        if compare:
            var matched = 0
            let result = suffix_pattern_cmp(input, n, m, suffix[mid], offset, prefix_equal, matched)
            if result > 0 or (not prefix_equal and result == 0):
                hi = mid
                right_match = matched
            else:
                lo = mid
                left_match = matched
    return hi

@export("suffix_array_lcp_search")
fn suffix_array_lcp_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 50: return -1
    if input[0] < 1 or input[0] > 32: return -1
    let n = Int(input[0])
    if Int(length) < n + 2 or input[n + 1] < 1 or input[n + 1] > 16: return -1
    let m = Int(input[n + 1])
    if Int(length) != n + m + 2: return -1
    var suffix = InlineArray[Int, 32](fill=0)
    var lcp = InlineArray[Int, 32](fill=0)
    var left_q = InlineArray[Int, 1024](fill=0)
    var right_q = InlineArray[Int, 1024](fill=0)
    for i in range(n):
        if input[1 + i] < 0 or input[1 + i] > 127: return -1
        suffix[i] = i
    for i in range(m):
        if input[n + 2 + i] < 0 or input[n + 2 + i] > 127: return -1
    for i in range(1, n):
        let value = suffix[i]
        var j = i
        while j > 0 and suffix_less(input, n, value, suffix[j - 1]):
            suffix[j] = suffix[j - 1]
            j -= 1
        suffix[j] = value
    for i in range(n - 1):
        let a = suffix[i]
        let b = suffix[i + 1]
        var common = 0
        while a + common < n and b + common < n and input[1 + a + common] == input[1 + b + common]: common += 1
        lcp[i] = common
    var lo_stack = InlineArray[Int, 64](fill=0)
    var hi_stack = InlineArray[Int, 64](fill=0)
    var top = 1
    hi_stack[0] = n - 1
    while top > 0:
        top -= 1
        let lo = lo_stack[top]
        let hi = hi_stack[top]
        if hi - lo < 2: continue
        let mid = (lo + hi + 1) // 2
        var q = n + 1
        for i in range(lo, mid): q = min(q, lcp[i])
        left_q[lo * 32 + hi] = q
        q = n + 1
        for i in range(mid, hi): q = min(q, lcp[i])
        right_q[lo * 32 + hi] = q
        if hi - mid >= 2:
            lo_stack[top] = mid
            hi_stack[top] = hi
            top += 1
        if mid - lo >= 2:
            lo_stack[top] = lo
            hi_stack[top] = mid
            top += 1
    let first = suffix_bound(input, n, m, suffix, left_q, right_q, False)
    let last = suffix_bound(input, n, m, suffix, left_q, right_q, True)
    let count = last - first
    let bytes = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(count + 1):
        var value = count
        if word > 0: value = suffix[first + word - 1]
        var bits = UInt64(value)
        for byte in range(8):
            output[8 * word + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
