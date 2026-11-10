@export("catalan_number")
def catalan_number(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 35: return -1
    var value: Int64 = 1
    var index: Int64 = 1
    while index <= n:
        var numerator = 4 * index - 2
        var denominator = index + 1
        var common = Int64((3 if denominator % 3 == 0 else 1) * (2 if denominator % 2 == 0 else 1))
        numerator /= common
        denominator /= common
        value = (value // denominator) * numerator
        index += 1
    return value
