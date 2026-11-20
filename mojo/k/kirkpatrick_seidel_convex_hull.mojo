from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_POINTS = 32
const MAX_INPUT_VALUES = 66
const MAX_COORDINATE = 1000

struct Point(Copyable):
    var x: Int64
    var y: Int64

struct Slope(Copyable):
    var dy: Int64
    var dx: Int64

struct Bridge(Copyable):
    var left: Int
    var right: Int

fn ks_compare_slope(a: Slope, b: Slope) -> Int:
    let lhs = a.dy * b.dx
    let rhs = b.dy * a.dx
    if lhs < rhs: return -1
    if lhs > rhs: return 1
    return 0

fn ks_select_x(inout ids: InlineArray[Int32, MAX_POINTS], n: Int, rank: Int,
               points: InlineArray[Point, MAX_POINTS]) -> Int:
    if n <= 5:
        for i in range(1, n):
            let value = ids[i]
            var j = i
            while j > 0 and points[Int(ids[j - 1])].x > points[Int(value)].x:
                ids[j] = ids[j - 1]
                j -= 1
            ids[j] = value
        return Int(ids[rank])
    var medians = InlineArray[Int32, MAX_POINTS](fill=0)
    var median_count = 0
    var start = 0
    while start < n:
        let group = min(5, n - start)
        var small = InlineArray[Int32, MAX_POINTS](fill=0)
        for i in range(group): small[i] = ids[start + i]
        for i in range(1, group):
            let value = small[i]
            var j = i
            while j > 0 and points[Int(small[j - 1])].x > points[Int(value)].x:
                small[j] = small[j - 1]
                j -= 1
            small[j] = value
        medians[median_count] = small[(group - 1) // 2]
        median_count += 1
        start += group
    let pivot = ks_select_x(inout medians, median_count, (median_count - 1) // 2, points)
    var lower = 0
    var cursor = 0
    var upper = n
    while cursor < upper:
        if points[Int(ids[cursor])].x < points[pivot].x:
            let temp = ids[lower]
            ids[lower] = ids[cursor]
            ids[cursor] = temp
            lower += 1
            cursor += 1
        elif points[Int(ids[cursor])].x > points[pivot].x:
            upper -= 1
            let temp = ids[upper]
            ids[upper] = ids[cursor]
            ids[cursor] = temp
        else:
            cursor += 1
    if rank < lower:
        var part = InlineArray[Int32, MAX_POINTS](fill=0)
        for i in range(lower): part[i] = ids[i]
        return ks_select_x(inout part, lower, rank, points)
    if rank < upper: return pivot
    var part = InlineArray[Int32, MAX_POINTS](fill=0)
    let part_count = n - upper
    for i in range(part_count): part[i] = ids[upper + i]
    return ks_select_x(inout part, part_count, rank - upper, points)

fn ks_sort_slopes(inout values: InlineArray[Slope, MAX_POINTS], n: Int):
    for i in range(1, n):
        let value = values[i]
        var j = i
        while j > 0 and ks_compare_slope(values[j - 1], value) > 0:
            values[j] = values[j - 1]
            j -= 1
        values[j] = value

fn ks_select_slope(inout values: InlineArray[Slope, MAX_POINTS], n: Int, rank: Int) -> Slope:
    if n <= 5:
        ks_sort_slopes(inout values, n)
        return values[rank]
    var medians = InlineArray[Slope, MAX_POINTS](fill=Slope(0, 1))
    var median_count = 0
    var start = 0
    while start < n:
        let group = min(5, n - start)
        var small = InlineArray[Slope, MAX_POINTS](fill=Slope(0, 1))
        for i in range(group): small[i] = values[start + i]
        ks_sort_slopes(inout small, group)
        medians[median_count] = small[(group - 1) // 2]
        median_count += 1
        start += group
    let pivot = ks_select_slope(inout medians, median_count, (median_count - 1) // 2)
    var lower = 0
    var cursor = 0
    var upper = n
    while cursor < upper:
        let order = ks_compare_slope(values[cursor], pivot)
        if order < 0:
            let temp = values[lower]
            values[lower] = values[cursor]
            values[cursor] = temp
            lower += 1
            cursor += 1
        elif order > 0:
            upper -= 1
            let temp = values[upper]
            values[upper] = values[cursor]
            values[cursor] = temp
        else:
            cursor += 1
    if rank < lower:
        var part = InlineArray[Slope, MAX_POINTS](fill=Slope(0, 1))
        for i in range(lower): part[i] = values[i]
        return ks_select_slope(inout part, lower, rank)
    if rank < upper: return pivot
    var part = InlineArray[Slope, MAX_POINTS](fill=Slope(0, 1))
    let part_count = n - upper
    for i in range(part_count): part[i] = values[upper + i]
    return ks_select_slope(inout part, part_count, rank - upper)

fn ks_pair_slope(first: Int, second: Int, points: InlineArray[Point, MAX_POINTS]) -> Slope:
    let left = if points[first].x < points[second].x: first else: second
    let right = if left == first: second else: first
    return Slope(points[right].y - points[left].y, points[right].x - points[left].x)

fn ks_upper_bridge(points: InlineArray[Point, MAX_POINTS],
                   inout candidates: InlineArray[Int32, MAX_POINTS],
                   count_input: Int, separator: Int64) -> Bridge:
    var count = count_input
    while count > 2:
        let pair_count = count // 2
        var slopes = InlineArray[Slope, MAX_POINTS](fill=Slope(0, 1))
        for pair in range(pair_count):
            slopes[pair] = ks_pair_slope(Int(candidates[2 * pair]), Int(candidates[2 * pair + 1]), points)
        let median = ks_select_slope(inout slopes, pair_count, (pair_count - 1) // 2)
        var support: Int64 = -5_000_000
        for i in range(count):
            let p = points[Int(candidates[i])]
            support = max(support, p.y * median.dx - median.dy * p.x)
        var left = -1
        var right = -1
        for i in range(count):
            let id = Int(candidates[i])
            let p = points[id]
            if p.y * median.dx - median.dy * p.x == support:
                if left < 0 or p.x < points[left].x: left = id
                if right < 0 or p.x > points[right].x: right = id
        if points[left].x <= separator and separator < points[right].x:
            return Bridge(left, right)
        let support_is_left = points[right].x <= separator
        var next = InlineArray[Int32, MAX_POINTS](fill=0)
        var next_count = 0
        for pair in range(pair_count):
            let first = Int(candidates[2 * pair])
            let second = Int(candidates[2 * pair + 1])
            let order = ks_compare_slope(ks_pair_slope(first, second, points), median)
            var keep_first = False
            var keep_second = False
            if support_is_left:
                keep_first = order < 0
                keep_second = order < 0
                if order >= 0:
                    keep_first = points[first].x > points[second].x
                    keep_second = points[second].x > points[first].x
            else:
                keep_first = order > 0
                keep_second = order > 0
                if order <= 0:
                    keep_first = points[first].x < points[second].x
                    keep_second = points[second].x < points[first].x
            if keep_first:
                next[next_count] = Int32(first)
                next_count += 1
            if keep_second:
                next[next_count] = Int32(second)
                next_count += 1
        if count % 2 == 1:
            next[next_count] = candidates[count - 1]
            next_count += 1
        for i in range(next_count): candidates[i] = next[i]
        count = next_count
    let first = Int(candidates[0])
    let second = Int(candidates[1])
    if points[first].x < points[second].x: return Bridge(first, second)
    return Bridge(second, first)

fn ks_append_unique(inout chain: InlineArray[Int32, MAX_POINTS],
                    inout chain_count: Int, point: Int):
    if chain_count == 0 or Int(chain[chain_count - 1]) != point:
        chain[chain_count] = Int32(point)
        chain_count += 1

fn ks_connect_upper(points: InlineArray[Point, MAX_POINTS],
                    candidates: InlineArray[Int32, MAX_POINTS], count: Int,
                    left: Int, right: Int,
                    inout chain: InlineArray[Int32, MAX_POINTS],
                    inout chain_count: Int):
    if left == right:
        ks_append_unique(inout chain, inout chain_count, left)
        return
    var median_ids = candidates
    let separator_id = ks_select_x(inout median_ids, count, (count - 1) // 2, points)
    let separator = points[separator_id].x
    var bridge_candidates = candidates
    let bridge = ks_upper_bridge(points, inout bridge_candidates, count, separator)
    var left_set = InlineArray[Int32, MAX_POINTS](fill=0)
    var right_set = InlineArray[Int32, MAX_POINTS](fill=0)
    var left_count = 0
    var right_count = 0
    for i in range(count):
        let id = Int(candidates[i])
        if points[id].x <= points[bridge.left].x:
            left_set[left_count] = candidates[i]
            left_count += 1
        if points[id].x >= points[bridge.right].x:
            right_set[right_count] = candidates[i]
            right_count += 1
    ks_connect_upper(points, left_set, left_count, left, bridge.left, inout chain, inout chain_count)
    ks_append_unique(inout chain, inout chain_count, bridge.right)
    ks_connect_upper(points, right_set, right_count, bridge.right, right, inout chain, inout chain_count)

fn ks_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("kirkpatrick_seidel_convex_hull")
fn kirkpatrick_seidel_convex_hull(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    if input[0] < 3 or input[0] > MAX_POINTS: return -1
    let count = Int(input[0])
    if length != c_size_t(1 + 2 * count): return -1
    var original = InlineArray[Point, MAX_POINTS](fill=Point(0, 0))
    var upper_points = InlineArray[Point, MAX_POINTS](fill=Point(0, 0))
    var lower_points = InlineArray[Point, MAX_POINTS](fill=Point(0, 0))
    var seen_x = InlineArray[Bool, 2001](fill=False)
    for i in range(count):
        let x = input[1 + 2 * i]
        let y = input[2 + 2 * i]
        if x < -MAX_COORDINATE or x > MAX_COORDINATE or y < -MAX_COORDINATE or y > MAX_COORDINATE:
            return -1
        let slot = Int(x + MAX_COORDINATE)
        if seen_x[slot]: return -1
        seen_x[slot] = True
        original[i] = Point(x, y)
        upper_points[i] = Point(x, y)
        lower_points[i] = Point(x, -y)
    var non_collinear = False
    for i in range(2, count):
        let cross = (original[1].x - original[0].x) * (original[i].y - original[0].y) -
                    (original[1].y - original[0].y) * (original[i].x - original[0].x)
        if cross != 0:
            non_collinear = True
            break
    if not non_collinear: return -1
    var ids = InlineArray[Int32, MAX_POINTS](fill=0)
    var upper = InlineArray[Int32, MAX_POINTS](fill=0)
    var lower = InlineArray[Int32, MAX_POINTS](fill=0)
    var hull = InlineArray[Int32, MAX_POINTS](fill=0)
    var left_index = 0
    var right_index = 0
    for i in range(count):
        ids[i] = Int32(i)
        if original[i].x < original[left_index].x: left_index = i
        if original[i].x > original[right_index].x: right_index = i
    var upper_count = 0
    var lower_count = 0
    ks_connect_upper(upper_points, ids, count, left_index, right_index, inout upper, inout upper_count)
    ks_connect_upper(lower_points, ids, count, left_index, right_index, inout lower, inout lower_count)
    var hull_count = 0
    for i in range(lower_count):
        ks_append_unique(inout hull, inout hull_count, Int(lower[i]))
    var upper_index = upper_count
    while upper_index > 2:
        upper_index -= 1
        ks_append_unique(inout hull, inout hull_count, Int(upper[upper_index - 1]))
    let output_bytes = hull_count * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for i in range(hull_count):
        let point = original[Int(hull[i])]
        ks_store_i64(output, 16 * i, point.x)
        ks_store_i64(output, 16 * i + 8, point.y)
    return Int64(output_bytes)
