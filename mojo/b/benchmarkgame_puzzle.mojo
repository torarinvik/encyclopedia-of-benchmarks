# Independent implementation of the documented bounded puzzle workload.
from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn puzzle_draw(inout low: Int, inout high: Int) -> Int:
    # Only the low 48 state bits can influence the 32 bits read after >> 16.
    # Two 24-bit limbs keep the modular multiply within signed Int range.
    let product = low * 1103515245 + 12345
    high = (high * 1103515245 + (product >> 24)) & 0xffffff
    low = product & 0xffffff
    let shifted = (high << 8) | (low >> 16)
    return shifted % 32767 + 1

@export("benchmarkgame_puzzle")
fn benchmarkgame_puzzle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let size_raw = input[0]
    let rounds_raw = input[1]
    let scans_raw = input[2]
    if size_raw < 1 or size_raw > 100000 or rounds_raw < 1 or rounds_raw > 8: return -1
    if scans_raw < 1 or scans_raw > 64: return -1
    let size = Int(size_raw)
    let rounds = Int(rounds_raw)
    let scans = Int(scans_raw)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(rounds * 4): return -2
    var low = 1
    var high = 0
    var results = InlineArray[Int, 8](fill=0)
    for round in range(rounds):
        var items = List[Int](capacity=size + 1)
        for i in range(size + 1): items.append(i)
        items[0] = 1 + (size * puzzle_draw(low, high)) // 32768
        var i = size
        while i > 0:
            let chosen = ((i + 1) * puzzle_draw(low, high)) // 32768
            let temporary = items[i]
            items[i] = items[chosen]
            items[chosen] = temporary
            i -= 1
        var duplicate = 0
        for repeat in range(scans):
            var value = size + 1
            for index in range(size + 1): value = value ^ (index + 1) ^ items[index]
            duplicate = value
        results[round] = duplicate
    for round in range(rounds):
        for byte in range(4): output[round * 4 + byte] = UInt8((results[round] >> (8 * byte)) & 255)
    return Int64(rounds * 4)
