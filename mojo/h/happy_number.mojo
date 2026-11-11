def digit_square_sum(n: Int64) -> Int64:
    var value = n
    var total: Int64 = 0
    while value > 0:
        var digit = value % 10
        total += digit * digit
        value /= 10
    return total

@export("happy_number")
def happy_number(n: Int64) abi("C") -> Int64:
    if n <= 0:
        return -1
    var slow = digit_square_sum(n)
    var fast = digit_square_sum(digit_square_sum(n))
    while slow != fast:
        slow = digit_square_sum(slow)
        fast = digit_square_sum(digit_square_sum(fast))
    if slow == 1:
        return 1
    return 0
