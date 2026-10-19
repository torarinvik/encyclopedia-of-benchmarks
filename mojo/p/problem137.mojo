@export("problem137")
fn problem137(n:Int64) abi("C")->Int64:
    if n<1 or n>23:return -1
    var previous=Int64(1);var current=Int64(1)
    for index in range(Int(2*n-1)):
        let next=previous+current;previous=current;current=next
    return previous*current
