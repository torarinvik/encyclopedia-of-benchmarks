fn p12s_divisor_count(value_in:Int64)->Int64:
    var value=value_in;var count=Int64(1);var factor=Int64(2)
    while factor<=value//factor:
        var multiplicity=Int64(0)
        while value%factor==0:value//=factor;multiplicity+=1
        if multiplicity!=0:count*=multiplicity+1
        factor+=1
    if value>1:count*=2
    return count
@export("problem12_sol1")
fn problem12_sol1(threshold:Int64) abi("C")->Int64:
    if threshold!=500:return -1
    var index=Int64(1);var triangular=Int64(1)
    while True:
        index+=1;triangular+=index
        if p12s_divisor_count(triangular)>500:return triangular
    return -1
