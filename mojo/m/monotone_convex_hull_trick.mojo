from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MCHT_MAX_LINES = 32
comptime MCHT_MAX_QUERIES = 32
comptime MCHT_MAX_LENGTH = 99
comptime MCHT_INVALID: Int64 = -9223372036854775807 - 1

struct MchtLine:
    var slope: Int64
    var intercept: Int64

fn mcht_value(line: MchtLine, x: Int64) -> Int64:
    return line.slope * x + line.intercept

fn mcht_redundant(first: MchtLine, middle: MchtLine, last: MchtLine) -> Bool:
    return (middle.intercept - first.intercept) * (middle.slope - last.slope) >= (last.intercept - middle.intercept) * (first.slope - middle.slope)

@export("monotone_convex_hull_trick")
fn monotone_convex_hull_trick(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MCHT_MAX_LENGTH): return MCHT_INVALID
    let line_count_value = values[0]
    let query_count_value = values[1]
    if line_count_value < 1 or line_count_value > MCHT_MAX_LINES or query_count_value < 0 or query_count_value > MCHT_MAX_QUERIES: return MCHT_INVALID
    let line_count = Int(line_count_value)
    let query_count = Int(query_count_value)
    if length != c_size_t(2 + 2 * line_count + query_count): return MCHT_INVALID

    var hull = InlineArray[MchtLine, MCHT_MAX_LINES]()
    var hull_count = 0
    var previous_slope: Int64 = 9223372036854775807
    var cursor = 2
    for _ in range(line_count):
        let line = MchtLine(values[cursor], values[cursor + 1])
        cursor += 2
        if line.slope < -1000 or line.slope > 1000 or line.intercept < -10000 or line.intercept > 10000 or line.slope >= previous_slope: return MCHT_INVALID
        previous_slope = line.slope
        while hull_count >= 2 and mcht_redundant(hull[hull_count - 2], hull[hull_count - 1], line): hull_count -= 1
        hull[hull_count] = line
        hull_count += 1

    var front = 0
    var previous_x: Int64 = -9223372036854775807 - 1
    var checksum: Int64 = 0
    for i in range(query_count):
        let x = values[cursor + i]
        if x < -1000 or x > 1000 or (i > 0 and x < previous_x): return MCHT_INVALID
        previous_x = x
        while front + 1 < hull_count and mcht_value(hull[front + 1], x) <= mcht_value(hull[front], x): front += 1
        checksum += Int64(i + 1) * mcht_value(hull[front], x)
    return checksum
