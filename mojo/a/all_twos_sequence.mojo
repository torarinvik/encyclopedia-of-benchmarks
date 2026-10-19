@export("all_twos_sequence")
fn all_twos_sequence(index: Int64) abi("C") -> Int64:
    if index < 0:
        return -1
    return 2
