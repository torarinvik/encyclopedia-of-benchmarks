from std.memory import stack_allocation

@export("bell_numbers")
def bell_numbers(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 25: return -1
    if n == 0: return 1
    var row = stack_allocation[26, Int64]()
    for index in range(26): row[index] = 0
    row[0] = 1
    for current in range(1, Int(n)):
        var previous_first = row[0]
        var previous_last = row[current - 1]
        row[0] = previous_last
        var previous_old = previous_first
        for column in range(1, current + 1):
            var old_value = row[column] if column < current else 0
            row[column] = row[column - 1] + previous_old
            previous_old = old_value
    return row[Int(n) - 1]
