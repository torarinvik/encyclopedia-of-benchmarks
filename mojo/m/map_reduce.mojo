from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn map_reduce_space(x: Int64) -> Bool:
    return x == 9 or x == 10 or x == 11 or x == 12 or x == 13 or x == 32
fn map_reduce_equal(v: UnsafePointer[Int64, ImmutAnyOrigin], s: Int, l: Int, os: Int, ol: Int) -> Bool:
    if l != ol: return False
    for i in range(l):
        if v[s+i] != v[os+i]: return False
    return True
fn map_reduce_hash(v: UnsafePointer[Int64, ImmutAnyOrigin], s: Int, l: Int) -> Int:
    var h = 0
    for i in range(l): h = (h*31 + Int(v[s+i])) % 1000003
    return h % 512
fn map_reduce_digit_count(mut out: InlineArray[UInt8, 1024], mut pos: Int, value: Int):
    var x = value; var digits = InlineArray[UInt8, 3](fill=0); var count = 0
    while True:
        digits[count] = UInt8(48 + x%10); count += 1; x /= 10
        if x == 0: break
    for i in range(count): out[pos] = digits[count-1-i]; pos += 1

@export("map_reduce")
fn map_reduce(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if n > 256 or (n > 0 and v == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(n)):
        let x = v[i]
        if not map_reduce_space(x) and (x < 32 or x > 126): return -1
    var starts = InlineArray[Int, 128](fill=0); var lengths = InlineArray[Int, 128](fill=0); var counts = InlineArray[Int, 128](fill=0)
    var table = InlineArray[Int, 512](fill=0); var unique = 0
    var begin = 0; var end = Int(n)
    while begin < end and v[begin] <= 32: begin += 1
    while end > begin and v[end-1] <= 32: end -= 1
    if begin == end:
        starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique = 1; table[0] = 1
    else:
        var cursor = begin
        while cursor < end:
            while cursor < end and map_reduce_space(v[cursor]): cursor += 1
            if cursor == end: break
            let start = cursor
            while cursor < end and not map_reduce_space(v[cursor]): cursor += 1
            let length = cursor - start
            var slot = map_reduce_hash(v, start, length)
            while table[slot] != 0:
                let item = table[slot] - 1
                if map_reduce_equal(v, start, length, starts[item], lengths[item]): counts[item] += 1; break
                slot = (slot + 1) % 512
            if table[slot] == 0:
                starts[unique] = start; lengths[unique] = length; counts[unique] = 1; table[slot] = unique+1; unique += 1
    var required = 0
    for item in range(unique):
        var digits = 1; var x = counts[item]
        while x >= 10: x /= 10; digits += 1
        required += lengths[item] + 2 + digits + (1 if item != 0 else 0)
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(required): return -2
    var staged = InlineArray[UInt8, 1024](fill=0); var written = 0
    for item in range(unique):
        if item != 0: staged[written] = 44; written += 1
        for j in range(lengths[item]): staged[written] = UInt8(v[starts[item]+j]); written += 1
        staged[written] = 58; staged[written+1] = 32; written += 2
        map_reduce_digit_count(mut staged, mut written, counts[item])
    for i in range(written): out[i] = staged[i]
    return Int64(written)
