from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_PARSEABLE_LENGTH = 194

struct CdqPoint(Copyable):
    var x: Int64
    var y: Int64
    var z: Int64
    var multiplicity: Int64
    var z_rank: Int
    var original_index: Int

    fn __init__(out self, x: Int64, y: Int64, z: Int64,
            multiplicity: Int64, z_rank: Int, original_index: Int):
        self.x = x
        self.y = y
        self.z = z
        self.multiplicity = multiplicity
        self.z_rank = z_rank
        self.original_index = original_index

struct CdqContext:
    var points: InlineArray[CdqPoint, MAX_N]
    var original_group: InlineArray[Int, MAX_N]
    var dominated: InlineArray[Int64, MAX_N]
    var bit: InlineArray[Int64, MAX_N + 1]
    var source_order: InlineArray[Int, MAX_N]
    var target_order: InlineArray[Int, MAX_N]
    var z_values: InlineArray[Int64, MAX_N]

    fn __init__(out self):
        self.points = InlineArray[CdqPoint, MAX_N](fill=CdqPoint(0, 0, 0, 0, 0, 0))
        self.original_group = InlineArray[Int, MAX_N](fill=0)
        self.dominated = InlineArray[Int64, MAX_N](fill=0)
        self.bit = InlineArray[Int64, MAX_N + 1](fill=0)
        self.source_order = InlineArray[Int, MAX_N](fill=0)
        self.target_order = InlineArray[Int, MAX_N](fill=0)
        self.z_values = InlineArray[Int64, MAX_N](fill=0)

fn point_less(a: CdqPoint, b: CdqPoint) -> Bool:
    if a.x != b.x:
        return a.x < b.x
    if a.y != b.y:
        return a.y < b.y
    return a.z < b.z

fn same_coordinates(a: CdqPoint, b: CdqPoint) -> Bool:
    return a.x == b.x and a.y == b.y and a.z == b.z

fn bit_add(mut context: CdqContext, start: Int, delta: Int64, limit: Int):
    var index = start
    while index <= limit:
        context.bit[index] += delta
        index += index & -index

fn bit_sum(context: CdqContext, start: Int) -> Int64:
    var index = start
    var total: Int64 = 0
    while index > 0:
        total += context.bit[index]
        index -= index & -index
    return total

fn cdq(mut context: CdqContext, left: Int, right: Int, group_count: Int):
    if left >= right:
        return
    let middle = left + (right - left) // 2
    cdq(mut context, left, middle, group_count)
    cdq(mut context, middle + 1, right, group_count)

    var source_cursor = left
    for target_position in range(middle + 1, right + 1):
        let target = context.source_order[target_position]
        while source_cursor <= middle:
            let source = context.source_order[source_cursor]
            if context.points[source].y > context.points[target].y:
                break
            let source_rank = context.points[source].z_rank
            let source_weight = context.points[source].multiplicity
            bit_add(mut context, source_rank, source_weight, group_count)
            source_cursor += 1
        let target_rank = context.points[target].z_rank
        let amount = bit_sum(context, target_rank)
        context.dominated[target] += amount
    for i in range(left, source_cursor):
        let source = context.source_order[i]
        let source_rank = context.points[source].z_rank
        let source_weight = context.points[source].multiplicity
        bit_add(mut context, source_rank, -source_weight, group_count)

    var left_cursor = left
    var right_cursor = middle + 1
    var destination = left
    while left_cursor <= middle and right_cursor <= right:
        let left_point = context.source_order[left_cursor]
        let right_point = context.source_order[right_cursor]
        if context.points[left_point].y <= context.points[right_point].y:
            context.target_order[destination] = left_point
            left_cursor += 1
        else:
            context.target_order[destination] = right_point
            right_cursor += 1
        destination += 1
    while left_cursor <= middle:
        context.target_order[destination] = context.source_order[left_cursor]
        left_cursor += 1
        destination += 1
    while right_cursor <= right:
        context.target_order[destination] = context.source_order[right_cursor]
        right_cursor += 1
        destination += 1
    for i in range(left, right + 1):
        context.source_order[i] = context.target_order[i]

@export("cdq_three_dimensional_dominance")
fn cdq_three_dimensional_dominance(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(1) or
            length > c_size_t(MAX_PARSEABLE_LENGTH):
        return -1
    if input[0] < 1 or input[0] > MAX_N:
        return -1
    let n = Int(input[0])
    if Int(length) != 1 + 3 * n:
        return -1

    var context = CdqContext()
    for i in range(n):
        let x = input[1 + 3 * i]
        let y = input[2 + 3 * i]
        let z = input[3 + 3 * i]
        if x < -1000 or x > 1000 or y < -1000 or y > 1000 or z < -1000 or z > 1000:
            return -1
        context.points[i] = CdqPoint(x, y, z, 1, 0, i)
    for i in range(1, n):
        let value = context.points[i]
        var j = i
        while j > 0 and point_less(value, context.points[j - 1]):
            context.points[j] = context.points[j - 1]
            j -= 1
        context.points[j] = value

    var group_count = 0
    for i in range(n):
        let point = context.points[i]
        if group_count > 0 and same_coordinates(point, context.points[group_count - 1]):
            context.points[group_count - 1].multiplicity += 1
            context.original_group[point.original_index] = group_count - 1
        else:
            context.points[group_count] = point
            context.points[group_count].multiplicity = 1
            context.original_group[point.original_index] = group_count
            group_count += 1

    for i in range(group_count):
        context.z_values[i] = context.points[i].z
    for i in range(1, group_count):
        let value = context.z_values[i]
        var j = i
        while j > 0 and value < context.z_values[j - 1]:
            context.z_values[j] = context.z_values[j - 1]
            j -= 1
        context.z_values[j] = value
    var z_count = 0
    for i in range(group_count):
        let value = context.z_values[i]
        if z_count == 0 or value != context.z_values[z_count - 1]:
            context.z_values[z_count] = value
            z_count += 1
    for i in range(group_count):
        var low = 0
        var high = z_count
        while low < high:
            let middle = low + (high - low) // 2
            if context.z_values[middle] < context.points[i].z:
                low = middle + 1
            else:
                high = middle
        context.points[i].z_rank = low + 1
        context.source_order[i] = i

    if group_count > 1:
        cdq(mut context, 0, group_count - 1, z_count)
    var result: Int64 = 0
    for i in range(n):
        let group = context.original_group[i]
        let count = context.dominated[group] + context.points[group].multiplicity - 1
        result += Int64(i + 1) * count
    return result
