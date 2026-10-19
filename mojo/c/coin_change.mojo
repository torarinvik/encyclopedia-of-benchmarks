from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("coin_change")
fn coin_change(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let amount = values[0]
    let count = values[1]
    if amount < 0 or amount > 512 or count < 0 or count > 128 or length != 2 + count: return -1
    for i in range(count):
        if values[2 + i] < 1 or values[2 + i] > 4096: return -1
    var minimum = InlineArray[Int64, 513](0)
    for current in range(1, amount + 1):
        var best: Int64 = 513
        for ci in range(count):
            let coin = values[2 + ci]
            if coin <= current and minimum[current - coin] < 513 and minimum[current - coin] + 1 < best:
                best = minimum[current - coin] + 1
        minimum[current] = best
    return minimum[amount] if minimum[amount] < 513 else -1
