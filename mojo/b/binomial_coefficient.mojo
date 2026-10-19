from std.collections import List

@export("binomial_coefficient")
fn binomial_coefficient(n: UInt64, k: UInt64) abi("C") -> Int64:
    if n > 66: return -1
    if k > n: return 0
    var row = List[Int64](capacity=67)
    for _ in range(67): row.append(0)
    row[0] = 1
    for i in range(1, Int(n) + 1):
        var j = min(i, Int(k))
        while j > 0:
            row[j] += row[j - 1]
            j -= 1
    return row[Int(k)]
