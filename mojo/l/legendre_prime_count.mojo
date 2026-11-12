const MAX_INPUT: Int64 = 10000

fn legendre_phi(primes: InlineArray[Int64, 25], value: Int64, count: Int) -> Int64:
    if value == 0: return 0
    if count == 0: return value
    if count == 1: return value - value // 2
    let prime = primes[count - 1]
    if value < prime: return 1
    return legendre_phi(primes, value, count - 1) - legendre_phi(primes, value // prime, count - 1)

@export("legendre_prime_count")
fn legendre_prime_count(value: Int64) abi("C") -> Int64:
    if value < 0 or value > MAX_INPUT: return -1
    if value < 2: return 0
    var root: Int64 = 0
    while (root + 1) * (root + 1) <= value: root += 1
    var composite = InlineArray[Bool, 101](fill=False)
    var candidate = 2
    while candidate * candidate <= Int(root):
        if not composite[candidate]:
            var multiple = candidate * candidate
            while multiple <= Int(root):
                composite[multiple] = True
                multiple += candidate
        candidate += 1
    var primes = InlineArray[Int64, 25](fill=0)
    var count = 0
    for candidate in range(2, Int(root) + 1):
        if not composite[candidate]:
            primes[count] = Int64(candidate)
            count += 1
    return legendre_phi(primes, value, count) + Int64(count) - 1
