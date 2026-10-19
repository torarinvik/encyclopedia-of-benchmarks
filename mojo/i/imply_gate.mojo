@export("imply_gate")
fn imply_gate(left:UInt64,right:UInt64) abi("C")->Int64:
    if left>1 or right>1:return -1
    return 1 if left==0 or right==1 else 0
