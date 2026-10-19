@export("check_even")
fn check_even(value: Int64) abi("C") -> Int64:
    return 1 if value % 2 == 0 else 0
