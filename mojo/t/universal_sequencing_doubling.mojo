from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("universal_sequencing_doubling")
fn universal_sequencing_doubling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 25: return -1
    let count = input[0]
    if count < 1 or count > 12 or length != c_size_t(1 + 2 * count): return -1
    let n = Int(count)
    var processing = InlineArray[Int64, 12](fill=0)
    var weights = InlineArray[Int, 12](fill=0)
    var total = 0
    for job in range(n):
        let p = input[1 + 2 * job]; let w = input[2 + 2 * job]
        if p < 1 or p > 255 or w < 1 or w > 32: return -1
        processing[job] = p
        weights[job] = Int(w)
        total += Int(w)
    if total > 32 or (total & (total - 1)) != 0: return -1
    var level_sets = InlineArray[Int, 6](fill=0)
    var levels = 0
    var bound = 1
    while bound <= total:
        var best = InlineArray[Int64, 33](fill=0)
        var masks = InlineArray[Int, 33](fill=0)
        var reachable = InlineArray[Bool, 33](fill=False)
        reachable[0] = True
        for job in range(n):
            var used = bound
            while used >= weights[job]:
                let prior = used - weights[job]
                if reachable[prior]:
                    let candidate = best[prior] + processing[job]
                    let mask = masks[prior] | (1 << job)
                    if not reachable[used] or candidate > best[used] or (candidate == best[used] and mask < masks[used]):
                        reachable[used] = True
                        best[used] = candidate
                        masks[used] = mask
                used -= 1
        var maximum: Int64 = -1
        var selected = 0
        for used in range(bound + 1):
            if reachable[used] and (best[used] > maximum or (best[used] == maximum and masks[used] < selected)):
                maximum = best[used]
                selected = masks[used]
        level_sets[levels] = selected
        levels += 1
        bound *= 2
    var ranks = InlineArray[Int, 12](fill=-1)
    for job in range(n):
        for level in range(levels):
            if (level_sets[level] & (1 << job)) != 0:
                ranks[job] = level
                break
        if ranks[job] < 0: return -1
    var words = InlineArray[Int64, 13](fill=0)
    words[0] = Int64(n)
    var at = 1
    var level = levels
    while level > 0:
        level -= 1
        for job in range(n):
            if ranks[job] == level:
                words[at] = Int64(job)
                at += 1
    let bytes = 8 * at
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(at):
        var bits = UInt64(words[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
