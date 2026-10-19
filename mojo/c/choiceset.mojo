from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("choiceset")
fn choiceset(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or values[0] < 0 or values[0] > 1024: return -1
    let operation_count = values[0]
    if length != 1 + 2 * operation_count: return -1
    var elements = InlineArray[Int64, 256](0)
    var results = InlineArray[Int64, 1024](0)
    var element_count: Int64 = 0
    for op_index in range(operation_count):
        let operation = values[1 + 2 * op_index]
        let argument = values[2 + 2 * op_index]
        if operation >= 1 and operation <= 3:
            if argument < -1000000000 or argument > 1000000000: return -1
            var found: Int64 = -1
            for i in range(element_count):
                if elements[i] == argument: found = i
            if operation == 1:
                if found >= 0: results[op_index] = 0
                else:
                    if element_count >= 256: return -1
                    elements[element_count] = argument
                    element_count += 1
                    results[op_index] = 1
            elif operation == 2:
                results[op_index] = 1 if found >= 0 else 0
            elif found < 0:
                results[op_index] = 0
            else:
                let last = element_count - 1
                if found != last: elements[found] = elements[last]
                element_count -= 1
                results[op_index] = 1
        elif operation == 4:
            if argument < 1 or argument > element_count: return -1
            results[op_index] = elements[argument - 1]
        else: return -1
    let output_bytes = operation_count * 8
    if capacity < output_bytes or (output_bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(operation_count):
        let bits = bitcast[UInt64](results[i])
        for byte in range(8): output[i * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    return output_bytes
