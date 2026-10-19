fn p47_distinct_factors(value_in:Int64)->Int:
    var value=value_in;var count=0;var factor=Int64(2)
    while factor<=value//factor:
        if value%factor==0:
            count+=1
            while value%factor==0:value//=factor
        factor+=1
    if value>1:count+=1
    return count
@export("problem47")
fn problem47(n:Int64) abi("C")->Int64:
    if n<1 or n>4:return -1
    var run=0;var value=Int64(2)
    while True:
        if p47_distinct_factors(value)==Int(n):run+=1
        else:run=0
        if run==Int(n):return value-n+1
        value+=1
    return -1
