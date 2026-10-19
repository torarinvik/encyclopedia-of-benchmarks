from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("circular_buffer_benchmark")
fn circular_buffer_benchmark(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1025 or (length - 1) % 2 != 0: return -1
    let capacity = values[0]
    if capacity < 1 or capacity > 256: return -1
    let operation_count = (length - 1) // 2
    var buffer = InlineArray[Int64, 256](0)
    var head: Int64 = 0
    var tail: Int64 = 0
    var count: Int64 = 0
    var checksum: Int64 = 0
    for operation in range(operation_count):
        let opcode = values[1 + 2 * operation]
        let payload = values[2 + 2 * operation]
        var observed: Int64 = 0
        if opcode == 0:
            if payload < 0 or payload > 1000000: return -1
            let was_empty = count == 0
            if count == capacity: head = (head + 1) % capacity
            else: count += 1
            buffer[tail] = payload
            tail = (tail + 1) % capacity
            observed = 1 if was_empty else 0
        elif opcode == 1:
            if payload != 0: return -1
            if count == 0: observed = -1
            else:
                observed = buffer[head]
                head = (head + 1) % capacity
                count -= 1
        elif opcode == 2:
            if payload != 0: return -1
            observed = 1 if count == 0 else 0
        elif opcode == 3:
            if payload != 0: return -1
            observed = 1 if count == capacity else 0
        elif opcode == 4:
            if payload != 0: return -1
            observed = count
        else: return -1
        checksum += (operation + 1) * (observed + 1000000)
    for index in range(count): checksum += (operation_count + index + 1) * (buffer[(head + index) % capacity] + 1000000)
    return checksum
