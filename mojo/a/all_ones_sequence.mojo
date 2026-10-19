@export("all_ones_sequence")
fn all_ones_sequence(index: Int64) abi("C") -> Int64:
    if index < 0:
        return -1
    return 1
