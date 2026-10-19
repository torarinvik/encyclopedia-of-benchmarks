@export("van_ecks_sequence")
fn van_ecks_sequence(pos:Int64) abi("C")->Int64:
    if pos<1 or pos>16:return -1
    var last=InlineArray[Int64,17](fill=0);var previous:Int64=0
    for current in range(2,Int(pos)+1):
        let next=0 if last[Int(previous)]==0 else Int64(current)-last[Int(previous)]
        last[Int(previous)]=Int64(current);previous=next
    return previous
