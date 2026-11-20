from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LIMIT: Int64 = 100_000
const MAX_QUEUE = 70_000

fn is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    var divisor: Int64 = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 2
    return True

fn search(base: Int64, digits: Int64) -> Int64:
    var queue = InlineArray[Int64, MAX_QUEUE](fill=0)
    var end = 0
    for value in range(2, Int(base)):
        if is_prime(Int64(value)):
            queue[end] = Int64(value)
            end += 1
    var best = queue[end - 1]
    var level_start = 0
    var level_end = end
    var place = base
    var width: Int64 = 1
    while width < digits and level_start < level_end:
        for index in range(level_start, level_end):
            let suffix = queue[index]
            var leading: Int64 = 1
            while leading < base:
                let candidate = leading * place + suffix
                if is_prime(candidate):
                    if end >= MAX_QUEUE:
                        return -1
                    queue[end] = candidate
                    end += 1
                    if candidate > best:
                        best = candidate
                leading += 1
        level_start = level_end
        level_end = end
        place *= base
        width += 1
    return best

@export("left_truncatable_prime_search")
fn left_truncatable_prime_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 3:
        return -1
    let base = input[0]
    let digits = input[1]
    if length != 2 or base < 3 or base > 16 or digits < 1 or digits > 10:
        return -1
    var limit: Int64 = 1
    for _ in range(Int(digits)):
        limit *= base
    if limit > MAX_LIMIT:
        return -1
    return search(base, digits)
