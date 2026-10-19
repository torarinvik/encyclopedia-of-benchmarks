@export("fermat_numbers_sequence")
fn fermat_numbers_sequence(index: Int64) abi("C") -> Int64:
    if index < 0 or index > 5: return -1
    var value: Int64 = 2
    for i in range(index): value *= value
    return value + 1
