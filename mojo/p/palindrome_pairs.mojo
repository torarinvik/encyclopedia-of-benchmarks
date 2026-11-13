from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn pp_palindrome(words: InlineArray[Int32, 64], id: Int, left: Int, right: Int) -> Bool:
    var lo = left
    var hi = right - 1
    while lo < hi:
        if words[id * 8 + lo] != words[id * 8 + hi]: return False
        lo += 1
        hi -= 1
    return True

fn pp_encode(words: InlineArray[Int32, 64], id: Int, left: Int, right: Int, reverse: Bool) -> Int64:
    var key: Int64 = 1
    if reverse:
        var i = right
        while i > left:
            i -= 1
            key = key * 5 + Int64(words[id * 8 + i] + 1)
    else:
        for i in range(left, right): key = key * 5 + Int64(words[id * 8 + i] + 1)
    return key

fn pp_slot(keys: InlineArray[Int64, 17], key: Int64) -> Int:
    var slot = Int(key % 17)
    while keys[slot] != 0 and keys[slot] != key: slot = (slot + 1) % 17
    return slot

fn pp_mark(keys: InlineArray[Int64, 17], heads: InlineArray[Int32, 17], next: InlineArray[Int32, 8],
           key: Int64, fixed: Int, fixed_right: Bool, inout found: InlineArray[Bool, 64]):
    let slot = pp_slot(keys, key)
    if keys[slot] != key: return
    var id = Int(heads[slot])
    while id >= 0:
        if id != fixed:
            if fixed_right: found[id * 8 + fixed] = True
            else: found[fixed * 8 + id] = True
        id = Int(next[id])

@export("palindrome_pairs")
fn palindrome_pairs(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t,
                    out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1 or n > 74: return -1
    if v[0] < 0 or v[0] > 8: return -1
    let count = Int(v[0])
    var words = InlineArray[Int32, 64](fill=0)
    var sizes = InlineArray[Int32, 8](fill=0)
    var cursor = 1
    for id in range(count):
        if cursor >= Int(n) or v[cursor] < 0 or v[cursor] > 8: return -1
        let size = Int(v[cursor]); cursor += 1
        if cursor + size > Int(n): return -1
        sizes[id] = Int32(size)
        for k in range(size):
            if v[cursor] < 0 or v[cursor] >= 4: return -1
            words[id * 8 + k] = Int32(v[cursor]); cursor += 1
    if cursor != Int(n): return -1

    var keys = InlineArray[Int64, 17](fill=0)
    var heads = InlineArray[Int32, 17](fill=-1)
    var next = InlineArray[Int32, 8](fill=-1)
    for id in range(count):
        let key = pp_encode(words, id, 0, Int(sizes[id]), False)
        let slot = pp_slot(keys, key)
        if keys[slot] == 0: keys[slot] = key; heads[slot] = Int32(id)
        else: next[id] = heads[slot]; heads[slot] = Int32(id)

    var found = InlineArray[Bool, 64](fill=False)
    for id in range(count):
        for split in range(Int(sizes[id]) + 1):
            if pp_palindrome(words, id, 0, split):
                pp_mark(keys, heads, next, pp_encode(words, id, split, Int(sizes[id]), True), id, True, inout found)
            if pp_palindrome(words, id, split, Int(sizes[id])):
                pp_mark(keys, heads, next, pp_encode(words, id, 0, split, True), id, False, inout found)
    var staged = InlineArray[UInt8, 56](fill=0)
    var bytes = 0
    for left in range(count):
        for right in range(count):
            if left != right and found[left * 8 + right]:
                staged[bytes] = UInt8(left * 8 + right); bytes += 1
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(bytes): return -2
    for i in range(bytes): out[i] = staged[i]
    return Int64(bytes)
