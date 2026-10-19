@export("cubes_sequence")
fn cubes_sequence(index: Int64) abi("C") -> Int64:
    if index < 0 or index > 2097151: return -1
    return index * index * index
