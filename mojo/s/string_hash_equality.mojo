from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin

comptime RC: Array[UInt64,24] = [
    0x1, 0x8082, 0x800000000000808a, 0x8000000080008000,
    0x808b, 0x80000001, 0x8000000080008081, 0x8000000000008009,
    0x8a, 0x88, 0x80008009, 0x8000000a,
    0x8000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x800a, 0x800000008000000a,
    0x8000000080008081, 0x8000000000008080, 0x80000001, 0x8000000080008008
]
comptime ROT: Array[Int,25] = [
    0, 1, 62, 28,
    27, 36, 44, 6,
    55, 20, 3, 10,
    43, 25, 39, 41,
    45, 15, 21, 8,
    18, 2, 61, 56,
    14
]


def rotate_left(value: UInt64, amount: Int) -> UInt64:
    if amount == 0:
        return value
    return (value << UInt64(amount)) | (value >> UInt64(64 - amount))


def keccak(input: Pointer[Int64, ImmUntrackedOrigin], start: Int, length: Int) -> Array[UInt64, 4]:
    var state_storage = Array[UInt64, 25](fill=0)
    var state = state_storage.unsafe_ptr()
    for index in range(length):
        state[unsafe_offset=index // 8] |= UInt64(input[unsafe_offset=start + index]) << UInt64(8 * (index % 8))
    state[unsafe_offset=length // 8] ^= UInt64(1) << UInt64(8 * (length % 8))
    state[unsafe_offset=16] ^= UInt64(0x8000000000000000)

    var rotations_storage = materialize[ROT]()
    var constants_storage = materialize[RC]()
    var rotations = rotations_storage.unsafe_ptr()
    var constants = constants_storage.unsafe_ptr()
    var columns_storage = Array[UInt64, 5](fill=0)
    var deltas_storage = Array[UInt64, 5](fill=0)
    var moved_storage = Array[UInt64, 25](fill=0)
    var columns = columns_storage.unsafe_ptr()
    var deltas = deltas_storage.unsafe_ptr()
    var moved = moved_storage.unsafe_ptr()
    for round in range(24):
        for x in range(5):
            columns[unsafe_offset=x] = state[unsafe_offset=x] ^ state[unsafe_offset=x + 5] ^ state[unsafe_offset=x + 10] ^ state[unsafe_offset=x + 15] ^ state[unsafe_offset=x + 20]
        for x in range(5):
            deltas[unsafe_offset=x] = columns[unsafe_offset=(x + 4) % 5] ^ rotate_left(columns[unsafe_offset=(x + 1) % 5], 1)
        for y in range(5):
            for x in range(5):
                var source = x + 5 * y
                var destination = y + 5 * ((2 * x + 3 * y) % 5)
                moved[unsafe_offset=destination] = rotate_left(state[unsafe_offset=source] ^ deltas[unsafe_offset=x], rotations[unsafe_offset=source])
        for y in range(5):
            for x in range(5):
                state[unsafe_offset=x + 5 * y] = moved[unsafe_offset=x + 5 * y] ^ ((~moved[unsafe_offset=(x + 1) % 5 + 5 * y]) & moved[unsafe_offset=(x + 2) % 5 + 5 * y])
        state[unsafe_offset=0] ^= constants[unsafe_offset=round]
    return [state[unsafe_offset=0], state[unsafe_offset=1], state[unsafe_offset=2], state[unsafe_offset=3]]


@export("string_hash_equality")
def string_hash_equality(input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t) abi("C") -> Int64:
    if input == None or length < 2 or length > 131:
        return -1
    var values = input.value()
    var first_length = Int(values[unsafe_offset=0])
    var second_length = Int(values[unsafe_offset=1])
    if first_length < 0 or first_length > 64 or second_length < 0 or second_length > 64:
        return -1
    if Int(length) != 2 + first_length + second_length:
        return -1
    for index in range(2, Int(length)):
        if values[unsafe_offset=index] < 0 or values[unsafe_offset=index] > 255:
            return -1
    var first_storage = keccak(values, 2, first_length)
    var second_storage = keccak(values, 2 + first_length, second_length)
    var first = first_storage.unsafe_ptr()
    var second = second_storage.unsafe_ptr()
    for lane in range(4):
        if first[unsafe_offset=lane] != second[unsafe_offset=lane]:
            return 0
    return 1
