from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const SIDE = 33
const MAX_POINTS = 17
const GOLDEN: UInt64 = 0x9e3779b97f4a7c15
const MULTIPLIER: UInt64 = 0x2545f4914f6cdd1d
const MASK64: UInt128 = 0xffffffffffffffff

fn dla_mul_wrap(left: UInt64, right: UInt64) -> UInt64:
    UInt64((UInt128(left) * UInt128(right)) & MASK64)

fn dla_next(inout state: UInt64) -> UInt64:
    state ^= state >> 12
    state ^= state << 25
    state ^= state >> 27
    return dla_mul_wrap(state, MULTIPLIER)

fn dla_touches(inout occupied: InlineArray[UInt8, SIDE * SIDE], x: Int, y: Int) -> Bool:
    return occupied[y * SIDE + x - 1] != 0 or occupied[(y - 1) * SIDE + x] != 0 or occupied[y * SIDE + x + 1] != 0 or occupied[(y + 1) * SIDE + x] != 0

fn dla_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("brownian_tree_diffusion_limited_aggregation")
fn brownian_tree_diffusion_limited_aggregation(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let attempts_value = input[0]
    let seed_value = input[1]
    let steps_value = input[2]
    if attempts_value < 0 or attempts_value > 16 or seed_value < 1 or steps_value < 1 or steps_value > 512: return -1

    var occupied = InlineArray[UInt8, SIDE * SIDE](fill=0)
    var point_x = InlineArray[Int32, MAX_POINTS](fill=0)
    var point_y = InlineArray[Int32, MAX_POINTS](fill=0)
    point_x[0] = 16
    point_y[0] = 16
    var point_count = 1
    occupied[16 * SIDE + 16] = 1

    for attempt in range(Int(attempts_value)):
        var state = UInt64(seed_value) ^ dla_mul_wrap(GOLDEN, UInt64(attempt + 1))
        if state == 0: state = MULTIPLIER
        let side_draw = dla_next(state)
        let position_draw = dla_next(state)
        let launch_side = Int(side_draw % UInt64(4))
        let position = 1 + Int(position_draw % UInt64(31))
        var x = position
        var y = position
        if launch_side == 0: y = 1
        elif launch_side == 1: x = 31
        elif launch_side == 2: y = 31
        else: x = 1

        var at = y * SIDE + x
        if occupied[at] != 0: continue
        if dla_touches(occupied, x, y):
            occupied[at] = 1
            point_x[point_count] = Int32(x)
            point_y[point_count] = Int32(y)
            point_count += 1
            continue
        for _ in range(Int(steps_value)):
            let direction = Int(dla_next(state) % UInt64(4))
            if direction == 0: x -= 1
            elif direction == 1: y -= 1
            elif direction == 2: x += 1
            else: y += 1
            if x == 0 or x == 32 or y == 0 or y == 32: break
            at = y * SIDE + x
            if dla_touches(occupied, x, y):
                occupied[at] = 1
                point_x[point_count] = Int32(x)
                point_y[point_count] = Int32(y)
                point_count += 1
                break

    let required = (1 + 2 * point_count) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    dla_store_i64(output, 0, Int64(point_count))
    for point in range(point_count):
        dla_store_i64(output, (1 + 2 * point) * 8, Int64(point_x[point]))
        dla_store_i64(output, (2 + 2 * point) * 8, Int64(point_y[point]))
    return Int64(required)
