# Independent IDEA feedback-mode implementation; see the package NOTICE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cfb_mul(a: Int, b: Int) -> Int:
    let left = 65536 if a == 0 else a
    let right = 65536 if b == 0 else b
    let result = (left * right) % 65537
    return 0 if result == 65536 else result

fn cfb_block(keys: InlineArray[Int, 52], feedback: InlineArray[Int, 8]) -> InlineArray[Int, 8]:
    var x1 = feedback[0] * 256 + feedback[1]
    var x2 = feedback[2] * 256 + feedback[3]
    var x3 = feedback[4] * 256 + feedback[5]
    var x4 = feedback[6] * 256 + feedback[7]
    for round in range(8):
        let k = round * 6
        let a = cfb_mul(x1, keys[k])
        let b = (x2 + keys[k + 1]) & 65535
        let c = (x3 + keys[k + 2]) & 65535
        let d = cfb_mul(x4, keys[k + 3])
        let p = cfb_mul(a ^ c, keys[k + 4])
        let q = cfb_mul(((b ^ d) + p) & 65535, keys[k + 5])
        let r = (p + q) & 65535
        x1 = a ^ q
        x2 = c ^ q
        x3 = b ^ r
        x4 = d ^ r
    let words = InlineArray[Int, 4](cfb_mul(x1, keys[48]), (x3 + keys[49]) & 65535,
                                   (x2 + keys[50]) & 65535, cfb_mul(x4, keys[51]))
    var result = InlineArray[Int, 8](fill=0)
    for i in range(4):
        result[2 * i] = words[i] >> 8
        result[2 * i + 1] = words[i] & 255
    return result

@export("idea_cfb64")
fn idea_cfb64(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 27 or length > 51: return -1
    let mode = input[0]
    let raw_count = input[1]
    if mode < 0 or mode > 1 or raw_count < 1 or raw_count > 24: return -1
    let count = Int(raw_count)
    if Int(length) != 26 + count: return -1
    for i in range(2, Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    var state = InlineArray[Int, 8](fill=0)
    var feedback = InlineArray[Int, 8](fill=0)
    for i in range(8):
        state[i] = Int(input[2 + 2 * i]) * 256 + Int(input[3 + 2 * i])
        feedback[i] = Int(input[18 + i])
    var keys = InlineArray[Int, 52](fill=0)
    var written = 0
    while written < 52:
        for i in range(min(8, 52 - written)): keys[written + i] = state[i]
        var rotated = InlineArray[Int, 8](fill=0)
        for i in range(8):
            rotated[i] = ((state[(i + 1) % 8] << 9) | (state[(i + 2) % 8] >> 7)) & 65535
        state = rotated
        written += 8
    var staged = InlineArray[UInt8, 24](fill=0)
    var position = 0
    while position < count:
        let stream = cfb_block(keys, feedback)
        let take = min(8, count - position)
        for i in range(take):
            let incoming = Int(input[26 + position + i])
            let transformed = incoming ^ stream[i]
            staged[position + i] = UInt8(transformed)
            feedback[i] = transformed if mode == 0 else incoming
        position += take
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count): output[i] = staged[i]
    return Int64(count)
