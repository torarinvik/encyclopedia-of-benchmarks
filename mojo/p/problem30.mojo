fn p30_fifth_sum(value_in:Int64)->Int64:
    var v=value_in;var sum=Int64(0)
    while v>0:
        let d=v%10;sum+=d*d*d*d*d;v//=10
    return sum
@export("problem30")
fn problem30(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var sum=Int64(0)
    for n in range(1000,1000000):if p30_fifth_sum(Int64(n))==Int64(n):sum+=Int64(n)
    return sum
