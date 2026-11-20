from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 12
comptime MAX_PATTERN = 8
comptime MAX_SIGMA = 4
comptime MAX_SUFFIXES = MAX_TEXT + 1
comptime MAX_NODES = 2 * MAX_SUFFIXES - 1
comptime MAX_INPUT = 24
comptime MAX_OUTPUT = 16

struct TrayNode(Copyable):
    var edge_start: Int
    var edge_length: Int
    var depth: Int
    var leaf_start: Int
    var child: InlineArray[Int, 5]
    var leaf_count: Int
    var sa_left: Int
    var sa_right: Int
    var sigma: Bool
    var kind: Int
    var sigma_child_count: Int
    var sigma_child: InlineArray[Int, 5]
    var child_by_symbol: InlineArray[Int, MAX_SIGMA]
    var group_by_symbol: InlineArray[Int, MAX_SIGMA]
    var gap_count: Int
    var gap_left: InlineArray[Int, 5]
    var gap_right: InlineArray[Int, 5]
    var separator: Int
    var only_sigma_child: Int
    var left_valid: Bool
    var left_interval: InlineArray[Int, 2]
    var right_valid: Bool
    var right_interval: InlineArray[Int, 2]

    fn __init__(out self):
        self.edge_start = 0
        self.edge_length = 0
        self.depth = 0
        self.leaf_start = -1
        self.child = InlineArray[Int, 5](fill=-1)
        self.leaf_count = 0
        self.sa_left = 0
        self.sa_right = -1
        self.sigma = False
        self.kind = 0
        self.sigma_child_count = 0
        self.sigma_child = InlineArray[Int, 5](fill=-1)
        self.child_by_symbol = InlineArray[Int, MAX_SIGMA](fill=-1)
        self.group_by_symbol = InlineArray[Int, MAX_SIGMA](fill=-1)
        self.gap_count = 0
        self.gap_left = InlineArray[Int, 5](fill=-1)
        self.gap_right = InlineArray[Int, 5](fill=-1)
        self.separator = -1
        self.only_sigma_child = -1
        self.left_valid = False
        self.left_interval = InlineArray[Int, 2](fill=-1)
        self.right_valid = False
        self.right_interval = InlineArray[Int, 2](fill=-1)

fn suffix_compare(text: InlineArray[Int, MAX_SUFFIXES], a: Int, b: Int, length: Int) -> Int:
    var offset = 0
    while a + offset < length and b + offset < length:
        if text[a + offset] != text[b + offset]:
            return -1 if text[a + offset] < text[b + offset] else 1
        offset += 1
    if a + offset == length and b + offset == length: return 0
    return -1 if a + offset == length else 1

fn build_suffix_array(text: InlineArray[Int, MAX_SUFFIXES], length: Int,
                      inout suffixes: InlineArray[Int, MAX_SUFFIXES],
                      inout rank: InlineArray[Int, MAX_SUFFIXES]):
    for i in range(length): suffixes[i] = i
    for i in range(1, length):
        let item = suffixes[i]
        var j = i
        while j > 0 and suffix_compare(text, item, suffixes[j - 1], length) < 0:
            suffixes[j] = suffixes[j - 1]
            j -= 1
        suffixes[j] = item
    for i in range(length): rank[suffixes[i]] = i

