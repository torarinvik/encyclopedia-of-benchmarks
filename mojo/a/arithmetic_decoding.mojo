from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("arithmetic_decoding")
fn arithmetic_decoding(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5:
        return -1
    let count = input[0]
    let alphabet_size = input[1]
    if count < 1 or count > 12 or alphabet_size < 1 or alphabet_size > count or length != c_size_t(3 + 2 * alphabet_size):
        return -1
    var denominator: Int64 = 1
    for i in range(Int(count)):
        denominator *= count
    let code = input[2]
    if code < 0 or code >= denominator:
        return -1
    var symbols = List[Int64](length=12, fill=0)
    var cumulative = List[Int64](length=13, fill=0)
    var total: Int64 = 0
    for i in range(Int(alphabet_size)):
        let symbol = input[3 + 2 * i]
        let frequency = input[4 + 2 * i]
        if symbol < 0 or symbol > 255 or frequency < 1 or frequency > count or (i > 0 and symbol <= symbols[i - 1]):
            return -1
        symbols[i] = symbol
        total += frequency
        cumulative[i + 1] = total
    if total != count:
        return -1
    var decoded = List[UInt8](length=12, fill=0)
    var low: Int64 = 0
    var high: Int64 = 1
    var scale = denominator / count
    for step in range(Int(count)):
        let interval = high - low
        let base = low * count
        var found = False
        for i in range(Int(alphabet_size)):
            let symbol_low = base + interval * cumulative[i]
            let symbol_high = base + interval * cumulative[i + 1]
            if code >= symbol_low * scale and code < symbol_high * scale:
                decoded[step] = UInt8(symbols[i])
                low = symbol_low
                high = symbol_high
                found = True
                break
        if not found:
            return -1
        if step + 1 < Int(count):
            scale /= count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count):
        return -2
    for i in range(Int(count)):
        output[i] = decoded[i]
    return count
