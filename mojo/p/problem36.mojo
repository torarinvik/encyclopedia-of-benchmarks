fn p36_pal(value_in:Int64,base:Int64)->Bool:
    var value=value_in;var rev=Int64(0)
    while value>0:rev=rev*base+value%base;value//=base
    return rev==value_in
@export("problem36")
fn problem36(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>1000000:return -1
    var total=Int64(0)
    for value in range(1,Int(limit)):
        if p36_pal(Int64(value),10) and p36_pal(Int64(value),2):total+=Int64(value)
    return total