fn insert_suffix(inout nodes: InlineArray[TrayNode, MAX_NODES], inout node_count: Int,
                 text: InlineArray[Int, MAX_SUFFIXES], text_length: Int, start: Int):
    var current = 0
    var position = start
    while position < text_length:
        let symbol = text[position]
        let child_id = nodes[current].child[symbol + 1]
        if child_id < 0:
            let id = node_count
            node_count += 1
            let edge_length = text_length - position
            nodes[id] = TrayNode()
            nodes[id].edge_start = position
            nodes[id].edge_length = edge_length
            nodes[id].depth = nodes[current].depth + edge_length
            nodes[id].leaf_start = start
            nodes[current].child[symbol + 1] = id
            return
        var common = 0
        while common < nodes[child_id].edge_length and position + common < text_length and text[position + common] == text[nodes[child_id].edge_start + common]:
            common += 1
        if common == nodes[child_id].edge_length:
            position += common
            current = child_id
            continue
        let split_id = node_count
        node_count += 1
        let old_start = nodes[child_id].edge_start
        nodes[split_id] = TrayNode()
        nodes[split_id].edge_start = old_start
        nodes[split_id].edge_length = common
        nodes[split_id].depth = nodes[current].depth + common
        nodes[current].child[symbol + 1] = split_id
        nodes[child_id].edge_start += common
        nodes[child_id].edge_length -= common
        nodes[split_id].child[text[nodes[child_id].edge_start] + 1] = child_id
        let new_start = position + common
        let new_id = node_count
        node_count += 1
        let new_length = text_length - new_start
        nodes[new_id] = TrayNode()
        nodes[new_id].edge_start = new_start
        nodes[new_id].edge_length = new_length
        nodes[new_id].depth = nodes[split_id].depth + new_length
        nodes[new_id].leaf_start = start
        nodes[split_id].child[text[new_start] + 1] = new_id
        return

fn summarize_node(inout nodes: InlineArray[TrayNode, MAX_NODES], node_id: Int,
                  rank: InlineArray[Int, MAX_SUFFIXES], sigma: Int):
    if nodes[node_id].leaf_start >= 0:
        nodes[node_id].leaf_count = 1
        nodes[node_id].sa_left = rank[nodes[node_id].leaf_start]
        nodes[node_id].sa_right = nodes[node_id].sa_left
        return
    var children = InlineArray[Int, 5](fill=0)
    var count = 0
    for symbol in range(-1, sigma):
        let child = nodes[node_id].child[symbol + 1]
        if child >= 0:
            children[count] = child
            count += 1
    nodes[node_id].leaf_count = 0
    nodes[node_id].sa_left = MAX_SUFFIXES
    nodes[node_id].sa_right = -1
    for i in range(count):
        let child = children[i]
        summarize_node(inout nodes, child, rank, sigma)
        nodes[node_id].leaf_count += nodes[child].leaf_count
        if nodes[child].sa_left < nodes[node_id].sa_left: nodes[node_id].sa_left = nodes[child].sa_left
        if nodes[child].sa_right > nodes[node_id].sa_right: nodes[node_id].sa_right = nodes[child].sa_right

