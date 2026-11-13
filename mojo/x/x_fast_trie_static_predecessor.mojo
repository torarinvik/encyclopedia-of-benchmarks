from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime XFT_MAX_KEYS = 24
comptime XFT_MAX_QUERIES = 24
comptime XFT_UNIVERSE_BITS = 16
comptime XFT_LEVELS = 17
comptime XFT_MAX_PARSEABLE = 51

fn xft_prefix(key: Int64, depth: Int) -> Int64:
    if depth == 0: return 0
    key >> (XFT_UNIVERSE_BITS - depth)

fn xft_find_prefix(prefixes: InlineArray[Int64, XFT_LEVELS * XFT_MAX_KEYS],
        counts: InlineArray[Int, XFT_LEVELS], depth: Int, wanted: Int64) -> Int:
    var low = 0
    var high = counts[depth]
    let row = depth * XFT_MAX_KEYS
    while low < high:
        let middle = low + (high - low) // 2
        if prefixes[row + middle] < wanted: low = middle + 1 else: high = middle
    if low < counts[depth] and prefixes[row + low] == wanted: return low
    -1

fn xft_predecessor(prefixes: InlineArray[Int64, XFT_LEVELS * XFT_MAX_KEYS],
        maxima: InlineArray[Int64, XFT_LEVELS * XFT_MAX_KEYS],
        counts: InlineArray[Int, XFT_LEVELS], query: Int64) -> Int64:
    var low = 0
    var high = XFT_LEVELS
    while high - low > 1:
        let middle = low + (high - low) // 2
        if xft_find_prefix(prefixes, counts, middle, xft_prefix(query, middle)) >= 0: low = middle
        else: high = middle
    if low == XFT_UNIVERSE_BITS: return query
    var depth = low + 1
    while depth > 0:
        let query_prefix = query >> (XFT_UNIVERSE_BITS - depth)
        if (query_prefix & 1) != 0:
            let position = xft_find_prefix(prefixes, counts, depth, query_prefix - 1)
            if position >= 0: return maxima[depth * XFT_MAX_KEYS + position]
        depth -= 1
    -1

fn xft_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > XFT_MAX_PARSEABLE: return -1
    if input[0] < 0 or input[0] > XFT_MAX_KEYS or input[1] < 0 or input[1] > XFT_MAX_QUERIES: return -1
    let n = Int(input[0])
    let q = Int(input[1])
    if length != 2 + n + q: return -1
    var keys = InlineArray[Int64, XFT_MAX_KEYS](fill=0)
    var queries = InlineArray[Int64, XFT_MAX_QUERIES](fill=0)
    for i in range(n):
        keys[i] = input[2 + i]
        if keys[i] < 0 or keys[i] > 65535: return -1
    for i in range(1, n):
        let key = keys[i]
        var at = i
        while at > 0 and key < keys[at - 1]:
            keys[at] = keys[at - 1]
            at -= 1
        keys[at] = key
    for i in range(1, n):
        if keys[i] == keys[i - 1]: return -1
    for i in range(q):
        queries[i] = input[2 + n + i]
        if queries[i] < 0 or queries[i] > 65535: return -1
    if n == 0 or q == 0: return 0

    var prefixes = InlineArray[Int64, XFT_LEVELS * XFT_MAX_KEYS](fill=0)
    var maxima = InlineArray[Int64, XFT_LEVELS * XFT_MAX_KEYS](fill=0)
    var counts = InlineArray[Int, XFT_LEVELS](fill=0)
    for depth in range(XFT_LEVELS):
        for i in range(n):
            let value = xft_prefix(keys[i], depth)
            let row = depth * XFT_MAX_KEYS
            let count = counts[depth]
            if count == 0 or prefixes[row + count - 1] != value:
                prefixes[row + count] = value
                maxima[row + count] = keys[i]
                counts[depth] = count + 1
            else:
                maxima[row + count - 1] = keys[i]
    var checksum: Int64 = 0
    for i in range(q):
        checksum += Int64(i + 1) * (xft_predecessor(prefixes, maxima, counts, queries[i]) + 1)
    checksum

@export("x_fast_trie_static_predecessor")
fn x_fast_trie_static_predecessor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(XFT_MAX_PARSEABLE): return -1
    xft_impl(input, Int(length))
