from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_DIMS = 5
alias MAX_ROWS = 16
alias MAX_MASKS = 1 << MAX_DIMS
alias KEY_CELLS = MAX_MASKS * MAX_ROWS * MAX_DIMS
alias SUM_CELLS = MAX_MASKS * MAX_ROWS

fn _dc_popcount(value: Int) -> Int:
    var remaining = value
    var count = 0
    while remaining != 0:
        count += remaining & 1
        remaining >>= 1
    return count

@export("npb_dc_smallest_parent")
fn npb_dc_smallest_parent(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < c_size_t(4) or input_length > c_size_t(98):
        return -1
    if input[0] < 1 or input[0] > MAX_DIMS or input[1] < 1 or input[1] > MAX_ROWS:
        return -1

    let dimensions = Int(input[0])
    let row_count = Int(input[1])
    if input_length != c_size_t(2 + row_count * (dimensions + 1)):
        return -1

    var attributes = InlineArray[Int64, MAX_ROWS * MAX_DIMS]()
    var measures = InlineArray[Int64, MAX_ROWS]()
    var offset = 2
    for row in range(row_count):
        for dimension in range(dimensions):
            let value = input[offset]
            offset += 1
            if value < 0 or value > 7:
                return -1
            attributes[row * MAX_DIMS + dimension] = value
        let measure = input[offset]
        offset += 1
        if measure < 0 or measure > 1000:
            return -1
        measures[row] = measure

    var keys = InlineArray[Int64, KEY_CELLS]()
    var sums = InlineArray[Int64, SUM_CELLS]()
    var group_counts = InlineArray[Int, MAX_MASKS]()
    var parents = InlineArray[Int, MAX_MASKS]()
    for mask in range(MAX_MASKS):
        parents[mask] = -2

    let full_mask = (1 << dimensions) - 1
    parents[full_mask] = -1

    # Build the full-dimensional view directly from the input rows.
    for row in range(row_count):
        var group = 0
        while group < group_counts[full_mask]:
            var equal = True
            for dimension in range(dimensions):
                if keys[full_mask * MAX_ROWS * MAX_DIMS + group * MAX_DIMS + dimension] != attributes[row * MAX_DIMS + dimension]:
                    equal = False
                    break
            if equal:
                break
            group += 1
        if group == group_counts[full_mask]:
            for dimension in range(dimensions):
                keys[full_mask * MAX_ROWS * MAX_DIMS + group * MAX_DIMS + dimension] = attributes[row * MAX_DIMS + dimension]
            sums[full_mask * MAX_ROWS + group] = measures[row]
            group_counts[full_mask] += 1
        else:
            sums[full_mask * MAX_ROWS + group] += measures[row]

    # The directly grouped full view also contributes in key order.
    for index in range(1, group_counts[full_mask]):
        var position = index
        while position > 0:
            let left_base = full_mask * MAX_ROWS * MAX_DIMS + position * MAX_DIMS
            let right_base = full_mask * MAX_ROWS * MAX_DIMS + (position - 1) * MAX_DIMS
            var less = False
            for dimension in range(dimensions):
                if keys[left_base + dimension] < keys[right_base + dimension]:
                    less = True
                    break
                if keys[left_base + dimension] > keys[right_base + dimension]:
                    break
            if not less:
                break
            for dimension in range(dimensions):
                let temporary = keys[left_base + dimension]
                keys[left_base + dimension] = keys[right_base + dimension]
                keys[right_base + dimension] = temporary
            let temporary_sum = sums[full_mask * MAX_ROWS + position]
            sums[full_mask * MAX_ROWS + position] = sums[full_mask * MAX_ROWS + position - 1]
            sums[full_mask * MAX_ROWS + position - 1] = temporary_sum
            position -= 1

    # Visit each lower view only after all of its immediate parents exist.
    for wanted_popcount in range(dimensions - 1, -1, -1):
        for mask in range(full_mask + 1):
            if _dc_popcount(mask) != wanted_popcount:
                continue

            var parent = -1
            for dimension in range(dimensions):
                let bit = 1 << dimension
                if (mask & bit) != 0:
                    continue
                let candidate = mask | bit
                if parent < 0 or group_counts[candidate] < group_counts[parent]:
                    parent = candidate
            if parent < 0:
                return -1
            parents[mask] = parent

            for parent_group in range(group_counts[parent]):
                var group = 0
                while group < group_counts[mask]:
                    var equal = True
                    for dimension in range(dimensions):
                        if (mask & (1 << dimension)) == 0:
                            continue
                        let parent_index = parent * MAX_ROWS * MAX_DIMS + parent_group * MAX_DIMS + dimension
                        let group_index = mask * MAX_ROWS * MAX_DIMS + group * MAX_DIMS + dimension
                        if keys[group_index] != keys[parent_index]:
                            equal = False
                            break
                    if equal:
                        break
                    group += 1

                let parent_sum = sums[parent * MAX_ROWS + parent_group]
                if group == group_counts[mask]:
                    for dimension in range(dimensions):
                        if (mask & (1 << dimension)) != 0:
                            keys[mask * MAX_ROWS * MAX_DIMS + group * MAX_DIMS + dimension] = keys[parent * MAX_ROWS * MAX_DIMS + parent_group * MAX_DIMS + dimension]
                    sums[mask * MAX_ROWS + group] = parent_sum
                    group_counts[mask] += 1
                else:
                    sums[mask * MAX_ROWS + group] += parent_sum

            # Insertion sort the projected groups lexicographically.
            for index in range(1, group_counts[mask]):
                var position = index
                while position > 0:
                    let left_base = mask * MAX_ROWS * MAX_DIMS + position * MAX_DIMS
                    let right_base = mask * MAX_ROWS * MAX_DIMS + (position - 1) * MAX_DIMS
                    var less = False
                    for dimension in range(dimensions):
                        if (mask & (1 << dimension)) == 0:
                            continue
                        if keys[left_base + dimension] < keys[right_base + dimension]:
                            less = True
                            break
                        if keys[left_base + dimension] > keys[right_base + dimension]:
                            break
                    if not less:
                        break
                    for dimension in range(dimensions):
                        let temporary = keys[left_base + dimension]
                        keys[left_base + dimension] = keys[right_base + dimension]
                        keys[right_base + dimension] = temporary
                    let temporary_sum = sums[mask * MAX_ROWS + position]
                    sums[mask * MAX_ROWS + position] = sums[mask * MAX_ROWS + position - 1]
                    sums[mask * MAX_ROWS + position - 1] = temporary_sum
                    position -= 1

    var checksum: Int64 = 0
    for mask in range(full_mask + 1):
        checksum += Int64(mask + 1) * 1000000
        checksum += Int64(parents[mask] + 2) * 10000
        checksum += Int64(group_counts[mask]) * 1000
        for group in range(group_counts[mask]):
            let rank = Int64(group + 1)
            checksum += rank * (sums[mask * MAX_ROWS + group] + 1)
            for dimension in range(dimensions):
                if (mask & (1 << dimension)) != 0:
                    let key = keys[mask * MAX_ROWS * MAX_DIMS + group * MAX_DIMS + dimension]
                    checksum += rank * Int64(dimension + 1) * (key + 1)
    return checksum
