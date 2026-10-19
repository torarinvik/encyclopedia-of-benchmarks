from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_inversions")
fn count_inversions(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    if length < 2: return 0
    var source = InlineArray[Int64, 4096](0)
    var scratch = InlineArray[Int64, 4096](0)
    for i in range(length): source[i] = values[i]
    var inversions: Int64 = 0
    var width: Int64 = 1
    while width < length:
        var low: Int64 = 0
        while low < length:
            var middle = low + width
            if middle > length: middle = length
            var high = middle + width
            if high > length: high = length
            var left = low
            var right = middle
            var out = low
            while left < middle and right < high:
                if source[left] <= source[right]:
                    scratch[out] = source[left]
                    left += 1
                else:
                    scratch[out] = source[right]
                    right += 1
                    inversions += middle - left
                out += 1
            while left < middle:
                scratch[out] = source[left]
                left += 1
                out += 1
            while right < high:
                scratch[out] = source[right]
                right += 1
                out += 1
            low = high
        for i in range(length): source[i] = scratch[i]
        width *= 2
    return inversions
