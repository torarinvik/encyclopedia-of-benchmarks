from std.memory import stack_allocation

def source_sieve_flag(value: Int64) -> Bool:
    if value < 2:
        return True
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True

@export("sphenic_number")
def sphenic_number(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 1000:
        return -1
    if value < 2:
        return 0
    var first = stack_allocation[3, Int64]()
    for i in range(3):
        first[i] = 0
    var count = 0
    var divisor: Int64 = 1
    while divisor <= value // 2:
        if value % divisor == 0:
            if count == 7:
                return 0
            if count < 3:
                first[count] = divisor
            count += 1
        divisor += 1
    return 1 if count == 7 and source_sieve_flag(first[0]) and source_sieve_flag(first[1]) and source_sieve_flag(first[2]) else 0
