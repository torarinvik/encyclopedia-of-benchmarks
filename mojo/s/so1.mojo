@export("so1")
fn so1(threshold:Int64) abi("C")->Int64:
    if threshold< -2147483648 or threshold>1000000000:return -1
    var first=Int64(1);var second=Int64(2);var total=Int64(0)
    while second<=threshold:
        if second%2==0:total+=second
        let temporary=first;first=second;second=temporary+first
    return total
