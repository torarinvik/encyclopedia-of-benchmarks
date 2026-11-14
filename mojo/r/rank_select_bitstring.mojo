from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("rank_select_bitstring")
fn rank_select_bitstring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 35: return -1
    let bit_count = input[0]
    let packed = input[1]
    let query_count = input[2]
    if bit_count < 1 or bit_count > 63 or packed < 0 or query_count < 0 or query_count > 16 or length != c_size_t(3 + 2 * query_count): return -1
    let n = Int(bit_count)
    let bits = UInt64(packed)
    if (bits >> n) != 0: return -1
    let blocks = (n + 7) // 8
    var prefix = InlineArray[Int64, 9](fill=0)
    for block in range(blocks):
        prefix[block + 1] = prefix[block]
        for pos in range(8 * block, min(8 * block + 8, n)):
            prefix[block + 1] += Int64((bits >> pos) & 1)
    var answers = InlineArray[Int64, 16](fill=0)
    for query in range(Int(query_count)):
        let op = input[3 + 2 * query]
        let index_value = input[4 + 2 * query]
        if (op != 0 and op != 1) or index_value < 1: return -1
        if (op == 0 and index_value > bit_count) or (op == 1 and index_value > 64): return -1
        let index = Int(index_value)
        if op == 0:
            let full = index // 8
            var result = prefix[full]
            for pos in range(8 * full, index): result += Int64((bits >> pos) & 1)
            answers[query] = result
        else:
            var block = 0
            while block < blocks and prefix[block + 1] < index_value: block += 1
            answers[query] = -1
            if block < blocks:
                var remaining = index_value - prefix[block]
                for pos in range(8 * block, min(8 * block + 8, n)):
                    if ((bits >> pos) & 1) != 0:
                        remaining -= 1
                        if remaining == 0:
                            answers[query] = Int64(pos + 1)
                            break
    let bytes = 8 * Int(query_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for query in range(Int(query_count)):
        var encoded = bitcast[UInt64](answers[query])
        for byte in range(8):
            output[8 * query + byte] = UInt8(encoded & 255)
            encoded >>= 8
    return Int64(bytes)
