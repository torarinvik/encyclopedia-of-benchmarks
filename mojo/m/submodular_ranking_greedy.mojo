from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn submodular_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("submodular_ranking_greedy")
fn submodular_ranking_greedy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 5 or mv < 1 or mv > 4: return -1
    let n = Int(nv)
    let m = Int(mv)
    let size = 1 << n
    if length != c_size_t(2 + m * size): return -1
    var tables = InlineArray[Int64, 128](fill=0)
    for f in range(m):
        let base = 32 * f
        for mask in range(size):
            let value = input[2 + f * size + mask]
            if value < 0 or value > 8: return -1
            tables[base + mask] = value
        if tables[base] != 0 or tables[base + size - 1] != 8: return -1
        for a in range(size):
            for b in range(size):
                if (a & b) == a:
                    for e in range(n):
                        let bit = 1 << e
                        if (b & bit) == 0:
                            let gain_a = tables[base + (a | bit)] - tables[base + a]
                            let gain_b = tables[base + (b | bit)] - tables[base + b]
                            if gain_a < gain_b or gain_b < 0: return -1
    let bytes = 8 * (1 + n + m)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var order = InlineArray[Int64, 5](fill=0)
    var times = InlineArray[Int64, 4](fill=0)
    var total: Int64 = 0
    var mask = 0
    for t in range(1, n + 1):
        var winner = 0
        var best_num: Int64 = -1
        var best_den: Int64 = 1
        for e in range(n):
            let bit = 1 << e
            if (mask & bit) == 0:
                var num: Int64 = 0
                var den: Int64 = 1
                for f in range(m):
                    let base = 32 * f
                    let current = tables[base + mask]
                    if current != 8:
                        let d = 8 - current
                        let gain = tables[base + (mask | bit)] - current
                        num = num * d + gain * den
                        den *= d
                if best_num < 0 or num * best_den > best_num * den:
                    winner = e
                    best_num = num
                    best_den = den
        mask |= 1 << winner
        order[t - 1] = Int64(winner)
        for f in range(m):
            if times[f] == 0 and tables[32 * f + mask] == 8:
                times[f] = Int64(t)
                total += Int64(t)
    submodular_store(output, 0, total)
    for i in range(n): submodular_store(output, 1 + i, order[i])
    for i in range(m): submodular_store(output, 1 + n + i, times[i])
    return Int64(bytes)
