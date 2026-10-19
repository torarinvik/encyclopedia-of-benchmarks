from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("arithmetic_coding")
fn arithmetic_coding(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let count = input[0]
    if count < 1 or count > 12 or length != c_size_t(count + 1):
        return -1
    var frequency = List[Int64](length=256, fill=0)
    var cumulative = List[Int64](length=257, fill=0)
    for i in range(Int(count)):
        let symbol = input[i + 1]
        if symbol < 0 or symbol >= 256: return -1
        frequency[Int(symbol)] += 1
    for symbol in range(256):
        cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol]
    var low: Int64 = 0
    var high: Int64 = 1
    for i in range(Int(count)):
        let symbol = Int(input[i + 1])
        let interval = high - low
        let base = low * count
        high = base + interval * cumulative[symbol + 1]
        low = base + interval * cumulative[symbol]
    return low
