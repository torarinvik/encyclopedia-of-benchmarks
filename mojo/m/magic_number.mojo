@export("magic_number")
fn magic_number(n: Int64) abi("C") -> Int64:
    return 1 if n > 0 and n % 9 == 1 else 0
