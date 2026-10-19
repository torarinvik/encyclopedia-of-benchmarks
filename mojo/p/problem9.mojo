@export("problem9")
fn problem9(total:Int64) abi("C")->Int64:
    if total<3 or total>1000:return -1
    for a in range(1,Int(total//3+1)):
        for b in range(a+1,Int((total-Int64(a))//2+1)):
            let c=total-Int64(a)-Int64(b)
            if Int64(a*a)+Int64(b*b)==c*c:return Int64(a)*Int64(b)*c
    return -1
