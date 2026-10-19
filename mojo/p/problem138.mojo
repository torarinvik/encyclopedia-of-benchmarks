@export("problem138")
fn problem138(count:Int64) abi("C")->Int64:
    if count>14:return -1
    if count<=0:return 0
    var m=Int64(2);var l=Int64(1);var total=Int64(0)
    for _ in range(Int(count)):
        let next_m=9*m+20*l;let next_l=4*m+9*l;m=next_m;l=next_l;total+=l
    return total
