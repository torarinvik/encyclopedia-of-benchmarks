from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias SB_LIMIT = Int64(1000000000)

fn sb_valid(a: Int64, b: Int64) -> Bool:
    if a < 1 or a > SB_LIMIT or b < 1 or b > SB_LIMIT: return False
    var x = a
    var y = b
    while y != 0:
        let remainder = x % y
        x = y
        y = remainder
    return x == 1

fn sb_encode(a: Int64, b: Int64, mut direction: InlineArray[Int64, 64],
              mut counts: InlineArray[Int64, 64]) -> Int:
    var numerator = a
    var denominator = b
    var size = 0
    while numerator != denominator:
        if size == 64: return -1
        if numerator < denominator:
            let count = (denominator - 1) // numerator
            direction[size] = 0
            counts[size] = count
            denominator -= count * numerator
        else:
            let count = (numerator - 1) // denominator
            direction[size] = 1
            counts[size] = count
            numerator -= count * denominator
        size += 1
    return size

fn sb_decode(direction: InlineArray[Int64, 64], counts: InlineArray[Int64, 64], size: Int,
              mut bounds: InlineArray[Int64, 4]) -> Bool:
    var ln: Int64 = 0
    var ld: Int64 = 1
    var un: Int64 = 1
    var ud: Int64 = 0
    var previous: Int64 = -1
    for i in range(size):
        let direction_value = direction[i]
        let count = counts[i]
        if (direction_value != 0 and direction_value != 1) or direction_value == previous or count < 1 or count > SB_LIMIT: return False
        if direction_value == 0:
            un += count * ln
            ud += count * ld
            if un > SB_LIMIT or ud > SB_LIMIT: return False
        else:
            ln += count * un
            ld += count * ud
            if ln > SB_LIMIT or ld > SB_LIMIT: return False
        previous = direction_value
    if not sb_valid(ln + un, ld + ud): return False
    bounds[0] = ln
    bounds[1] = ld
    bounds[2] = un
    bounds[3] = ud
    return True

@export("stern_brocot_tree")
fn stern_brocot_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 16384: return -1
    let query_count = input[0]
    if query_count < 1 or query_count > 128: return -1
    # At most 128 encoded paths each contribute 130 words, below this bound.
    var words = InlineArray[Int64, 32768](fill=0)
    var word_count = 0
    var pos = 1
    for _ in range(Int(query_count)):
        if c_size_t(pos) >= length: return -1
        let op = input[pos]
        pos += 1
        var dirs = InlineArray[Int64, 64](fill=0)
        var counts = InlineArray[Int64, 64](fill=0)
        var size = 0
        var bounds = InlineArray[Int64, 4](fill=0)
        if op == 1:
            if c_size_t(pos) >= length: return -1
            let run_count = input[pos]
            pos += 1
            if run_count < 0 or run_count > 64 or c_size_t(pos + 2 * Int(run_count)) > length: return -1
            size = Int(run_count)
            for i in range(size):
                dirs[i] = input[pos]
                counts[i] = input[pos + 1]
                pos += 2
            if not sb_decode(dirs, counts, size, mut bounds): return -1
            words[word_count] = op
            words[word_count + 1] = bounds[0] + bounds[2]
            words[word_count + 2] = bounds[1] + bounds[3]
            word_count += 3
        elif op == 0 or op == 2 or op == 3 or op == 4:
            var depth: Int64 = 0
            if op == 3:
                if c_size_t(pos) >= length: return -1
                depth = input[pos]
                pos += 1
                if depth < 1 or depth > SB_LIMIT: return -1
            let needed = 4 if op == 2 else 2
            if c_size_t(pos + needed) > length: return -1
            let a = input[pos]
            let b = input[pos + 1]
            pos += 2
            if not sb_valid(a, b): return -1
            size = sb_encode(a, b, mut dirs, mut counts)
            if size < 0: return -1
            if op == 0:
                words[word_count] = op
                words[word_count + 1] = Int64(size)
                word_count += 2
                for i in range(size):
                    words[word_count] = dirs[i]
                    words[word_count + 1] = counts[i]
                    word_count += 2
                continue
            if op == 2:
                let c = input[pos]
                let d = input[pos + 1]
                pos += 2
                if not sb_valid(c, d): return -1
                var other_dirs = InlineArray[Int64, 64](fill=0)
                var other_counts = InlineArray[Int64, 64](fill=0)
                let other_size = sb_encode(c, d, mut other_dirs, mut other_counts)
                if other_size < 0: return -1
                var shared = 0
                # A partial common run ends the prefix: subsequent directions differ.
                while shared < size and shared < other_size and dirs[shared] == other_dirs[shared]:
                    let left = counts[shared]
                    let right = other_counts[shared]
                    counts[shared] = min(left, right)
                    shared += 1
                    if left != right: break
                size = shared
            elif op == 3:
                var total: Int64 = 0
                for i in range(size): total += counts[i]
                if depth > total:
                    words[word_count] = op
                    words[word_count + 1] = -1
                    word_count += 2
                    continue
                var remaining = depth
                var prefix = 0
                while prefix < size and remaining > 0:
                    let take = min(remaining, counts[prefix])
                    counts[prefix] = take
                    remaining -= take
                    prefix += 1
                size = prefix
            if not sb_decode(dirs, counts, size, mut bounds): return -1
            words[word_count] = op
            word_count += 1
            if op == 4:
                for i in range(4):
                    words[word_count] = bounds[i]
                    word_count += 1
            else:
                words[word_count] = bounds[0] + bounds[2]
                words[word_count + 1] = bounds[1] + bounds[3]
                word_count += 2
        else:
            return -1
    if c_size_t(pos) != length: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * word_count): return -2
    for i in range(word_count):
        var bits = UInt64(0xffffffffffffffff)
        if words[i] >= 0: bits = UInt64(words[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return query_count
