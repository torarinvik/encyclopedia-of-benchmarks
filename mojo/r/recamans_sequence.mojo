@export("recamans_sequence")
fn recamans_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>32:return -1
    var seen=InlineArray[Int64,529](fill=0);seen[0]=1;var previous:Int64=0
    for step in range(1,Int(index)+1):
        var candidate=previous-Int64(step)
        if candidate<0 or seen[Int(candidate)]!=0:candidate=previous+Int64(step)
        seen[Int(candidate)]=1;previous=candidate
    return previous
