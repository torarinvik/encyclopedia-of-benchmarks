from std.collections import List

@export("bell_numbers")
fn bell_numbers(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 25: return -1
    if n == 0: return 1
    var row = List[Int64](capacity=26)
    for _ in range(26): row.append(0)
    row[0] = 1
    for current in range(1, Int(n)):
        let previous_first = row[0]
        let previous_last = row[current - 1]
        row[0] = previous_last
        var previous_old = previous_first
        for column in range(1, current + 1):
            let old_value = row[column] if column < current else 0
            row[column] = row[column - 1] + previous_old
            previous_old = old_value
    return row[Int(n) - 1]
