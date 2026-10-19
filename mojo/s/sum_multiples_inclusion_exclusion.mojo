@export("sum_multiples_inclusion_exclusion")
fn sum_multiples_inclusion_exclusion(limit: Int64) abi("C") -> Int64:
    if limit < 1 or limit > 100000: return -1
    let last = limit - 1
    let a = last / 3
    let b = last / 5
    let c = last / 15
    return 3*a*(a+1)/2 + 5*b*(b+1)/2 - 15*c*(c+1)/2
