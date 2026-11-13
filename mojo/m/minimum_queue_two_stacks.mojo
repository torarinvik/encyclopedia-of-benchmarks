from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime QUEUE_CAPACITY = 16
comptime MAX_OPERATIONS = 32
comptime MAX_PARSEABLE_LENGTH = 65
comptime VALUE_MIN = -1000
comptime VALUE_MAX = 1000
comptime CHECKSUM_OFFSET = 1001

@export("minimum_queue_two_stacks")
fn minimum_queue_two_stacks(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if input[0] < 0 or input[0] > MAX_OPERATIONS:
        return -1

    var in_values = InlineArray[Int64, QUEUE_CAPACITY]()
    var in_minimums = InlineArray[Int64, QUEUE_CAPACITY]()
    var out_values = InlineArray[Int64, QUEUE_CAPACITY]()
    var out_minimums = InlineArray[Int64, QUEUE_CAPACITY]()
    var in_count = 0
    var out_count = 0
    var cursor = 1
    let operation_count = Int(input[0])
    var checksum: Int64 = 0

    for operation in range(operation_count):
        if cursor >= Int(length):
            return -1
        let opcode = input[cursor]
        cursor += 1
        if opcode == 0:
            if cursor >= Int(length):
                return -1
            let value = input[cursor]
            cursor += 1
            if value < VALUE_MIN or value > VALUE_MAX or in_count + out_count >= QUEUE_CAPACITY:
                return -1
            in_values[in_count] = value
            if in_count == 0 or value < in_minimums[in_count - 1]:
                in_minimums[in_count] = value
            else:
                in_minimums[in_count] = in_minimums[in_count - 1]
            in_count += 1
        elif opcode == 1:
            if in_count + out_count == 0:
                return -1
            if out_count == 0:
                while in_count > 0:
                    in_count -= 1
                    let value = in_values[in_count]
                    out_values[out_count] = value
                    if out_count == 0 or value < out_minimums[out_count - 1]:
                        out_minimums[out_count] = value
                    else:
                        out_minimums[out_count] = out_minimums[out_count - 1]
                    out_count += 1
            out_count -= 1
            checksum += Int64(operation + 1) * (out_values[out_count] + CHECKSUM_OFFSET)
        elif opcode == 2:
            if in_count + out_count == 0:
                return -1
            var observed: Int64 = 0
            if in_count == 0:
                observed = out_minimums[out_count - 1]
            elif out_count == 0:
                observed = in_minimums[in_count - 1]
            elif in_minimums[in_count - 1] < out_minimums[out_count - 1]:
                observed = in_minimums[in_count - 1]
            else:
                observed = out_minimums[out_count - 1]
            checksum += Int64(operation + 1) * (observed + CHECKSUM_OFFSET)
        else:
            return -1
    if cursor != Int(length):
        return -1

    var position = 0
    for index in range(out_count):
        position += 1
        checksum += Int64(position) * (out_values[out_count - index - 1] + CHECKSUM_OFFSET)
    for index in range(in_count):
        position += 1
        checksum += Int64(position) * (in_values[index] + CHECKSUM_OFFSET)
    return checksum
