from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ceil_log2(value: Int) -> Int:
    var exponent = 0
    var power = 1
    while power < value:
        power *= 2
        exponent += 1
    return exponent

@export("radio_network_bgi_broadcast")
fn radio_network_bgi_broadcast(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 203: return -1
    let nv = input[0]; let sourcev = input[1]; let deltav = input[2]
    if nv < 2 or nv > 8 or sourcev < 0 or sourcev >= nv or deltav < 2 or deltav > 8: return -1
    let n = Int(nv); let source = Int(sourcev); let delta = Int(deltav)
    let k = 2 * ceil_log2(delta); let t = ceil_log2(2 * n)
    let tape_at = 3 + n; let tape_count = n * t * k
    if length != c_size_t(tape_at + tape_count): return -1
    let full = (Int64(1) << n) - 1
    var adjacency = InlineArray[Int64, 8](fill=0)
    var calls = InlineArray[Int, 8](fill=0)
    var first_slot = InlineArray[Int64, 8](fill=-1)
    var informed = InlineArray[Bool, 8](fill=False)
    var active = InlineArray[Bool, 8](fill=False)
    var newly = InlineArray[Bool, 8](fill=False)
    for v in range(n):
        let raw = input[3 + v]
        if raw < 0 or (raw & ~full) != 0 or (raw & (Int64(1) << v)) != 0: return -1
        adjacency[v] = raw
        var degree = 0
        for u in range(n):
            if (raw & (Int64(1) << u)) != 0: degree += 1
        if degree > delta: return -1
    for u in range(n):
        for v in range(n):
            if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1): return -1
    for i in range(tape_count):
        let bit = input[tape_at + i]
        if bit != 0 and bit != 1: return -1
    let output_bytes = 8 * (n + 3)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    informed[source] = True
    first_slot[source] = 0
    var transmissions: Int64 = 0
    var phases: Int64 = 0
    for phase in range(n * t):
        var starter_count = 0
        for v in range(n):
            active[v] = informed[v] and calls[v] < t
            newly[v] = False
            if active[v]: starter_count += 1
        if starter_count == 0: break
        for slot in range(k):
            for sender in range(n):
                if active[sender]: transmissions += 1
            for receiver in range(n):
                if informed[receiver] or newly[receiver]: continue
                var sender_count = 0
                for sender in range(n):
                    if active[sender] and (adjacency[sender] & (Int64(1) << receiver)) != 0: sender_count += 1
                if sender_count == 1:
                    newly[receiver] = True
                    first_slot[receiver] = Int64(phase * k + slot)
            for sender in range(n):
                if active[sender]:
                    let at = tape_at + (sender * t + calls[sender]) * k + slot
                    if slot + 1 == k or input[at] == 0: active[sender] = False
        for v in range(n):
            if informed[v] and calls[v] < t: calls[v] += 1
            if newly[v]:
                informed[v] = True
        phases = Int64(phase + 1)

    for field in range(n + 3):
        var value: Int64 = 0
        if field == 0: value = nv
        elif field == 1: value = phases
        elif field == 2: value = transmissions
        else: value = first_slot[field - 3]
        var bits = UInt64(value)
        for byte in range(8):
            output[8 * field + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(output_bytes)
