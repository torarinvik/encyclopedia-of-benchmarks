@export("buzz_number")
fn buzz_number(value: Int64) abi("C") -> Int64:
    if value % 7 == 0: return 1
    if value >= 0 and value % 10 == 7: return 1
    return 0
