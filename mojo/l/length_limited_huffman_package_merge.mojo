from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_SYMBOLS = 12
comptime MAX_LIMIT = 6
comptime MAX_LEVELS = 16
comptime MAX_ITEMS = 32
comptime MAX_INPUT_LENGTH = 15

@export("length_limited_huffman_package_merge")
fn length_limited_huffman_package_merge(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let symbol_value = input[0]
    let limit_value = input[1]
    if symbol_value < 2 or symbol_value > MAX_SYMBOLS or limit_value < 1 or limit_value > MAX_LIMIT:
        return -1
    let symbol_count = Int(symbol_value)
    let limit = Int(limit_value)
    if symbol_count > (1 << limit) or length != c_size_t(symbol_count + 2):
        return -1

    var weights = InlineArray[Int64, MAX_SYMBOLS](fill=0)
    for index in range(symbol_count):
        let weight = input[index + 2]
        if weight < 0 or weight > 1_000_000:
            return -1
        weights[index] = weight
    for index in range(1, symbol_count):
        let key = weights[index]
        var position = index
        while position > 0 and weights[position - 1] > key:
            weights[position] = weights[position - 1]
            position -= 1
        weights[position] = key

    var levels = InlineArray[Int64, MAX_LEVELS * MAX_ITEMS](fill=0)
    var counts = InlineArray[Int, MAX_LEVELS](fill=0)
    for level in range(limit):
        for index in range(symbol_count):
            levels[level * MAX_ITEMS + index] = weights[index]
        counts[level] = symbol_count

    var remaining = Int64(symbol_count - 1) << limit
    var total: Int64 = 0
    var level = 0
    while remaining > 0:
        while level < MAX_LEVELS and counts[level] == 0:
            level += 1
        if level >= MAX_LEVELS:
            return -1
        let width = Int64(1) << level
        let smallest_needed = remaining & -remaining
        if width > smallest_needed:
            return -1

        let base = level * MAX_ITEMS
        var current_count = counts[level]
        if width == smallest_needed:
            total += levels[base]
            for index in range(1, current_count):
                levels[base + index - 1] = levels[base + index]
            current_count -= 1
            counts[level] = current_count
            remaining -= width
            if remaining == 0:
                break

        var packages = InlineArray[Int64, MAX_ITEMS](fill=0)
        var package_count = 0
        var index = 0
        while index + 1 < current_count:
            packages[package_count] = levels[base + index] + levels[base + index + 1]
            package_count += 1
            index += 2
        counts[level] = 0

        let next_level = level + 1
        if next_level >= MAX_LEVELS:
            return -1
        let existing_count = counts[next_level]
        var merged = InlineArray[Int64, MAX_ITEMS](fill=0)
        var package_index = 0
        var existing_index = 0
        var merged_count = 0
        while package_index < package_count and existing_index < existing_count:
            if packages[package_index] <= levels[next_level * MAX_ITEMS + existing_index]:
                merged[merged_count] = packages[package_index]
                package_index += 1
            else:
                merged[merged_count] = levels[next_level * MAX_ITEMS + existing_index]
                existing_index += 1
            merged_count += 1
        while package_index < package_count:
            merged[merged_count] = packages[package_index]
            package_index += 1
            merged_count += 1
        while existing_index < existing_count:
            merged[merged_count] = levels[next_level * MAX_ITEMS + existing_index]
            existing_index += 1
            merged_count += 1
        for index in range(merged_count):
            levels[next_level * MAX_ITEMS + index] = merged[index]
        counts[next_level] = merged_count
        level = next_level
    return total
