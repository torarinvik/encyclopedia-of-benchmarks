@export("nand_gate")
fn nand_gate(a:Int64,b:Int64) abi("C")->Int64:
    if (a!=0 and a!=1) or (b!=0 and b!=1):return -1
    return 1 if a==0 or b==0 else 0
