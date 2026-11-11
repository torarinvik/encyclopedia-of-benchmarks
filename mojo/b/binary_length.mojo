from std.math import floor, log2

@export("binary_length")
def binary_length(value: Int64) abi("C") -> Int64:
    if value <= 0 or value > 2_147_483_647:
        return -1
    return Int64(floor(log2(Float64(value)))) + 1
