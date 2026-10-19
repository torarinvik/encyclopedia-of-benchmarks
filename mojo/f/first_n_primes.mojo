from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List
from std.collections import InlineArray

fn prime_is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var d: Int64 = 2
    while d <= value / d:
        if value % d == 0: return False
        d += 1
    return True

@export("first_n_primes")
fn first_n_primes(count: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if count < 0 or count > 20: return -1
    var staged = List[UInt8](capacity=64)
    var found: Int64 = 0
    var candidate: Int64 = 2
    while found < count:
        if prime_is_prime(candidate):
            if found > 0: staged.append(UInt8(44))
            var digits = InlineArray[UInt8, 3](fill=0)
            var nd = 0
            var rest = candidate
            while rest > 0:
                digits[nd] = UInt8(48 + rest % 10); nd += 1; rest /= 10
            while nd > 0:
                nd -= 1; staged.append(digits[nd])
            found += 1
        candidate += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
