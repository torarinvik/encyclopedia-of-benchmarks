from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime SWAD_MODULUS = Int64(97)
comptime SWAD_IDENTITY = Int64(1 + 97 * 97 * 97)

fn swad_pack(a: Int64, b: Int64, c: Int64, d: Int64) -> Int64:
    a + SWAD_MODULUS * b + SWAD_MODULUS * SWAD_MODULUS * c + SWAD_MODULUS * SWAD_MODULUS * SWAD_MODULUS * d

fn swad_multiply(x: Int64, y: Int64) -> Int64:
    let xa = x % SWAD_MODULUS
    let xb = (x // SWAD_MODULUS) % SWAD_MODULUS
    let xc = (x // (SWAD_MODULUS * SWAD_MODULUS)) % SWAD_MODULUS
    let xd = (x // (SWAD_MODULUS * SWAD_MODULUS * SWAD_MODULUS)) % SWAD_MODULUS
    let ya = y % SWAD_MODULUS
    let yb = (y // SWAD_MODULUS) % SWAD_MODULUS
    let yc = (y // (SWAD_MODULUS * SWAD_MODULUS)) % SWAD_MODULUS
    let yd = (y // (SWAD_MODULUS * SWAD_MODULUS * SWAD_MODULUS)) % SWAD_MODULUS
    let a = (xa * ya + xb * yc) % SWAD_MODULUS
    let b = (xa * yb + xb * yd) % SWAD_MODULUS
    let c = (xc * ya + xd * yc) % SWAD_MODULUS
    let d = (xc * yb + xd * yd) % SWAD_MODULUS
    swad_pack(a, b, c, d)

fn swad_push_front(inout items: InlineArray[Int64, 32], inout aggregates: InlineArray[Int64, 32], inout count: Int, value: Int64):
    items[count] = value
    aggregates[count] = if count == 0: value else: swad_multiply(value, aggregates[count - 1])
    count += 1

fn swad_push_back(inout items: InlineArray[Int64, 32], inout aggregates: InlineArray[Int64, 32], inout count: Int, value: Int64):
    items[count] = value
    aggregates[count] = if count == 0: value else: swad_multiply(aggregates[count - 1], value)
    count += 1

fn swad_rebalance(inout front: InlineArray[Int64, 32], inout front_aggregate: InlineArray[Int64, 32], inout front_count: Int,
                  inout back: InlineArray[Int64, 32], inout back_aggregate: InlineArray[Int64, 32], inout back_count: Int,
                  inout temporary: InlineArray[Int64, 32]):
    let front_was_empty = front_count == 0
    let total = front_count + back_count
    for i in range(front_count):
        temporary[i] = front[front_count - 1 - i]
    for i in range(back_count):
        temporary[front_count + i] = back[i]
    let front_size = total // 2 + (if front_was_empty: total % 2 else: 0)
    front_count = 0
    back_count = 0
    for i in range(front_size):
        swad_push_front(front, front_aggregate, front_count, temporary[front_size - 1 - i])
    for i in range(front_size, total):
        swad_push_back(back, back_aggregate, back_count, temporary[i])

@export("slide_window_aggregation_deque")
fn slide_window_aggregation_deque(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 162: return -1
    if values[0] < 0 or values[0] > 32: return -1
    let operation_count = Int(values[0])
    var front = InlineArray[Int64, 32]()
    var front_aggregate = InlineArray[Int64, 32]()
    var back = InlineArray[Int64, 32]()
    var back_aggregate = InlineArray[Int64, 32]()
    var temporary = InlineArray[Int64, 32]()
    var front_count = 0
    var back_count = 0
    var position = 1
    var query_ordinal: Int64 = 0
    var checksum: Int64 = 0

    for _ in range(operation_count):
        if c_size_t(position) >= length: return -1
        let opcode = values[position]
        position += 1
        if opcode == 0 or opcode == 1:
            if c_size_t(position + 4) > length: return -1
            let a = values[position]
            let b = values[position + 1]
            let c = values[position + 2]
            let d = values[position + 3]
            if a < 0 or a >= SWAD_MODULUS or b < 0 or b >= SWAD_MODULUS or c < 0 or c >= SWAD_MODULUS or d < 0 or d >= SWAD_MODULUS: return -1
            let value = swad_pack(a, b, c, d)
            position += 4
            if opcode == 0: swad_push_front(front, front_aggregate, front_count, value)
            else: swad_push_back(back, back_aggregate, back_count, value)
        elif opcode == 2 or opcode == 3:
            if front_count + back_count == 0: return -1
            if opcode == 2:
                if front_count == 0:
                    swad_rebalance(front, front_aggregate, front_count, back, back_aggregate, back_count, temporary)
                front_count -= 1
            else:
                if back_count == 0:
                    swad_rebalance(front, front_aggregate, front_count, back, back_aggregate, back_count, temporary)
                back_count -= 1
        elif opcode == 4:
            let left = if front_count == 0: SWAD_IDENTITY else: front_aggregate[front_count - 1]
            let right = if back_count == 0: SWAD_IDENTITY else: back_aggregate[back_count - 1]
            query_ordinal += 1
            checksum += query_ordinal * (swad_multiply(left, right) + 1)
        else:
            return -1
    if c_size_t(position) != length: return -1
    return checksum
