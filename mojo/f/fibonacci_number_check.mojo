fn fib_num_is_square(value: Int64) -> Bool:
    if value < 0: return False
    var low: Int64 = 0
    var high: Int64 = 3037000499
    while low <= high:
        let middle = low + (high - low) / 2
        let square = middle * middle
        if square == value: return True
        if square < value: low = middle + 1
        else: high = middle - 1
    return False

@export("fibonacci_number_check")
fn fibonacci_number_check(number: Int64) abi("C") -> Int64:
    if number < -1300000000 or number > 1300000000: return -1
    let v = 5 * number * number
    return 1 if fib_num_is_square(v + 4) or fib_num_is_square(v - 4) else 0
