from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime KML_N = 64
comptime KML_K = 4
comptime KML_LEVELS = 7
comptime KML_OUTPUT = 320
comptime KML_INPUT = 67

fn kml_pair_less(a: Int, b: Int, width: Int, mut rank: InlineArray[Int, KML_N], n: Int) -> Bool:
    if rank[a] != rank[b]: return rank[a] < rank[b]
    let ra = if a + width < n: rank[a + width] else: -1
    let rb = if b + width < n: rank[b + width] else: -1
    ra < rb

fn kml_lce(a: Int, b: Int, n: Int, mut inverse: InlineArray[Int, KML_N],
           mut sparse: InlineArray[Int, KML_LEVELS * KML_N],
           mut logs: InlineArray[Int, KML_N + 1]) -> Int:
    if a >= n or b >= n: return 0
    if a == b: return n - a
    var left = inverse[a]
    var right = inverse[b]
    if left > right:
        let temporary = left
        left = right
        right = temporary
    left += 1
    let count = right - left + 1
    let level = logs[count]
    let span = 1 << level
    return min(sparse[level * KML_N + left], sparse[level * KML_N + right - span + 1])

@export("k_mismatch_longest_extension_table")
fn k_mismatch_longest_extension_table(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > KML_INPUT:
        return -1
    let n_value = input[0]
    let budget_value = input[1]
    if n_value < 1 or n_value > KML_N or budget_value < 0 or budget_value > KML_K:
        return -1
    let n = Int(n_value)
    let budget = Int(budget_value)
    if length != c_size_t(n + 2): return -1

    var text = InlineArray[Int, KML_N](fill=0)
    var suffixes = InlineArray[Int, KML_N](fill=0)
    var rank = InlineArray[Int, KML_N](fill=0)
    var inverse = InlineArray[Int, KML_N](fill=0)
    var lcp = InlineArray[Int, KML_N](fill=0)
    var sparse = InlineArray[Int, KML_LEVELS * KML_N](fill=0)
    var logs = InlineArray[Int, KML_N + 1](fill=0)
    var staged = InlineArray[UInt8, KML_OUTPUT](fill=0)
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] > 25: return -1
        text[i] = Int(input[i + 2])
        suffixes[i] = i
        rank[i] = text[i]

    var width = 1
    while width < n:
        for i in range(1, n):
            let key = suffixes[i]
            var j = i
            while j > 0 and kml_pair_less(key, suffixes[j - 1], width, mut rank, n):
                suffixes[j] = suffixes[j - 1]
                j -= 1
            suffixes[j] = key
        var next_rank = InlineArray[Int, KML_N](fill=0)
        var classes = 0
        next_rank[suffixes[0]] = 0
        for i in range(1, n):
            let a = suffixes[i - 1]
            let b = suffixes[i]
            let a2 = if a + width < n: rank[a + width] else: -1
            let b2 = if b + width < n: rank[b + width] else: -1
            if rank[a] != rank[b] or a2 != b2: classes += 1
            next_rank[b] = classes
        rank = next_rank
        if classes == n - 1 or width > n // 2: break
        width *= 2

    for i in range(n): inverse[suffixes[i]] = i
    var matched = 0
    for start in range(n):
        let order = inverse[start]
        if order == 0:
            matched = 0
            continue
        let other = suffixes[order - 1]
        while start + matched < n and other + matched < n and text[start + matched] == text[other + matched]:
            matched += 1
        lcp[order] = matched
        if matched > 0: matched -= 1
    for i in range(n): sparse[i] = lcp[i]
    for level in range(1, KML_LEVELS):
        let span = 1 << level
        let half = span // 2
        for i in range(max(0, n - span + 1)):
            sparse[level * KML_N + i] = min(sparse[(level - 1) * KML_N + i], sparse[(level - 1) * KML_N + i + half])
    for count in range(2, n + 1): logs[count] = logs[count // 2] + 1

    var written = 0
    for p in range(n):
        let limit = n - p
        var extension = min(limit, kml_lce(0, p, n, mut inverse, mut sparse, mut logs))
        staged[written] = UInt8(extension)
        written += 1
        for _ in range(1, budget + 1):
            if extension < limit:
                extension = min(limit, extension + 1 + kml_lce(extension + 1, p + extension + 1, n, mut inverse, mut sparse, mut logs))
            staged[written] = UInt8(extension)
            written += 1
    if written > KML_OUTPUT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written): return -2
    for i in range(written): output[i] = staged[i]
    Int64(written)
