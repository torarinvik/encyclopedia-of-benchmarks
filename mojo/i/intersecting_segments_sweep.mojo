from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn sweep_orient(ax: Int64, ay: Int64, bx: Int64, by: Int64, cx: Int64, cy: Int64) -> Int64:
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

fn sweep_between(a: Int64, b: Int64, point: Int64) -> Bool:
    if a <= b:
        return a <= point and point <= b
    return b <= point and point <= a

fn sweep_on_segment(ax: Int64, ay: Int64, bx: Int64, by: Int64, px: Int64, py: Int64) -> Bool:
    return sweep_orient(ax, ay, bx, by, px, py) == 0 and sweep_between(ax, bx, px) and sweep_between(ay, by, py)

fn sweep_intersects(coords: InlineArray[Int64, 96], first: Int, second: Int) -> Bool:
    let a = first * 4
    let b = second * 4
    let ab_c = sweep_orient(coords[a], coords[a + 1], coords[a + 2], coords[a + 3], coords[b], coords[b + 1])
    let ab_d = sweep_orient(coords[a], coords[a + 1], coords[a + 2], coords[a + 3], coords[b + 2], coords[b + 3])
    let cd_a = sweep_orient(coords[b], coords[b + 1], coords[b + 2], coords[b + 3], coords[a], coords[a + 1])
    let cd_b = sweep_orient(coords[b], coords[b + 1], coords[b + 2], coords[b + 3], coords[a + 2], coords[a + 3])
    if ab_c == 0 and sweep_on_segment(coords[a], coords[a + 1], coords[a + 2], coords[a + 3], coords[b], coords[b + 1]): return True
    if ab_d == 0 and sweep_on_segment(coords[a], coords[a + 1], coords[a + 2], coords[a + 3], coords[b + 2], coords[b + 3]): return True
    if cd_a == 0 and sweep_on_segment(coords[b], coords[b + 1], coords[b + 2], coords[b + 3], coords[a], coords[a + 1]): return True
    if cd_b == 0 and sweep_on_segment(coords[b], coords[b + 1], coords[b + 2], coords[b + 3], coords[a + 2], coords[a + 3]): return True
    return ((ab_c < 0 and ab_d > 0) or (ab_c > 0 and ab_d < 0)) and ((cd_a < 0 and cd_b > 0) or (cd_a > 0 and cd_b < 0))

fn sweep_compare_at_x(coords: InlineArray[Int64, 96], first: Int, second: Int, x: Int64) -> Int:
    let a = first * 4
    let b = second * 4
    let adx = coords[a + 2] - coords[a]
    let bdx = coords[b + 2] - coords[b]
    let a_num = coords[a + 1] * adx + (coords[a + 3] - coords[a + 1]) * (x - coords[a])
    let b_num = coords[b + 1] * bdx + (coords[b + 3] - coords[b + 1]) * (x - coords[b])
    let left = a_num * bdx
    let right = b_num * adx
    if left < right: return -1
    if left > right: return 1
    let a_slope = (coords[a + 3] - coords[a + 1]) * bdx
    let b_slope = (coords[b + 3] - coords[b + 1]) * adx
    if a_slope < b_slope: return -1
    if a_slope > b_slope: return 1
    if first < second: return -1
    if first > second: return 1
    return 0

@export("intersecting_segments_sweep")
fn intersecting_segments_sweep(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 98: return -1
    let count_raw = input[0]
    if count_raw < 0 or count_raw > 24 or length != c_size_t(1 + 4 * count_raw): return -1
    let count = Int(count_raw)
    var used_x = InlineArray[Bool, 201](fill=False)
    var coords = InlineArray[Int64, 96](fill=0)
    var event_x = InlineArray[Int64, 48](fill=0)
    var event_id = InlineArray[Int, 48](fill=0)
    var event_start = InlineArray[Bool, 48](fill=False)
    var event_count = 0
    for id in range(count):
        let x1 = input[1 + 4 * id]
        let y1 = input[2 + 4 * id]
        let x2 = input[3 + 4 * id]
        let y2 = input[4 + 4 * id]
        if x1 < -100 or x1 > 100 or x2 < -100 or x2 > 100 or y1 < -100 or y1 > 100 or y2 < -100 or y2 > 100 or x1 >= x2: return -1
        let first_x = Int(x1 + 100)
        let second_x = Int(x2 + 100)
        if used_x[first_x] or used_x[second_x]: return -1
        used_x[first_x] = True
        used_x[second_x] = True
        coords[4 * id] = x1
        coords[4 * id + 1] = y1
        coords[4 * id + 2] = x2
        coords[4 * id + 3] = y2
        event_x[event_count] = x1
        event_id[event_count] = id
        event_start[event_count] = True
        event_count += 1
        event_x[event_count] = x2
        event_id[event_count] = id
        event_start[event_count] = False
        event_count += 1
    for index in range(1, event_count):
        let saved_x = event_x[index]
        let saved_id = event_id[index]
        let saved_start = event_start[index]
        var position = index
        while position > 0 and event_x[position - 1] > saved_x:
            event_x[position] = event_x[position - 1]
            event_id[position] = event_id[position - 1]
            event_start[position] = event_start[position - 1]
            position -= 1
        event_x[position] = saved_x
        event_id[position] = saved_id
        event_start[position] = saved_start

    var active = InlineArray[Int, 24](fill=0)
    var active_count = 0
    for event_index in range(event_count):
        let x = event_x[event_index]
        let id = event_id[event_index]
        if event_start[event_index]:
            var position = 0
            while position < active_count and sweep_compare_at_x(coords, active[position], id, x) < 0:
                position += 1
            if position > 0 and sweep_intersects(coords, active[position - 1], id): return 1
            if position < active_count and sweep_intersects(coords, active[position], id): return 1
            var move = active_count
            while move > position:
                active[move] = active[move - 1]
                move -= 1
            active[position] = id
            active_count += 1
        else:
            var position = 0
            while position < active_count and active[position] != id: position += 1
            if position == active_count: return -1
            if position > 0 and position + 1 < active_count and sweep_intersects(coords, active[position - 1], active[position + 1]): return 1
            var move = position
            while move + 1 < active_count:
                active[move] = active[move + 1]
                move += 1
            active_count -= 1
    return 0
