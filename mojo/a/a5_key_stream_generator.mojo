from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct A5State:
    var r1: UInt32
    var r2: UInt32
    var r3: UInt32

    fn __init__(out self):
        self.r1 = 0
        self.r2 = 0
        self.r3 = 0

fn parity(x0: UInt32) -> UInt32:
    var x = x0
    x = x ^ (x >> 16)
    x = x ^ (x >> 8)
    x = x ^ (x >> 4)
    x = x ^ (x >> 2)
    x = x ^ (x >> 1)
    return x & 1

fn push(r: UInt32, width: UInt32, bit: UInt32) -> UInt32:
    return ((r << 1) | bit) & ((UInt32(1) << width) - 1)

fn fb1(s: A5State) -> UInt32:
    return parity(s.r1 & ((1 << 13) | (1 << 16) | (1 << 17) | (1 << 18)))

fn fb2(s: A5State) -> UInt32:
    return parity(s.r2 & ((1 << 20) | (1 << 21)))

fn fb3(s: A5State) -> UInt32:
    return parity(s.r3 & ((1 << 7) | (1 << 20) | (1 << 21) | (1 << 22)))

fn init_state(key: UInt64, frame: UInt32) -> A5State:
    var s = A5State()
    for step in range(64):
        let i = 63 - step
        let bit = UInt32((key >> i) & 1)
        s.r1 = push(s.r1, 19, bit ^ fb1(s))
        s.r2 = push(s.r2, 22, bit ^ fb2(s))
        s.r3 = push(s.r3, 23, bit ^ fb3(s))
    for step in range(22):
        let i = 21 - step
        let bit = (frame >> i) & 1
        s.r1 = push(s.r1, 19, bit ^ fb1(s))
        s.r2 = push(s.r2, 22, bit ^ fb2(s))
        s.r3 = push(s.r3, 23, bit ^ fb3(s))
    return s

fn tick(mut s: A5State) -> UInt32:
    let c1 = (s.r1 >> 8) & 1
    let c2 = (s.r2 >> 10) & 1
    let c3 = (s.r3 >> 10) & 1
    var majority: UInt32 = 0
    if c1 + c2 + c3 >= 2:
        majority = 1
    let output = (s.r1 >> 18 ^ s.r2 >> 21 ^ s.r3 >> 22) & 1
    if c1 == majority:
        s.r1 = push(s.r1, 19, fb1(s))
    if c2 == majority:
        s.r2 = push(s.r2, 22, fb2(s))
    if c3 == majority:
        s.r3 = push(s.r3, 23, fb3(s))
    return output

fn next_frame(frame0: UInt32) -> UInt32:
    var frame = frame0
    for step in range(22):
        let i = 21 - step
        let mask = UInt32(1) << i
        if (frame & mask) == 0:
            return frame | mask
        frame = frame & (~mask)
    return frame

@export("a5_key_stream_generator")
fn a5_key_stream_generator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3 or input[2] < 1 or input[2] > 4:
        return -1
    let count = input[2]
    let bytes = c_size_t(29 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes:
        return -2
    let key = UInt64(input[0])
    var frame = UInt32(UInt64(input[1]) & 0x3fffff)
    for block in range(count):
        var state = init_state(key, frame)
        for _ in range(100):
            _ = tick(state)
        for i in range(29):
            output[block * 29 + i] = 0
        for bit in range(228):
            let value = tick(state)
            let byte_index = block * 29 + bit / 8
            output[byte_index] = output[byte_index] | UInt8(value << (bit % 8))
        frame = next_frame(frame)
    return Int64(bytes)
