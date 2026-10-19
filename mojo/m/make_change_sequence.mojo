from std.collections import InlineArray

@export("make_change_sequence")
fn make_change_sequence(amount: Int64) abi("C") -> Int64:
    if amount < 0 or amount > 128: return -1
    var values = InlineArray[Int64, 129](fill=0)
    let seeds = InlineArray[Int64, 17](1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 11, 12, 15, 16, 19, 22, 25)
    for i in range(17): values[i] = seeds[i]
    for n in range(17, Int(amount) + 1):
        values[n] = values[n-2] + values[n-5] - values[n-7] + values[n-10] - values[n-12] - values[n-15] + values[n-17] + 1
    return values[Int(amount)]
