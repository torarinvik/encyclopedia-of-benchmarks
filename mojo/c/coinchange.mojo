from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("coinchange")
fn coinchange(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 10: return -1
    let amount = values[0]
    let count = values[1]
    if amount < 1 or amount > 30 or count < 0 or count > 8 or length != count + 2: return -1
    for i in range(count):
        if values[2 + i] < 1 or values[2 + i] > 30: return -1
    var combinations = InlineArray[Int64, 30](0)
    combinations[0] = 1
    for ci in range(count):
        let coin = values[2 + ci]
        for subtotal in range(coin, amount):
            combinations[subtotal] += combinations[subtotal - coin]
    return combinations[amount - 1]
