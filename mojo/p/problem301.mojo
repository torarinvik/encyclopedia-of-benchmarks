@export("problem301")
fn problem301(exponent:Int64) abi("C")->Int64:
    if exponent<0 or exponent>30:return -1
    var previous=Int64(0);var current=Int64(1)
    for _ in range(Int(exponent+2)):
        let next=previous+current;previous=current;current=next
    return previous-(exponent%2)
