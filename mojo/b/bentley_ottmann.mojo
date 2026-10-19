from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_SEGMENTS = 24
comptime MAX_EVENTS = 2 * MAX_SEGMENTS + MAX_SEGMENTS * (MAX_SEGMENTS - 1) // 2
comptime MAX_POINTS = MAX_SEGMENTS * (MAX_SEGMENTS - 1) // 2

struct Segment:
    var x1: Int64
    var y1: Int64
    var x2: Int64
    var y2: Int64

struct SweepEvent:
    var x: Int64
    var y: Int64
    var a: Int
    var b: Int
    var kind: Int
    var done: Bool

struct Point:
    var x: Int64
    var y: Int64

fn cross(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Int64:
    return ax * by - ay * bx

fn intersection(a: Segment, b: Segment) -> (Bool, Point):
    let rx = a.x2 - a.x1
    let ry = a.y2 - a.y1
    let sx = b.x2 - b.x1
    let sy = b.y2 - b.y1
    var denominator = cross(rx, ry, sx, sy)
    var t = cross(b.x1 - a.x1, b.y1 - a.y1, sx, sy)
    var u = cross(b.x1 - a.x1, b.y1 - a.y1, rx, ry)
    if denominator == 0:
        return (False, Point(0, 0))
    if denominator < 0:
        denominator = -denominator
        t = -t
        u = -u
    if t <= 0 or t >= denominator or u <= 0 or u >= denominator:
        return (False, Point(0, 0))
    let x_numerator = a.x1 * denominator + t * rx
    let y_numerator = a.y1 * denominator + t * ry
    if x_numerator % denominator != 0 or y_numerator % denominator != 0:
        return (False, Point(0, 0))
    return (True, Point(x_numerator // denominator, y_numerator // denominator))

fn segment_less(segments: List[Segment], a: Int, b: Int, x: Int64) -> Bool:
    let sa = segments[a]
    let sb = segments[b]
    let da = sa.x2 - sa.x1
    let db = sb.x2 - sb.x1
    let na = sa.y1 * da + (x - sa.x1) * (sa.y2 - sa.y1)
    let nb = sb.y1 * db + (x - sb.x1) * (sb.y2 - sb.y1)
    let height_compare = na * db - nb * da
    if height_compare != 0:
        return height_compare < 0
    let slope_compare = (sa.y2 - sa.y1) * db - (sb.y2 - sb.y1) * da
    if slope_compare != 0:
        return slope_compare < 0
    return a < b

fn append_i64_le(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8):
        bytes.append(UInt8(bits & 255))
        bits >>= 8

@export("bentley_ottmann")
fn bentley_ottmann(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1:
        return -1
    let count_value = input[0]
    if count_value < 0 or count_value > MAX_SEGMENTS or length != c_size_t(1 + 4 * count_value):
        return -1
    let count = Int(count_value)
    var segments = List[Segment](capacity=MAX_SEGMENTS)
    for i in range(count):
        let x1 = input[1 + 4 * i]
        let y1 = input[2 + 4 * i]
        let x2 = input[3 + 4 * i]
        let y2 = input[4 + 4 * i]
        if x1 < -1000 or x1 > 1000 or y1 < -1000 or y1 > 1000 or x2 < -1000 or x2 > 1000 or y2 < -1000 or y2 > 1000 or x1 == x2:
            return -1
        if x1 < x2:
            segments.append(Segment(x1, y1, x2, y2))
        else:
            segments.append(Segment(x2, y2, x1, y1))

    var events = List[SweepEvent](capacity=MAX_EVENTS)
    for i in range(count):
        let s = segments[i]
        events.append(SweepEvent(s.x1, s.y1, i, 0, 0, False))
        events.append(SweepEvent(s.x2, s.y2, i, 0, 1, False))
    var scheduled = List[Bool](capacity=MAX_SEGMENTS * MAX_SEGMENTS)
    for _ in range(MAX_SEGMENTS * MAX_SEGMENTS):
        scheduled.append(False)
    var active = List[Int](capacity=MAX_SEGMENTS)
    var points = List[Point](capacity=MAX_POINTS)

    while True:
        var event_index = len(events)
        for i in range(len(events)):
            let event = events[i]
            if event.done:
                continue
            if event_index == len(events) or event.x < events[event_index].x or (event.x == events[event_index].x and event.y < events[event_index].y):
                event_index = i
        if event_index == len(events):
            break

        let event = events[event_index]
        events[event_index].done = True
        if event.kind == 0:
            active.append(event.a)
        elif event.kind == 1:
            var found = -1
            for i in range(len(active)):
                if active[i] == event.a:
                    found = i
                    break
            if found >= 0:
                for i in range(found + 1, len(active)):
                    active[i - 1] = active[i]
                _ = active.pop()
        else:
            points.append(Point(event.x, event.y))

        for i in range(1, len(active)):
            let value = active[i]
            var j = i
            while j > 0 and segment_less(segments, value, active[j - 1], event.x):
                active[j] = active[j - 1]
                j -= 1
            active[j] = value

        for i in range(1, len(active)):
            let a = active[i - 1]
            let b = active[i]
            let pair_key = a * MAX_SEGMENTS + b
            if scheduled[pair_key]:
                continue
            let (exists, point) = intersection(segments[a], segments[b])
            if exists and point.x > event.x:
                if len(events) >= MAX_EVENTS:
                    return -1
                events.append(SweepEvent(point.x, point.y, a, b, 2, False))
                scheduled[pair_key] = True
                scheduled[b * MAX_SEGMENTS + a] = True

    for i in range(1, len(points)):
        let value = points[i]
        var j = i
        while j > 0 and (points[j - 1].x > value.x or (points[j - 1].x == value.x and points[j - 1].y > value.y)):
            points[j] = points[j - 1]
            j -= 1
        points[j] = value

    let byte_count = c_size_t((1 + 2 * len(points)) * 8)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < byte_count:
        return -2
    var bytes = List[UInt8](capacity=Int(byte_count))
    append_i64_le(bytes, Int64(len(points)))
    for i in range(len(points)):
        append_i64_le(bytes, points[i].x)
        append_i64_le(bytes, points[i].y)
    for i in range(Int(byte_count)):
        output[i] = bytes[i]
    return Int64(byte_count)
