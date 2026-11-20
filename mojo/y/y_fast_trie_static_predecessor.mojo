from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_KEYS = 256
comptime MAX_QUERIES = 256
comptime BUCKET_SIZE = 16
comptime MAX_BUCKETS = 16
comptime MAX_TRIE_NODES = 257
comptime MAX_INPUT_VALUES = 514
comptime MAX_PARSEABLE_VALUES = 515
comptime UNIVERSE_BITS = 16

fn yft_successor_bucket(children: InlineArray[Int, 2 * MAX_TRIE_NODES],
                        min_rank: InlineArray[Int, MAX_TRIE_NODES],
                        leaf_rank: InlineArray[Int, MAX_TRIE_NODES],
                        query: Int, bucket_count: Int) -> Int:
    if bucket_count == 0: return -1
    var node = 0
    var candidate = -1
    for bit_position in range(UNIVERSE_BITS):
        let shift = UNIVERSE_BITS - 1 - bit_position
        let branch = (query >> shift) & 1
        if branch == 0:
            let right_child = children[node * 2 + 1]
            if right_child >= 0: candidate = min_rank[right_child]
        let next_node = children[node * 2 + branch]
        if next_node < 0:
            node = -1
            break
        node = next_node
    if node >= 0 and leaf_rank[node] >= 0: return leaf_rank[node]
    if candidate >= 0: return candidate
    return bucket_count - 1

fn yft_lower_bound(keys: InlineArray[Int, MAX_KEYS], start: Int, end: Int, query: Int) -> Int:
    var low = start
    var high = end
    while low < high:
        let middle = low + (high - low) // 2
        if keys[middle] < query: low = middle + 1
        else: high = middle
    return low

fn yft_upper_bound(keys: InlineArray[Int, MAX_KEYS], start: Int, end: Int, query: Int) -> Int:
    var low = start
    var high = end
    while low < high:
        let middle = low + (high - low) // 2
        if keys[middle] <= query: low = middle + 1
        else: high = middle
    return low

@export("y_fast_trie_static_predecessor")
fn y_fast_trie_static_predecessor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_VALUES:
        return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 0 or n64 > MAX_KEYS or q64 < 0 or q64 > MAX_QUERIES:
        return -1
    let n = Int(n64)
    let q = Int(q64)
    if length != c_size_t(2 + n + q) or length > MAX_INPUT_VALUES:
        return -1

    var keys = InlineArray[Int, MAX_KEYS](fill=0)
    var queries = InlineArray[Int, MAX_QUERIES](fill=0)
    for index in range(n):
        let value = input[2 + index]
        if value < 0 or value > 65535: return -1
        keys[index] = Int(value)
    for index in range(1, n):
        let key = keys[index]
        var position = index
        while position > 0 and key < keys[position - 1]:
            keys[position] = keys[position - 1]
            position -= 1
        keys[position] = key
    for index in range(1, n):
        if keys[index] == keys[index - 1]: return -1
    for index in range(q):
        let value = input[2 + n + index]
        if value < 0 or value > 65535: return -1
        queries[index] = Int(value)
    if n == 0 or q == 0: return 0

    let bucket_count = (n + BUCKET_SIZE - 1) // BUCKET_SIZE
    var children = InlineArray[Int, 2 * MAX_TRIE_NODES](fill=-1)
    var min_rank = InlineArray[Int, MAX_TRIE_NODES](fill=-1)
    var leaf_rank = InlineArray[Int, MAX_TRIE_NODES](fill=-1)
    var node_count = 1
    min_rank[0] = 0
    for bucket in range(bucket_count):
        let end = min((bucket + 1) * BUCKET_SIZE, n)
        let separator = keys[end - 1]
        var node = 0
        for bit_position in range(UNIVERSE_BITS):
            let shift = UNIVERSE_BITS - 1 - bit_position
            let branch = (separator >> shift) & 1
            let slot = node * 2 + branch
            var child = children[slot]
            if child < 0:
                child = node_count
                children[slot] = child
                min_rank[child] = bucket
                node_count += 1
            elif min_rank[child] < 0 or bucket < min_rank[child]:
                min_rank[child] = bucket
            node = child
        leaf_rank[node] = bucket

    var checksum: Int64 = 0
    for index in range(q):
        let query = queries[index]
        let bucket = yft_successor_bucket(children, min_rank, leaf_rank, query, bucket_count)
        let start = bucket * BUCKET_SIZE
        let end = min(start + BUCKET_SIZE, n)
        let lower = yft_lower_bound(keys, start, end, query)
        let upper = yft_upper_bound(keys, start, end, query)
        var predecessor: Int64 = -1
        var successor: Int64 = -1
        if lower > start: predecessor = Int64(keys[lower - 1])
        elif bucket > 0: predecessor = Int64(keys[start - 1])
        if upper < end: successor = Int64(keys[upper])
        elif bucket + 1 < bucket_count: successor = Int64(keys[end])
        let contribution = Int64(index + 1) * ((predecessor + 1) + 65537 * (successor + 1))
        checksum += contribution
    return checksum
