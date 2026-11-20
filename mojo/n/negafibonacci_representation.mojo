from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_INDEX = 17
const VALUE_LIMIT: Int64 = 1000

fn nn_encode(value: Int64, inout output: InlineArray[UInt8, 17]) -> Int:
    var fib = InlineArray[Int64, 18](fill=0)
    var weight = InlineArray[Int64, 18](fill=0)
    var low = InlineArray[Int64, 18](fill=0)
    var high = InlineArray[Int64, 18](fill=0)
    var digit = InlineArray[Bool, 18](fill=False)
    fib[1] = 1
    fib[2] = 1
    for k in range(3, MAX_INDEX + 1): fib[k] = fib[k - 1] + fib[k - 2]
    for k in range(1, MAX_INDEX + 1): weight[k] = fib[k] if k % 2 == 1 else -fib[k]
    for k in range(1, MAX_INDEX + 1):
        let suffix_low = 0 if k == 1 else low[k - 2]
        let suffix_high = 0 if k == 1 else high[k - 2]
        let with_low = weight[k] + suffix_low
        let with_high = weight[k] + suffix_high
        low[k] = low[k - 1] if low[k - 1] < with_low else with_low
        high[k] = high[k - 1] if high[k - 1] > with_high else with_high
    var remaining = value
    var selected_above = False
    for k in range(MAX_INDEX, 0, -1):
        var choose = False
        if not selected_above:
            let suffix_low = 0 if k == 1 else low[k - 2]
            let suffix_high = 0 if k == 1 else high[k - 2]
            let candidate = remaining - weight[k]
            choose = suffix_low <= candidate and candidate <= suffix_high
        if choose:
            digit[k] = True
            remaining -= weight[k]
        selected_above = choose
    var highest = MAX_INDEX
    while highest > 1 and not digit[highest]: highest -= 1
    var written = 0
    for k in range(highest, 0, -1):
        output[written] = UInt8(49) if digit[k] else UInt8(48)
        written += 1
    return written

fn negafibonacci_representation_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) -> Int64:
    if input.is_null() or length != 1: return -1
    let value = input[0]
    if value < -VALUE_LIMIT or value > VALUE_LIMIT: return -1
    var staged = InlineArray[UInt8, 17](fill=0)
    let required = nn_encode(value, inout staged)
    if output.is_null() or output_capacity < c_size_t(required): return -2
    for index in range(required): output[index] = staged[index]
    return Int64(required)

@export("negafibonacci_representation")
fn negafibonacci_representation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    return negafibonacci_representation_impl(input, length, output, output_capacity)
