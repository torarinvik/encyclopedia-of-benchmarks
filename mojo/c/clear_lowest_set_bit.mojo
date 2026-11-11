@export("clear_lowest_set_bit")
def clear_lowest_set_bit(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 2147483647: return -1
    return value & (value - 1)
