from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("circular_linked_list_benchmark")
fn circular_linked_list_benchmark(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 1024 or length % 2 != 0 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    let operation_count = length // 2
    var items = InlineArray[Int64, 256](0)
    var count: Int64 = 0
    var checksum: Int64 = 0
    for operation in range(operation_count):
        let opcode = values[2 * operation]
        let payload = values[2 * operation + 1]
        var observed: Int64 = 0
        var returns_value = True
        if opcode == 0 or opcode == 1:
            if payload < -1000000 or payload > 1000000 or count == 256: return -1
            if opcode == 0: items[count] = payload
            else:
                var i = count
                while i > 0:
                    items[i] = items[i - 1]
                    i -= 1
                items[0] = payload
            count += 1
            returns_value = False
        elif opcode == 2 or opcode == 3:
            if payload != 0 or count == 0: return -1
            if opcode == 2:
                observed = items[0]
                for i in range(1, count): items[i - 1] = items[i]
            else: observed = items[count - 1]
            count -= 1
        elif opcode == 4 or opcode == 5:
            if payload < -1000000 or payload > 1000000: return -1
            var found: Int64 = -1
            for i in range(count):
                if found < 0 and items[i] == payload: found = i
            observed = 1 if found >= 0 else 0
            if opcode == 4 and found >= 0:
                for i in range(found + 1, count): items[i - 1] = items[i]
                count -= 1
        elif opcode == 6:
            if payload != 0: return -1
            observed = count
        elif opcode == 7 or opcode == 8:
            if payload < 0 or payload > 1000000 or count == 0: return -1
            if opcode == 8 and payload >= count: return -1
            let index = payload if opcode == 7 else payload
            if opcode == 7 and index >= count: return -1
            observed = items[index]
            if opcode == 8:
                for i in range(index + 1, count): items[i - 1] = items[i]
                count -= 1
        else: return -1
        if returns_value: checksum += (operation + 1) * (observed + 1000000)
    for i in range(count): checksum += (operation_count + i + 1) * (items[i] + 1000000)
    return checksum
