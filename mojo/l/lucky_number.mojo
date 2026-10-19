@export("lucky_number")
fn lucky_number(number:Int64) abi("C")->Int64:
    if number<1 or number>1000000:return -1
    var counter:Int64=2;var position=number
    while counter<=position:
        if position%counter==0:return 0
        position-=position/counter;counter+=1
    return 1