fn build_tray(inout nodes: InlineArray[TrayNode, MAX_NODES], node_count: Int, sigma: Int,
              text: InlineArray[Int, MAX_SUFFIXES]):
    for id in range(node_count): nodes[id].sigma = nodes[id].leaf_count >= sigma
    for id in range(node_count):
        if not nodes[id].sigma: continue
        var children = InlineArray[Int, 5](fill=0)
        var child_count = 0
        for symbol in range(-1, sigma):
            let child = nodes[id].child[symbol + 1]
            if child >= 0:
                children[child_count] = child
                child_count += 1
        var sigma_children = InlineArray[Int, 5](fill=0)
        var sig_count = 0
        for i in range(child_count):
            if nodes[children[i]].sigma:
                sigma_children[sig_count] = children[i]
                sig_count += 1
        nodes[id].sigma_child_count = sig_count
        for i in range(sig_count): nodes[id].sigma_child[i] = sigma_children[i]
        if sig_count == 0:
            nodes[id].kind = 3
            continue
        if sig_count == 1:
            nodes[id].kind = 2
            let child = sigma_children[0]
            nodes[id].only_sigma_child = child
            nodes[id].separator = text[nodes[child].edge_start]
            var left = InlineArray[Int, 5](fill=0)
            var right = InlineArray[Int, 5](fill=0)
            var left_count = 0
            var right_count = 0
            var after = False
            for i in range(child_count):
                let item = children[i]
                if item == child:
                    after = True
                    continue
                if not nodes[item].sigma:
                    if after:
                        right[right_count] = item
                        right_count += 1
                    else:
                        left[left_count] = item
                        left_count += 1
            if left_count == 0:
                nodes[id].left_valid = False
                nodes[id].left_interval[0] = -1
                nodes[id].left_interval[1] = -1
            else:
                nodes[id].left_valid = True
                nodes[id].left_interval[0] = nodes[left[0]].sa_left
                nodes[id].left_interval[1] = nodes[left[left_count - 1]].sa_right
            if right_count == 0:
                nodes[id].right_valid = False
                nodes[id].right_interval[0] = -1
                nodes[id].right_interval[1] = -1
            else:
                nodes[id].right_valid = True
                nodes[id].right_interval[0] = nodes[right[0]].sa_left
                nodes[id].right_interval[1] = nodes[right[right_count - 1]].sa_right
            continue
        nodes[id].kind = 1
        var gaps = InlineArray[InlineArray[Int, 5], 6](fill=InlineArray[Int, 5](fill=0))
        var gap_counts = InlineArray[Int, 6](fill=0)
        var gap = 0
        for i in range(child_count):
            let item = children[i]
            if nodes[item].sigma:
                gap += 1
            else:
                gaps[gap][gap_counts[gap]] = item
                gap_counts[gap] += 1
        nodes[id].gap_count = sig_count + 1
        for g in range(sig_count + 1):
            if gap_counts[g] > 0:
                nodes[id].gap_left[g] = nodes[gaps[g][0]].sa_left
                nodes[id].gap_right[g] = nodes[gaps[g][gap_counts[g] - 1]].sa_right
        for symbol in range(sigma):
            var found = -1
            var preceding = 0
            for i in range(sig_count):
                let first = text[nodes[sigma_children[i]].edge_start]
                if first == symbol:
                    found = sigma_children[i]
                    break
                if first < symbol: preceding += 1
            if found >= 0:
                nodes[id].child_by_symbol[symbol] = found
            elif gap_counts[preceding] > 0:
                nodes[id].group_by_symbol[symbol] = preceding

fn compare_suffix_pattern(text: InlineArray[Int, MAX_SUFFIXES], text_length: Int,
                          suffix_start: Int, pattern: InlineArray[Int, MAX_PATTERN],
                          q: Int, start_at: Int, inout lcp: Int) -> Int:
    var i = start_at
    while i < q and suffix_start + i < text_length:
        if text[suffix_start + i] != pattern[i]:
            lcp = i
            return -1 if text[suffix_start + i] < pattern[i] else 1
        i += 1
    lcp = i
    return 1 if i == q else -1

fn interval_search(text: InlineArray[Int, MAX_SUFFIXES], text_length: Int,
                   pattern: InlineArray[Int, MAX_PATTERN], q: Int,
                   suffixes: InlineArray[Int, MAX_SUFFIXES], lo: Int, hi: Int,
                   known_prefix: Int) -> Int:
    var low = lo - 1
    var high = hi + 1
    var low_lcp = known_prefix
    var high_lcp = known_prefix
    while high - low > 1:
        let middle = (low + high) // 2
        var lcp = known_prefix
        let start_at = low_lcp if low_lcp < high_lcp else high_lcp
        let comparison = compare_suffix_pattern(text, text_length, suffixes[middle], pattern, q, start_at, inout lcp)
        if comparison < 0:
            low = middle
            low_lcp = lcp
        else:
            high = middle
            high_lcp = lcp
    if high > hi: return -1
    let start = suffixes[high]
    if start + q > text_length: return -1
    for i in range(q):
        if text[start + i] != pattern[i]: return -1
    return start

