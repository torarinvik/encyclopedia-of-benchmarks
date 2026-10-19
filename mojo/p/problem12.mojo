fn p12_divisors(value_in:Int64)->Int64:
    var value=value_in;var count=Int64(1);var factor=Int64(2)
    while factor<=value//factor:
        if value%factor==0:
            var exp=Int64(0)
            while value%factor==0:value//=factor;exp+=1
            count*=exp+1
        factor+=1
    if value>1:count*=2
    return count
@export("problem12")
fn problem12(minimum_divisors:Int64) abi("C")->Int64:
    if minimum_divisors<0 or minimum_divisors>500:return -1
    for index in range(1,12376):
        var left=Int64(index);var right=Int64(index+1)
        if index%2==0:left//=2
        else:right//=2
        if p12_divisors(left)*p12_divisors(right)>=minimum_divisors:return Int64(index*(index+1)//2)
    return -1
