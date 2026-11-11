@export("liouville_lambda")
def liouville_lambda(input: Int64) abi("C") -> Int64:
    if input < 1 or input > 2147483647:
        return -1
    var remaining = UInt64(input)
    var sign: Int64 = 1
    var factor = UInt64(2)
    while factor <= remaining // factor:
        while remaining % factor == 0:
            remaining //= factor
            sign = -sign
        if factor == 2:
            factor = 3
        else:
            factor += 2
    if remaining > 1:
        sign = -sign
    return sign