fn tray_query(text: InlineArray[Int, MAX_SUFFIXES], text_length: Int,
              pattern: InlineArray[Int, MAX_PATTERN], q: Int, sigma: Int,
              suffixes: InlineArray[Int, MAX_SUFFIXES],
              inout nodes: InlineArray[TrayNode, MAX_NODES]) -> Int:
    var current = 0
    var matched = 0
    while True:
        if matched == q: return suffixes[nodes[current].sa_left]
        let symbol = pattern[matched]
        if not nodes[current].sigma or nodes[current].kind == 3:
            return interval_search(text, text_length, pattern, q, suffixes,
                                   nodes[current].sa_left, nodes[current].sa_right, matched)
        var next = -1
        var interval_left = -1
        var interval_right = -1
        if nodes[current].kind == 1:
            if symbol < 0 or symbol >= sigma: return -1
            next = nodes[current].child_by_symbol[symbol]
            if next < 0:
                let group = nodes[current].group_by_symbol[symbol]
                if group < 0 or nodes[current].gap_left[group] < 0: return -1
                interval_left = nodes[current].gap_left[group]
                interval_right = nodes[current].gap_right[group]
        else:
            next = nodes[current].only_sigma_child
            if symbol != nodes[current].separator:
                if symbol < nodes[current].separator:
                    if not nodes[current].left_valid: return -1
                    interval_left = nodes[current].left_interval[0]
                    interval_right = nodes[current].left_interval[1]
                else:
                    if not nodes[current].right_valid: return -1
                    interval_left = nodes[current].right_interval[0]
                    interval_right = nodes[current].right_interval[1]
        if interval_left >= 0:
            return interval_search(text, text_length, pattern, q, suffixes, interval_left, interval_right, matched)
        if next < 0: return -1
        let representative = suffixes[nodes[next].sa_left]
        var edge_position = nodes[current].depth
        while matched < q and edge_position < nodes[next].depth:
            if text[representative + edge_position] != pattern[matched]: return -1
            matched += 1
            edge_position += 1
        if matched == q: return suffixes[nodes[next].sa_left]
        if edge_position != nodes[next].depth: return -1
        current = next
    return -1

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for i in range(8): output[position + i] = UInt8((bits >> (8 * i)) & 255)

@export("suffix_tray_pattern_query")
fn suffix_tray_pattern_query(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT: return -1
    let sigma64 = input[0]
    let n64 = input[1]
    let q64 = input[2]
    if sigma64 < 2 or sigma64 > MAX_SIGMA or n64 < 1 or n64 > MAX_TEXT or q64 < 1 or q64 > MAX_PATTERN: return -1
    let sigma = Int(sigma64)
    let n = Int(n64)
    let q = Int(q64)
    if Int(length) != 3 + n + q: return -1
    var text = InlineArray[Int, MAX_SUFFIXES](fill=0)
    var pattern = InlineArray[Int, MAX_PATTERN](fill=0)
    for i in range(n):
        if input[3 + i] < 0 or input[3 + i] >= sigma64: return -1
        text[i] = Int(input[3 + i])
    text[n] = -1
    for i in range(q):
        if input[3 + n + i] < 0 or input[3 + n + i] >= sigma64: return -1
        pattern[i] = Int(input[3 + n + i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(MAX_OUTPUT): return -2
    var suffixes = InlineArray[Int, MAX_SUFFIXES](fill=0)
    var rank = InlineArray[Int, MAX_SUFFIXES](fill=0)
    build_suffix_array(text, n + 1, inout suffixes, inout rank)
    var nodes = InlineArray[TrayNode, MAX_NODES](fill=TrayNode())
    var node_count = 1
    for start in range(n + 1): insert_suffix(inout nodes, inout node_count, text, n + 1, start)
    summarize_node(inout nodes, 0, rank, sigma)
    build_tray(inout nodes, node_count, sigma, text)
    let found = tray_query(text, n + 1, pattern, q, sigma, suffixes, inout nodes)
    put_i64_le(output, 0, Int64(0) if found < 0 else Int64(1))
    put_i64_le(output, 8, Int64(found))
    return MAX_OUTPUT
