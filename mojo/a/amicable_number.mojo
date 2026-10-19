@export("amicable_number")
fn amicable_number(left: Int64, right: Int64) abi("C") -> Int64:
    if left < 1 or left > 1000000000 or right < 1 or right > 1000000000:
        return -1
    if left == right:
        return 0
    var sum_left: Int64 = 0
    if left > 1:
        sum_left = 1
        var d: Int64 = 2
        while d <= left / d:
            if left % d == 0:
                sum_left += d
                let p = left / d
                if p != d: sum_left += p
            d += 1
    var sum_right: Int64 = 0
    if right > 1:
        sum_right = 1
        var d: Int64 = 2
        while d <= right / d:
            if right % d == 0:
                sum_right += d
                let p = right / d
                if p != d: sum_right += p
            d += 1
    if sum_left == right and sum_right == left:
        return 1
    return 0
