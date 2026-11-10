from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("smallest_divisor")
def smallest_divisor(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if input == None or length < 2 or length > 257:
        return -1
    var values = input.value()
    var count = UInt64(length - 1)
    var threshold = UInt64(values[unsafe_offset=0])
    if threshold < count or threshold > 1_000_000:
        return -1

    var maximum: UInt64 = 0
    var total: UInt64 = 0
    for index in range(1, Int(length)):
        var value = UInt64(values[unsafe_offset=index])
        if value == 0 or value > 1_000_000:
            return -1
        maximum = max(maximum, value)
        total += value
    if threshold == count:
        return Int64(maximum)

    var low = (total - 1) // threshold + 1
    var upper_bound = (total - count) // (threshold - count + 1) + 1
    var high = min(maximum, upper_bound)
    while low < high:
        var middle = low + ((high - low) >> 1)
        var rounded_sum = count
        if count <= 4:
            for index in range(1, Int(length)):
                var value = UInt32(values[unsafe_offset=index])
                rounded_sum += UInt64((value - 1) // UInt32(middle))
        else:
            var reciprocal = (UInt64(1_099_511_627_775) // middle) + 1
            for index in range(1, Int(length)):
                var value = UInt64(values[unsafe_offset=index])
                rounded_sum += ((value - 1) * reciprocal) >> 40
        if rounded_sum <= threshold:
            high = middle
        else:
            low = middle + 1
    return Int64(low)
