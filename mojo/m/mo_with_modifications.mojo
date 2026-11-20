from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 64
comptime MAX_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q

fn apply_update(position: Int, old_value: Int, new_value: Int, forward: Bool,
        mut values: InlineArray[Int, MAX_N], left: Int, right: Int,
        mut frequency: InlineArray[Int, 16], mut distinct: Int):
    var from_value = old_value
    var to_value = new_value
    if not forward:
        from_value = new_value
        to_value = old_value
    if left <= position and position <= right:
        frequency[from_value] -= 1
        if frequency[from_value] == 0:
            distinct -= 1
        if frequency[to_value] == 0:
            distinct += 1
        frequency[to_value] += 1
    values[position] = to_value

@export("mo_with_modifications")
fn mo_with_modifications(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_n = input[0]
    let raw_q = input[1]
    if raw_n < 1 or raw_n > MAX_N or raw_q < 0 or raw_q > MAX_Q:
        return -1
    let n = Int(raw_n)
    let operation_count = Int(raw_q)
    if length != c_size_t(2 + n + 3 * operation_count):
        return -1

    var values = InlineArray[Int, MAX_N](fill=0)
    var simulated = InlineArray[Int, MAX_N](fill=0)
    for index in range(n):
        let value = input[2 + index]
        if value < 0 or value > 15:
            return -1
        values[index] = Int(value)
        simulated[index] = Int(value)

    var update_positions = InlineArray[Int, MAX_Q](fill=0)
    var update_old_values = InlineArray[Int, MAX_Q](fill=0)
    var update_new_values = InlineArray[Int, MAX_Q](fill=0)
    var query_lefts = InlineArray[Int, MAX_Q](fill=0)
    var query_rights = InlineArray[Int, MAX_Q](fill=0)
    var query_times = InlineArray[Int, MAX_Q](fill=0)
    var query_indices = InlineArray[Int, MAX_Q](fill=0)
    var update_count = 0
    var query_count = 0
    var cursor = 2 + n
    for _ in range(operation_count):
        let operation = input[cursor]
        let first = input[cursor + 1]
        let second = input[cursor + 2]
        cursor += 3
        if operation == 0:
            if first < 0 or first >= raw_n or second < 0 or second > 15:
                return -1
            let position = Int(first)
            update_positions[update_count] = position
            update_old_values[update_count] = simulated[position]
            update_new_values[update_count] = Int(second)
            simulated[position] = Int(second)
            update_count += 1
        elif operation == 1:
            if first < 0 or second < first or second >= raw_n:
                return -1
            query_lefts[query_count] = Int(first)
            query_rights[query_count] = Int(second)
            query_times[query_count] = update_count
            query_indices[query_count] = query_count
            query_count += 1
        else:
            return -1

    var block_size = 1
    while block_size * block_size * block_size < n * n:
        block_size += 1
    for index in range(1, query_count):
        let item_left = query_lefts[index]
        let item_right = query_rights[index]
        let item_time = query_times[index]
        let item_index = query_indices[index]
        var j = index
        while j > 0:
            let a_left_block = item_left / block_size
            let b_left_block = query_lefts[j - 1] / block_size
            let a_right_block = item_right / block_size
            let b_right_block = query_rights[j - 1] / block_size
            var should_move = False
            if a_left_block != b_left_block:
                should_move = a_left_block < b_left_block
            elif a_right_block != b_right_block:
                if a_left_block % 2 == 0:
                    should_move = a_right_block < b_right_block
                else:
                    should_move = a_right_block > b_right_block
            elif item_time != query_times[j - 1]:
                if (a_left_block + a_right_block) % 2 == 0:
                    should_move = item_time < query_times[j - 1]
                else:
                    should_move = item_time > query_times[j - 1]
            elif item_right != query_rights[j - 1]:
                if a_left_block % 2 == 0:
                    should_move = item_right < query_rights[j - 1]
                else:
                    should_move = item_right > query_rights[j - 1]
            else:
                should_move = item_index < query_indices[j - 1]
            if not should_move:
                break
            query_lefts[j] = query_lefts[j - 1]
            query_rights[j] = query_rights[j - 1]
            query_times[j] = query_times[j - 1]
            query_indices[j] = query_indices[j - 1]
            j -= 1
        query_lefts[j] = item_left
        query_rights[j] = item_right
        query_times[j] = item_time
        query_indices[j] = item_index

    var answers = InlineArray[Int, MAX_Q](fill=0)
    var frequency = InlineArray[Int, 16](fill=0)
    var distinct = 0
    var current_left = 0
    var current_right = -1
    var current_time = 0
    for query_index in range(query_count):
        let target_left = query_lefts[query_index]
        let target_right = query_rights[query_index]
        let target_time = query_times[query_index]
        while current_time < target_time:
            apply_update(update_positions[current_time], update_old_values[current_time],
                update_new_values[current_time], True, mut values, current_left,
                current_right, mut frequency, mut distinct)
            current_time += 1
        while current_time > target_time:
            current_time -= 1
            apply_update(update_positions[current_time], update_old_values[current_time],
                update_new_values[current_time], False, mut values, current_left,
                current_right, mut frequency, mut distinct)
        while current_left > target_left:
            current_left -= 1
            let value = values[current_left]
            if frequency[value] == 0:
                distinct += 1
            frequency[value] += 1
        while current_right < target_right:
            current_right += 1
            let value = values[current_right]
            if frequency[value] == 0:
                distinct += 1
            frequency[value] += 1
        while current_left < target_left:
            let value = values[current_left]
            frequency[value] -= 1
            if frequency[value] == 0:
                distinct -= 1
            current_left += 1
        while current_right > target_right:
            let value = values[current_right]
            frequency[value] -= 1
            if frequency[value] == 0:
                distinct -= 1
            current_right -= 1
        answers[query_indices[query_index]] = distinct

    var checksum: Int64 = 0
    for index in range(query_count):
        checksum += Int64(index + 1) * Int64(answers[index] + 1)
    return checksum
