from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_ITEMS = 16
comptime MAX_CAPACITY = 32
comptime MAX_INPUT_LENGTH = 19
comptime STRIDE = MAX_CAPACITY + 1

@export("subset_sum_bin_packing")
fn subset_sum_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_count = input[0]
    let raw_capacity = input[1]
    if raw_count < 1 or raw_count > MAX_ITEMS or raw_capacity < 1 or raw_capacity > MAX_CAPACITY:
        return -1
    let count = Int(raw_count)
    let capacity = Int(raw_capacity)
    if length != c_size_t(2 + count):
        return -1

    var remaining_size = InlineArray[Int, MAX_ITEMS](fill=0)
    var remaining_item = InlineArray[Int, MAX_ITEMS](fill=0)
    var assigned_bin = InlineArray[Int, MAX_ITEMS](fill=0)
    for i in range(count):
        let size = input[2 + i]
        if size < 1 or size > raw_capacity:
            return -1
        remaining_size[i] = Int(size)
        remaining_item[i] = i

    var remaining_count = count
    var bin_count = 0
    while remaining_count > 0:
        var reachable = InlineArray[Bool, (MAX_ITEMS + 1) * STRIDE](fill=False)
        reachable[remaining_count * STRIDE] = True
        var row = remaining_count
        while row > 0:
            row -= 1
            let size = remaining_size[row]
            for sum in range(capacity + 1):
                reachable[row * STRIDE + sum] = reachable[(row + 1) * STRIDE + sum]
                if sum >= size and reachable[(row + 1) * STRIDE + sum - size]:
                    reachable[row * STRIDE + sum] = True

        var target = capacity
        while target > 0 and not reachable[target]:
            target -= 1
        var selected = InlineArray[Bool, MAX_ITEMS](fill=False)
        var needed = target
        for item in range(remaining_count):
            let size = remaining_size[item]
            if size <= needed and reachable[(item + 1) * STRIDE + needed - size]:
                selected[item] = True
                needed -= size
                assigned_bin[remaining_item[item]] = bin_count

        var survivors = 0
        for item in range(remaining_count):
            if not selected[item]:
                remaining_size[survivors] = remaining_size[item]
                remaining_item[survivors] = remaining_item[item]
                survivors += 1
        remaining_count = survivors
        bin_count += 1

    var checksum: Int64 = Int64(bin_count * 10000)
    for i in range(count):
        checksum += Int64((i + 1) * (assigned_bin[i] + 1))
    return checksum
