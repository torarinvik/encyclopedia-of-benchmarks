@export("sum_multiples_inclusion_exclusion")
def sum_multiples_inclusion_exclusion(limit: Int64) abi("C") -> Int64:
    if limit < 1 or limit > 100000: return -1
    var last = limit - 1
    var a = last // 3
    var b = last // 5
    var c = last // 15
    return 3*a*(a+1)//2 + 5*b*(b+1)//2 - 15*c*(c+1)//2
