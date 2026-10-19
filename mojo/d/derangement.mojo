@export("derangement")
fn derangement(n:Int64) abi("C")->Int64:
    if n<0 or n>20:return -1
    if n<2:return 0
    if n==2:return 1
    var previous:Int64=1;var previous_previous:Int64=0
    for i in range(3,Int(n)+1):
        let current=Int64(i-1)*(previous+previous_previous)
        previous_previous=previous;previous=current
    return previous
