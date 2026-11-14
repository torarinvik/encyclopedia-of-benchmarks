from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("space_saving_frequent_items")
fn space_saving_frequent_items(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 67: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 64: return -1
    let k = Int(input[0])
    let n = Int(input[1])
    if length != c_size_t(2+n): return -1
    for i in range(n):
        if input[2+i] < -1000 or input[2+i] > 1000: return -1
    var items = InlineArray[Int64, 8](fill=0)
    var estimates = InlineArray[Int64, 8](fill=0)
    var errors = InlineArray[Int64, 8](fill=0)
    var used = 0
    for i in range(n):
        let item = input[2+i]
        var found = used
        for j in range(used):
            if items[j] == item:
                found = j
                break
        if found < used:
            estimates[found] += 1
        elif used < k:
            items[used] = item
            estimates[used] = 1
            errors[used] = 0
            used += 1
        else:
            var victim = 0
            for j in range(1, used):
                if estimates[j] < estimates[victim] or (estimates[j] == estimates[victim] and items[j] < items[victim]):
                    victim = j
            let minimum = estimates[victim]
            items[victim] = item
            estimates[victim] = minimum+1
            errors[victim] = minimum
    var sort_index = 1
    while sort_index < used:
        var j = sort_index
        while j > 0 and items[j] < items[j-1]:
            let item = items[j]
            let estimate = estimates[j]
            let error = errors[j]
            items[j] = items[j-1]
            estimates[j] = estimates[j-1]
            errors[j] = errors[j-1]
            items[j-1] = item
            estimates[j-1] = estimate
            errors[j-1] = error
            j -= 1
        sort_index += 1
    let byte_count = 8*(1+3*used)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    var fields = InlineArray[Int64, 25](fill=0)
    fields[0] = Int64(used)
    for i in range(used):
        fields[1+3*i] = items[i]
        fields[2+3*i] = estimates[i]
        fields[3+3*i] = errors[i]
    var staged = InlineArray[UInt8, 200](fill=0)
    for i in range(1+3*used):
        let bits = bitcast[UInt64](fields[i])
        for b in range(8): staged[8*i+b] = UInt8((bits >> UInt(8*b)) & 255)
    for i in range(byte_count): output[i] = staged[i]
    return Int64(byte_count)
