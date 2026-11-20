from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ROWS = 6
comptime MAX_COLUMNS = 8
comptime MAX_INPUT = 17
comptime MAX_STACK = 32

fn rs_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

fn rs_interval_cover(
    left: InlineArray[Int, MAX_ROWS], right: InlineArray[Int, MAX_ROWS], count: Int,
    weights: InlineArray[Int64, MAX_COLUMNS], columns: Int,
    inout out_cost: Int64, inout out_mask: Int64,
) -> Bool:
    if count == 0:
        out_cost = 0
        out_mask = 0
        return True
    var minimum_right = right[0]
    var maximum_left = left[0]
    for i in range(1, count):
        if right[i] < minimum_right: minimum_right = right[i]
        if left[i] > maximum_left: maximum_left = left[i]
    var costs = InlineArray[Int64, MAX_COLUMNS](fill=1000000)
    var masks = InlineArray[Int64, MAX_COLUMNS](fill=0)
    for point in range(columns):
        if point <= minimum_right:
            costs[point] = weights[point]
            masks[point] = Int64(1) << point
        for previous in range(point):
            if costs[previous] == 1000000: continue
            var blocked = False
            for i in range(count):
                if previous < left[i] and right[i] < point:
                    blocked = True
                    break
            if blocked: continue
            let candidate_cost = costs[previous] + weights[point]
            let candidate_mask = masks[previous] | (Int64(1) << point)
            if candidate_cost < costs[point] or
                (candidate_cost == costs[point] and candidate_mask < masks[point]):
                costs[point] = candidate_cost
                masks[point] = candidate_mask
    out_cost = 1000000
    out_mask = 0
    for point in range(maximum_left, columns):
        if costs[point] < out_cost or
            (costs[point] == out_cost and costs[point] != 1000000 and masks[point] < out_mask):
            out_cost = costs[point]
            out_mask = masks[point]
    return out_cost != 1000000

@export("ruf_schobel_set_cover")
fn ruf_schobel_set_cover(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT): return -1
    let rows_raw = input[0]
    let columns_raw = input[1]
    if rows_raw < 1 or rows_raw > MAX_ROWS or columns_raw < 1 or columns_raw > MAX_COLUMNS: return -1
    let rows = Int(rows_raw)
    let columns = Int(columns_raw)
    if length != c_size_t(2 + rows + columns): return -1
    var weights = InlineArray[Int64, MAX_COLUMNS](fill=0)
    for column in range(columns):
        let weight = input[2 + column]
        if weight < 1 or weight > 20: return -1
        weights[column] = weight
    let allowed = (UInt64(1) << columns) - UInt64(1)
    var row_masks = InlineArray[UInt64, MAX_ROWS](fill=0)
    var block_left = InlineArray[Int, MAX_ROWS * MAX_COLUMNS](fill=0)
    var block_right = InlineArray[Int, MAX_ROWS * MAX_COLUMNS](fill=0)
    var block_count = InlineArray[Int, MAX_ROWS](fill=0)
    for row in range(rows):
        let raw = input[2 + columns + row]
        if raw < 0 or (UInt64(raw) & ~allowed) != 0: return -1
        row_masks[row] = UInt64(raw)
        var column = 0
        while column < columns:
            if (row_masks[row] & (UInt64(1) << column)) == 0:
                column += 1
                continue
            let block = block_count[row]
            let slot = row * MAX_COLUMNS + block
            block_left[slot] = column
            while column + 1 < columns and (row_masks[row] & (UInt64(1) << (column + 1))) != 0:
                column += 1
            block_right[slot] = column
            block_count[row] += 1
            column += 1
    for row in range(rows):
        if row_masks[row] == 0:
            if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
            rs_store_i64_le(output, -1)
            return 8

    var best_cost: Int64 = 1000000
    var stack = InlineArray[Int8, MAX_STACK * MAX_ROWS](fill=-1)
    var stack_size = 1
    while stack_size > 0:
        stack_size -= 1
        var fixed = InlineArray[Int, MAX_ROWS](fill=-1)
        for row in range(rows): fixed[row] = Int(stack[stack_size * MAX_ROWS + row])
        var left = InlineArray[Int, MAX_ROWS](fill=0)
        var right = InlineArray[Int, MAX_ROWS](fill=0)
        var count = 0
        for row in range(rows):
            if block_count[row] == 1 or fixed[row] >= 0:
                var block = 0
                if block_count[row] != 1: block = fixed[row]
                let slot = row * MAX_COLUMNS + block
                left[count] = block_left[slot]
                right[count] = block_right[slot]
                count += 1
        var lower_cost: Int64 = 0
        var lower_mask: Int64 = 0
        if not rs_interval_cover(left, right, count, weights, columns, lower_cost, lower_mask): continue
        var extra_left = InlineArray[Int, MAX_ROWS](fill=0)
        var extra_right = InlineArray[Int, MAX_ROWS](fill=0)
        var extra_count = 0
        for row in range(rows):
            if (row_masks[row] & UInt64(lower_mask)) != 0: continue
            var chosen = 0
            var chosen_cost = 1000000
            for block in range(block_count[row]):
                let slot = row * MAX_COLUMNS + block
                var cheapest = 1000000
                for column in range(block_left[slot], block_right[slot] + 1):
                    if weights[column] < cheapest: cheapest = Int(weights[column])
                if cheapest < chosen_cost:
                    chosen = block
                    chosen_cost = cheapest
            let slot = row * MAX_COLUMNS + chosen
            extra_left[extra_count] = block_left[slot]
            extra_right[extra_count] = block_right[slot]
            extra_count += 1
        var extra_cost: Int64 = 0
        var extra_mask: Int64 = 0
        if not rs_interval_cover(extra_left, extra_right, extra_count, weights, columns, extra_cost, extra_mask): continue
        let candidate_mask = lower_mask | extra_mask
        var candidate_cost: Int64 = 0
        for column in range(columns):
            if (candidate_mask & (Int64(1) << column)) != 0: candidate_cost += weights[column]
        if candidate_cost < best_cost: best_cost = candidate_cost
        if best_cost <= lower_cost: continue
        var branch = -1
        for row in range(rows):
            if block_count[row] > 1 and fixed[row] < 0:
                branch = row
                break
        if branch < 0: continue
        for block in range(block_count[branch] - 1, -1, -1):
            for row in range(rows):
                stack[stack_size * MAX_ROWS + row] = Int8(fixed[row])
            stack[stack_size * MAX_ROWS + branch] = Int8(block)
            stack_size += 1
    let result = if best_cost == 1000000: Int64(-1) else: best_cost
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    rs_store_i64_le(output, result)
    return 8
