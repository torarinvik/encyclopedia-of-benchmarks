from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_OPERATIONS = 32
const MAX_INPUT_LENGTH = 99
const BREAKPOINT_INFINITY = Int64(1_000_000_000_000_000)
const CHECKSUM_OFFSET = Int64(2_000_001)

fn aolc_intersection(slopes: InlineArray[Int64, 32], intercepts: InlineArray[Int64, 32],
                     left: Int, right: Int) -> Int64:
    let numerator = intercepts[left] - intercepts[right]
    let denominator = slopes[right] - slopes[left]
    var quotient = numerator / denominator
    if numerator % denominator != 0 and numerator < 0: quotient -= 1
    return quotient

fn aolc_erase(mut slopes: InlineArray[Int64, 32], mut intercepts: InlineArray[Int64, 32],
              mut breakpoints: InlineArray[Int64, 32], mut count: Int, position: Int):
    for i in range(position, count - 1):
        slopes[i] = slopes[i + 1]
        intercepts[i] = intercepts[i + 1]
        breakpoints[i] = breakpoints[i + 1]
    count -= 1

fn aolc_insert(mut slopes: InlineArray[Int64, 32], mut intercepts: InlineArray[Int64, 32],
               mut breakpoints: InlineArray[Int64, 32], mut count: Int,
               slope: Int64, intercept: Int64):
    var position = 0
    while position < count and slopes[position] < slope: position += 1
    if position < count and slopes[position] == slope:
        if intercepts[position] >= intercept: return
        aolc_erase(slopes, intercepts, breakpoints, count, position)
    for i in range(position, count):
        let source = count - (i - position) - 1
        slopes[source + 1] = slopes[source]
        intercepts[source + 1] = intercepts[source]
        breakpoints[source + 1] = breakpoints[source]
    slopes[position] = slope
    intercepts[position] = intercept
    breakpoints[position] = BREAKPOINT_INFINITY
    count += 1
    var active = position
    while active + 1 < count:
        let breakpoint = aolc_intersection(slopes, intercepts, active, active + 1)
        breakpoints[active] = breakpoint
        if breakpoint >= breakpoints[active + 1]:
            aolc_erase(slopes, intercepts, breakpoints, count, active + 1)
        else:
            break
    if active + 1 == count: breakpoints[active] = BREAKPOINT_INFINITY
    if active > 0:
        let breakpoint = aolc_intersection(slopes, intercepts, active - 1, active)
        breakpoints[active - 1] = breakpoint
        var cursor = 0
        if breakpoint >= breakpoints[active]:
            aolc_erase(slopes, intercepts, breakpoints, count, active)
            active -= 1
            if active + 1 < count:
                breakpoints[active] = aolc_intersection(slopes, intercepts, active, active + 1)
            else:
                breakpoints[active] = BREAKPOINT_INFINITY
            cursor = active
        else:
            cursor = active - 1
        while cursor > 0 and breakpoints[cursor - 1] >= breakpoints[cursor]:
            aolc_erase(slopes, intercepts, breakpoints, count, cursor)
            cursor -= 1
            active -= 1
            if cursor + 1 < count:
                breakpoints[cursor] = aolc_intersection(slopes, intercepts, cursor, cursor + 1)
            else:
                breakpoints[cursor] = BREAKPOINT_INFINITY

fn aolc_query(slopes: InlineArray[Int64, 32], intercepts: InlineArray[Int64, 32],
              breakpoints: InlineArray[Int64, 32], count: Int, x: Int64, objective: Int64) -> Int64:
    var low = 0
    var high = count
    while low < high:
        let middle = low + (high - low) / 2
        if breakpoints[middle] < x: low = middle + 1
        else: high = middle
    return (slopes[low] * x + intercepts[low]) * objective

@export("arbitrary_order_line_container")
fn arbitrary_order_line_container(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let mode = input[0]
    let operation_value = input[1]
    if (mode != 0 and mode != 1) or operation_value < 0 or operation_value > MAX_OPERATIONS: return -1
    let operations = Int(operation_value)
    if length != c_size_t(2 + 3 * operations): return -1
    var seen_line = False
    for operation in range(operations):
        let p = 2 + 3 * operation
        let opcode = input[p]
        let first = input[p + 1]
        let second = input[p + 2]
        if opcode == 0:
            if first < -1000 or first > 1000 or second < -1000 or second > 1000: return -1
            seen_line = True
        elif opcode == 1:
            if not seen_line or first < -1000 or first > 1000 or second != 0: return -1
        else:
            return -1
    let objective = Int64(1) if mode == 1 else Int64(-1)
    var slopes = InlineArray[Int64, 32](fill=0)
    var intercepts = InlineArray[Int64, 32](fill=0)
    var breakpoints = InlineArray[Int64, 32](fill=0)
    var line_count = 0
    var query_index = 0
    var checksum: Int64 = 0
    for operation in range(operations):
        let p = 2 + 3 * operation
        if input[p] == 0:
            aolc_insert(slopes, intercepts, breakpoints, line_count,
                        input[p + 1] * objective, input[p + 2] * objective)
        else:
            let optimum = aolc_query(slopes, intercepts, breakpoints, line_count,
                                     input[p + 1], objective)
            checksum += Int64(query_index + 1) * (optimum + CHECKSUM_OFFSET)
            query_index += 1
    return checksum
