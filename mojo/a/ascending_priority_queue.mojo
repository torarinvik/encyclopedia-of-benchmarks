from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("ascending_priority_queue")
fn ascending_priority_queue(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 512 or length != c_size_t(1 + 2 * input[0]):
        return -1
    var queue = List[Int64](capacity=64)
    var checksum: Int64 = 0
    for operation in range(Int(input[0])):
        let opcode = input[1 + 2 * operation]
        let payload = input[2 + 2 * operation]
        if opcode == 0:
            if payload < -1000000 or payload > 1000000 or len(queue) >= 64:
                return -1
            queue.append(payload)
        elif opcode == 1:
            if payload != 0 or len(queue) == 0:
                return -1
            var minimum = 0
            for i in range(1, len(queue)):
                if queue[i] < queue[minimum]:
                    minimum = i
            checksum += Int64(operation + 1) * (queue[minimum] + 1000001)
            for i in range(minimum, len(queue) - 1):
                queue[i] = queue[i + 1]
            queue.pop()
        else:
            return -1
    for i in range(len(queue)):
        checksum += Int64(i + 1) * (queue[i] + 1000001)
    return checksum
