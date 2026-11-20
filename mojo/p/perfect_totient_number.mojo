@export("perfect_totient_number")
fn perfect_totient_number(n: Int64) abi("C") -> Int64:
    if n < 3 or n > 65535:
        return -1

    var value = n
    var total: Int64 = 0
    while value > 1:
        var result = value
        var remaining = value
        var factor: Int64 = 2
        while factor <= remaining // factor:
            if remaining % factor == 0:
                while remaining % factor == 0:
                    remaining //= factor
                result -= result // factor
            factor += 1
        if remaining > 1:
            result -= result // remaining
        value = result
        total += value

    return 1 if total == n else 0
