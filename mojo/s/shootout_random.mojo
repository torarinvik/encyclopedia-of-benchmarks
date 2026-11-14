from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("shootout_random")
fn shootout_random(call_count: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if call_count < 1 or call_count > 1_000_000: return -1
    var state = Int64(42)
    for _ in range(Int(call_count)):
        state = (state * 3877 + 29573) % 139968
    let scaled = (100 * state * 1_000_000_000 + 139968 // 2) // 139968
    var whole = scaled // 1_000_000_000
    var fraction = scaled % 1_000_000_000
    var digits = List[UInt8]()
    while True:
        digits.append(UInt8(48 + whole % 10))
        whole //= 10
        if whole == 0: break
    var staged = List[UInt8]()
    for index in range(len(digits)):
        staged.append(digits[len(digits) - 1 - index])
    staged.append(46)
    var place = Int64(100_000_000)
    while place > 0:
        staged.append(UInt8(48 + fraction // place))
        fraction %= place
        place //= 10
    staged.append(10)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(staged)): return -2
    for index in range(len(staged)):
        output[index] = staged[index]
    return Int64(len(staged))
