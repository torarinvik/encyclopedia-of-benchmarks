from std.memory import stack_allocation

@export("keith_number")
def keith_number(number: Int64) abi("C") -> Int64:
    if number < 10 or number > 999999:
        return -1
    var reversed = stack_allocation[6, Int64]()
    var digits = stack_allocation[6, Int64]()
    for i in range(6):
        reversed[i] = 0
        digits[i] = 0
    var value = number
    var digit_count = 0
    while value > 0:
        reversed[digit_count] = value % 10
        digit_count += 1
        value //= 10

    var total: Int64 = 0
    for i in range(digit_count):
        digits[i] = reversed[digit_count - 1 - i]
        total += digits[i]

    var oldest = 0
    while True:
        var next = total
        if next >= number:
            return 1 if next == number else 0
        total = total - digits[oldest] + next
        digits[oldest] = next
        oldest = (oldest + 1) % digit_count
    return 0
