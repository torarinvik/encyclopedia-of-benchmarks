@export("all_threes_sequence")
fn all_threes_sequence(index: Int64) abi("C") -> Int64:
    if index < 0:
        return -1
    return 3
