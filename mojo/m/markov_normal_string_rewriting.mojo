from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_RULES = 8
const MAX_WORD = 64
const MAX_INPUT = 204

@export("markov_normal_string_rewriting")
fn markov_normal_string_rewriting(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT: return -1
    let rule_word = values[0]
    let step_word = values[1]
    let initial_word = values[2]
    if rule_word < 0 or rule_word > MAX_RULES or step_word < 0 or step_word > 32 or initial_word < 0 or initial_word > 48: return -1
    let rule_count = rule_word
    let step_limit = step_word
    var word = InlineArray[Int64, MAX_WORD]()
    var word_length = initial_word
    var cursor = 3
    if length < c_size_t(cursor + word_length): return -1
    for index in range(word_length):
        let symbol = values[cursor]
        if symbol < 0 or symbol > 25: return -1
        word[index] = symbol
        cursor += 1
    var kind = InlineArray[Int64, MAX_RULES]()
    var left_length = InlineArray[Int64, MAX_RULES]()
    var right_length = InlineArray[Int64, MAX_RULES]()
    var left = InlineArray[Int64, MAX_RULES * 8]()
    var right = InlineArray[Int64, MAX_RULES * 8]()
    for r in range(rule_count):
        if c_size_t(cursor + 3) > length: return -1
        let rule_kind = values[cursor]
        let lhs_len = values[cursor + 1]
        let rhs_len = values[cursor + 2]
        cursor += 3
        if (rule_kind != 0 and rule_kind != 1) or lhs_len < 1 or lhs_len > 8 or rhs_len < 0 or rhs_len > 8: return -1
        if c_size_t(cursor + lhs_len + rhs_len) > length: return -1
        kind[r] = rule_kind
        left_length[r] = lhs_len
        right_length[r] = rhs_len
        for j in range(lhs_len):
            let symbol = values[cursor]
            if symbol < 0 or symbol > 25: return -1
            left[r * 8 + j] = symbol
            cursor += 1
        for j in range(rhs_len):
            let symbol = values[cursor]
            if symbol < 0 or symbol > 25: return -1
            right[r * 8 + j] = symbol
            cursor += 1
    if c_size_t(cursor) != length: return -1

    var rewrites = 0
    var halt: UInt8 = 0
    while True:
        var chosen = rule_count
        var offset = 0
        for r in range(rule_count):
            if chosen != rule_count: break
            let lhs_len = left_length[r]
            if lhs_len > word_length: continue
            for at in range(word_length - lhs_len + 1):
                var same = True
                for j in range(lhs_len):
                    if word[at + j] != left[r * 8 + j]:
                        same = False
                        break
                if same:
                    chosen = r
                    offset = at
                    break
        if chosen == rule_count:
            halt = 0
            break
        if rewrites == step_limit:
            halt = 2
            break
        let lhs_len = left_length[chosen]
        let rhs_len = right_length[chosen]
        let new_length = word_length - lhs_len + rhs_len
        if new_length > MAX_WORD: return -3
        var next = InlineArray[Int64, MAX_WORD]()
        var out = 0
        for i in range(offset):
            next[out] = word[i]
            out += 1
        for i in range(rhs_len):
            next[out] = right[chosen * 8 + i]
            out += 1
        for i in range(offset + lhs_len, word_length):
            next[out] = word[i]
            out += 1
        word = next
        word_length = new_length
        rewrites += 1
        if kind[chosen] == 1:
            halt = 1
            break

    let needed = 3 + word_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    output[0] = halt
    output[1] = UInt8(rewrites)
    output[2] = UInt8(word_length)
    for i in range(word_length): output[i + 3] = UInt8(word[i])
    Int64(needed)
