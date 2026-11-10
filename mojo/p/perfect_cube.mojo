@export("perfect_cube")
def perfect_cube(value: Int64) abi("C") -> Int64:
    if value < -1000000000000 or value > 1000000000000:
        return -1
    var target = UInt64(-value if value < 0 else value)
    if target < 2:
        return 1
    var root_limit = UInt64(10000)
    if target <= 1000:
        root_limit = 10
    elif target <= 1000000:
        root_limit = 100
    elif target <= 1000000000:
        root_limit = 1000
    var low: UInt64 = 1
    var high = min(target / 2, root_limit)
    while low <= high:
        var middle = (low + high) >> 1
        var cube = middle * middle * middle
        if cube == target:
            return 1
        if cube < target:
            if middle == high:
                return 0
            low = middle + 1
        else:
            if middle == low:
                return 0
            high = middle - 1
    return 0
