def is_candidate_prime(value: UInt32) -> Bool:
    if value % 3 == 0:
        return False
    var divisor: UInt32 = 5
    while divisor * divisor <= value:
        if value % divisor == 0 or value % (divisor + 2) == 0:
            return False
        divisor += 6
    return True

@export("next_prime_number")
def next_prime_number(value: Int64) abi("C") -> Int64:
    if value < -4096 or value > 4096:
        return -1
    if value < 2:
        return 2
    if value == 2:
        return 3
    var candidate = UInt32(value + 1) | UInt32(1)
    while not is_candidate_prime(candidate):
        candidate += 2
    return Int64(candidate)
