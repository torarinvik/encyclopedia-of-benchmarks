from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn popcount64(value: UInt64) -> Int32:
    var remaining = value
    var count: Int32 = 0
    while remaining != 0:
        remaining &= remaining - 1
        count += 1
    return count

fn store_i32_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int32):
    var bits = bitcast[UInt32](value)
    for byte in range(4):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("bitset_xor_shift_trace")
fn bitset_xor_shift_trace(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 131: return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 1 or n64 > 4096 or q64 < 0 or q64 > 64: return -1
    let n = Int(n64)
    let q = Int(q64)
    let word_count = (n + 63) // 64
    let shift_offset = 2 + word_count
    if length != c_size_t(shift_offset + q): return -1

    var words = InlineArray[UInt64, 64](fill=0)
    for word in range(word_count): words[word] = bitcast[UInt64](input[2 + word])
    let tail_bits = n % 64
    let tail_mask: UInt64 = if tail_bits == 0 then UInt64(0) - 1 else (UInt64(1) << tail_bits) - 1
    if (words[word_count - 1] & ~tail_mask) != 0: return -1
    for operation in range(q):
        let shift = input[shift_offset + operation]
        if shift < -(n64 - 1) or shift > n64 - 1: return -1

    let output_bytes = q * 4
    if output_bytes != 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2
    var counts = InlineArray[Int32, 64](fill=0)
    for operation in range(q):
        let shift = input[shift_offset + operation]
        if shift == 0:
            for word in range(word_count): words[word] = 0
        elif shift > 0:
            let distance = Int(shift)
            let whole = distance // 64
            let part = distance % 64
            for destination in range(word_count):
                let source = destination + whole
                var shifted: UInt64 = if source < word_count then words[source] >> part else 0
                if part != 0 and source + 1 < word_count:
                    shifted |= words[source + 1] << (64 - part)
                words[destination] ^= shifted
        else:
            let distance = Int(-shift)
            let whole = distance // 64
            let part = distance % 64
            for reverse_index in range(word_count):
                let destination = word_count - 1 - reverse_index
                let source = destination - whole
                var shifted: UInt64 = 0
                if source >= 0: shifted = words[source] << part
                if part != 0 and source > 0: shifted |= words[source - 1] >> (64 - part)
                words[destination] ^= shifted
        words[word_count - 1] &= tail_mask
        var count: Int32 = 0
        for word in range(word_count): count += popcount64(words[word])
        counts[operation] = count
    for operation in range(q): store_i32_le(output, operation * 4, counts[operation])
    return Int64(output_bytes)
