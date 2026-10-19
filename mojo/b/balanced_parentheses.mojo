from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_LENGTH = 4096

@export("balanced_parentheses")
fn balanced_parentheses(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > MAX_LENGTH or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    var stack = List[Int64](capacity=MAX_LENGTH)
    for index in range(length):
        let value = input[index]
        if value == 40 or value == 91 or value == 123:
            stack.append(value)
        elif value == 41 or value == 93 or value == 125:
            if len(stack) == 0:
                return 0
            let opener = stack.pop()
            if (value == 41 and opener != 40) or (value == 93 and opener != 91) or (value == 125 and opener != 123):
                return 0
    return 1 if len(stack) == 0 else 0
