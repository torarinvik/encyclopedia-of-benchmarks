@export("perfect_square")
def perfect_square(input: Int64) abi("C") -> Int64:
    if input < 0:
        return 0
    if input < 2:
        return 1
    var number = UInt64(input)
    if ((UInt64(0x0213) >> (number & 15)) & 1) == 0:
        return 0
    var low: UInt64 = 1
    var root_limit = UInt64(65535) if number <= 0xffffffff else UInt64(3037000499)
    var high = min(number / 2, root_limit)
    while low <= high:
        var middle = (low + high) >> 1
        var square = middle * middle
        if square == number:
            return 1
        if square < number:
            low = middle + 1
        else:
            high = middle - 1
    return 0
