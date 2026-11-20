from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_NODES = 32
alias MAX_POINTER = 64
alias RECORD_WORDS = 21

fn field(values: UnsafePointer[Int64, ImmutAnyOrigin], base: Int, node: Int, offset: Int) -> Int64:
    return values[base + node * RECORD_WORDS + offset]

@export("json_pointer_evaluation")
fn json_pointer_evaluation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let n_value = values[0]
    let root_value = values[1]
    let pointer_value = values[2]
    if n_value < 1 or n_value > MAX_NODES or root_value < 0 or root_value >= n_value or pointer_value < 0 or pointer_value > MAX_POINTER:
        return -1
    let n = Int(n_value)
    let root = Int(root_value)
    let pointer_length = Int(pointer_value)
    let base = 3 + pointer_length
    if length != base + n * RECORD_WORDS: return -1
    for i in range(pointer_length):
        if values[3 + i] < 0 or values[3 + i] > 127: return -1
    if pointer_length != 0 and values[3] != 47: return -1
    var syntax_pos = 1
    while syntax_pos < pointer_length:
        if values[3 + syntax_pos] == 126:
            syntax_pos += 1
            if syntax_pos >= pointer_length: return -1
            let escaped = values[3 + syntax_pos]
            if escaped != 48 and escaped != 49: return -1
        syntax_pos += 1

    for i in range(n):
        let kind = field(values, base, i, 0)
        let parent = field(values, base, i, 1)
        let key_length = field(values, base, i, 2)
        let array_index = field(values, base, i, 19)
        if kind < 0 or kind > 2 or key_length < 0 or key_length > 16: return -1
        if i == root:
            if parent != -1 or key_length != 0 or array_index != -1: return -1
        else:
            if parent < 0 or parent >= n_value or Int(parent) == i: return -1
            let parent_kind = field(values, base, Int(parent), 0)
            if parent_kind < 0 or parent_kind > 1: return -1
            if parent_kind == 0:
                if array_index != -1: return -1
            elif key_length != 0 or array_index < 0: return -1
        for k in range(16):
            let ch = field(values, base, i, 3 + k)
            if k < Int(key_length):
                if ch < 0 or ch > 127: return -1
            elif ch != 0: return -1
        var cursor = i
        var hops = 0
        while cursor != root and hops < n:
            let next = field(values, base, cursor, 1)
            if next < 0 or next >= n_value: return -1
            cursor = Int(next)
            hops += 1
        if cursor != root: return -1

    for parent in range(n):
        if field(values, base, parent, 0) != 1: continue
        var children = 0
        for child in range(n):
            if field(values, base, child, 1) == Int64(parent): children += 1
        for child in range(n):
            if field(values, base, child, 1) != Int64(parent): continue
            let index = field(values, base, child, 19)
            if index < 0 or Int(index) >= children: return -1
            for prior in range(child):
                if field(values, base, prior, 1) == Int64(parent) and field(values, base, prior, 19) == index: return -1

    var current = root
    if pointer_length == 0: return Int64(current)
    var token = InlineArray[Int64, 64]()
    var token_length = 0
    var pos = 1
    while pos <= pointer_length:
        if pos == pointer_length or values[3 + pos] == 47:
            let kind = field(values, base, current, 0)
            var found = n
            var matches = 0
            if kind == 0:
                for child in range(n):
                    if field(values, base, child, 1) != Int64(current) or field(values, base, child, 2) != Int64(token_length): continue
                    var k = 0
                    while k < token_length and field(values, base, child, 3 + k) == token[k]: k += 1
                    if k == token_length:
                        found = child
                        matches += 1
            elif kind == 1:
                if token_length == 0 or (token_length > 1 and token[0] == 48): return -2
                var index: Int64 = 0
                for k in range(token_length):
                    if token[k] < 48 or token[k] > 57: return -2
                    index = index * 10 + token[k] - 48
                    if index > MAX_NODES: return -2
                for child in range(n):
                    if field(values, base, child, 1) == Int64(current) and field(values, base, child, 19) == index:
                        found = child
                        matches += 1
            else: return -2
            if matches != 1: return -2
            current = found
            token_length = 0
            pos += 1
            continue
        var ch = values[3 + pos]
        if ch == 126:
            pos += 1
            if pos >= pointer_length: return -1
            let escaped = values[3 + pos]
            if escaped == 48: ch = 126
            elif escaped == 49: ch = 47
            else: return -1
        token[token_length] = ch
        token_length += 1
        pos += 1
    return Int64(current)
