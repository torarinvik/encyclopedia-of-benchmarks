from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("two_interval_precedence_chain")
fn two_interval_precedence_chain(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 65: return -1
    let count = input[0]
    if count < 1 or count > 16 or length != c_size_t(1 + 4 * count): return -1
    let n = Int(count)
    var endpoints = InlineArray[Int64, 64](fill=0)
    var order = InlineArray[Int, 16](fill=0)
    for i in range(n):
        for j in range(4):
            let value = input[1 + 4 * i + j]
            if value < 0 or value > 63: return -1
            endpoints[4 * i + j] = value
        if endpoints[4 * i] >= endpoints[4 * i + 1] or endpoints[4 * i + 1] >= endpoints[4 * i + 2] or endpoints[4 * i + 2] >= endpoints[4 * i + 3]: return -1
        order[i] = i
    for i in range(1, n):
        let item = order[i]
        var at = i
        while at > 0:
            let prior = order[at - 1]
            var comparison = 0
            for j in range(4):
                if comparison == 0:
                    if endpoints[4 * item + j] < endpoints[4 * prior + j]: comparison = -1
                    elif endpoints[4 * item + j] > endpoints[4 * prior + j]: comparison = 1
            if comparison == 0:
                if item < prior: comparison = -1
                else: comparison = 1
            if comparison >= 0: break
            order[at] = prior
            at -= 1
        order[at] = item
    var paths = InlineArray[Int, 256](fill=0)
    var lengths = InlineArray[Int, 16](fill=0)
    for i in range(n):
        paths[16 * i] = order[i]
        lengths[i] = 1
        for j in range(i):
            let a = order[j]; let b = order[i]
            if endpoints[4 * a + 1] < endpoints[4 * b] and endpoints[4 * a + 3] < endpoints[4 * b + 2]:
                let candidate_length = lengths[j] + 1
                var take = candidate_length > lengths[i]
                if candidate_length == lengths[i]:
                    var comparison = 0
                    for q in range(candidate_length):
                        let value = if q == lengths[j]: b else: paths[16 * j + q]
                        if comparison == 0:
                            if value < paths[16 * i + q]: comparison = -1
                            elif value > paths[16 * i + q]: comparison = 1
                    take = comparison < 0
                if take:
                    for q in range(lengths[j]): paths[16 * i + q] = paths[16 * j + q]
                    paths[16 * i + lengths[j]] = b
                    lengths[i] = candidate_length
    var best = 0
    for i in range(1, n):
        var take = lengths[i] > lengths[best]
        if lengths[i] == lengths[best]:
            var comparison = 0
            for q in range(lengths[i]):
                if comparison == 0:
                    if paths[16 * i + q] < paths[16 * best + q]: comparison = -1
                    elif paths[16 * i + q] > paths[16 * best + q]: comparison = 1
            take = comparison < 0
        if take: best = i
    let bytes = 8 * (1 + lengths[best])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for slot in range(1 + lengths[best]):
        let value = if slot == 0: lengths[best] else: paths[16 * best + slot - 1]
        var bits = UInt64(value)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
