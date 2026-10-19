@export("not_gate")
fn not_gate(x:Int64) abi("C")->Int64:
    if x!=0 and x!=1:return -1
    return 1 if x==0 else 0
