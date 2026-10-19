@export("armstrong")
fn armstrong(n: Int64) abi("C") -> Int64:
    if n < -2147483648 or n > 2147483647: return -1
    if n < 0: return 0
    if n == 0: return 1
    var digits: Int64 = 0
    var remaining = n
    while remaining > 0:
        digits += 1
        remaining /= 10
    var total: Int64 = 0
    remaining = n
    while remaining > 0:
        let digit = remaining % 10
        var power: Int64 = 1
        for e in range(Int(digits)): power *= digit
        total += power
        remaining /= 10
    if total == n: return 1
    return 0
