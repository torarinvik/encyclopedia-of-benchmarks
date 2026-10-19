@export("abundant_number")
fn abundant_number(n: Int64) abi("C") -> Int64:
    if n < 1 or n > 100000000:
        return -1
    var sum: Int64 = 1
    var divisor: Int64 = 2
    while divisor <= n / divisor:
        if n % divisor == 0:
            sum += divisor
            let partner = n / divisor
            if partner != divisor:
                sum += partner
            if sum > n:
                return 1
        divisor += 1
    return 0
