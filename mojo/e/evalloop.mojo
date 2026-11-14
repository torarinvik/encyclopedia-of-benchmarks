from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("evalloop")
fn evalloop(passes: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if passes < 0 or passes > 1000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var commands = List[Int](length=2048, fill=0)
    for i in range(2047): commands[i] = i % 31 + 1
    var total: Int64 = 0
    for _ in range(Int(passes)):
        var pc = 0
        while commands[pc] != 0:
            let opcode = commands[pc]
            if opcode >= 1 and opcode <= 31: total += Int64(opcode)
            pc += 1
    var reverse = List[UInt8](length=10, fill=0)
    var digits = 0
    var remaining = total
    while True:
        reverse[digits] = UInt8(48 + remaining % 10)
        digits += 1
        remaining //= 10
        if remaining == 0: break
    let used = 6 + digits
    if capacity < c_size_t(used): return -2
    output[0] = 83
    output[1] = 117
    output[2] = 109
    output[3] = 58
    output[4] = 32
    for i in range(digits): output[5 + i] = reverse[digits - 1 - i]
    output[5 + digits] = 10
    return Int64(used)
