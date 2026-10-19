from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("brainfuck")
fn brainfuck(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 3074: return -2
    let pv = input[0]
    if pv < 0 or pv > 2048: return -2
    let plen = Int(pv); let ii = plen + 1
    if ii >= Int(length) or input[ii] < 0 or input[ii] > 1024: return -2
    let ilen = Int(input[ii])
    if length != c_size_t(plen + ilen + 2): return -2
    for i in range(plen):
        if input[1 + i] < 32 or input[1 + i] > 126: return -2
    for i in range(ilen):
        if input[ii + 1 + i] < 0 or input[ii + 1 + i] > 255: return -2
    var matching = List[Int](capacity=2048); var openings = List[Int](capacity=2048)
    for _ in range(2048): matching.append(-1); openings.append(0)
    var depth = 0
    for i in range(plen):
        if input[1 + i] == 91: openings[depth] = i; depth += 1
        elif input[1 + i] == 93:
            if depth == 0: return -2
            depth -= 1; let o = openings[depth]; matching[o] = i; matching[i] = o
    if depth != 0: return -2
    var tape = List[UInt8](capacity=257); for _ in range(257): tape.append(0)
    var result = List[UInt8](capacity=8192); var ptr = 128; var inpos = 0; var pc = 0; var steps = 0
    while pc < plen:
        steps += 1
        if steps > 100000: return -2
        let command = input[1 + pc]
        if command == 46:
            if len(result) == 8192: return -2
            result.append(tape[ptr])
        elif command == 44:
            tape[ptr] = UInt8(input[ii + 1 + inpos]) if inpos < ilen else UInt8(0)
            if inpos < ilen: inpos += 1
        elif command == 62: ptr += 1; if ptr >= 257: return -2
        elif command == 60: ptr -= 1; if ptr < 0: return -2
        elif command == 43: tape[ptr] = UInt8((Int(tape[ptr]) + 1) % 256)
        elif command == 45: tape[ptr] = UInt8((Int(tape[ptr]) + 255) % 256)
        elif command == 91 and tape[ptr] == 0: pc = matching[pc]
        elif command == 93 and tape[ptr] != 0: pc = matching[pc]
        pc += 1
    if len(result) > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(result))): return -2
    for i in range(len(result)): output[i] = result[i]
    return Int64(len(result))
