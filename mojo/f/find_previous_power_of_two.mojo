@export("find_previous_power_of_two")
fn find_previous_power_of_two(number: Int64) abi("C") -> Int64:
    if number < 0 or number > 2147483647: return -1
    if number == 0: return 0
    var power: Int64 = 1
    while power <= number: power <<= 1
    return (power >> 1) if number > 1 else 1
