from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("validate_sudoku_board")
fn validate_sudoku_board(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=81:return -1
    for i in range(81):if v[i]!=46 and (v[i]<49 or v[i]>57):return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<1:return -2
    var rows=InlineArray[UInt16,9](fill=0);var cols=InlineArray[UInt16,9](fill=0);var boxes=InlineArray[UInt16,9](fill=0);var valid=True
    for i in range(81):
        let x=v[i]
        if x==46:continue
        let r=i/9;let c=i%9;let bx=(r/3)*3+c/3;let bit=UInt16(1)<<Int(x-48)
        if (rows[r]&bit)!=0 or (cols[c]&bit)!=0 or (boxes[bx]&bit)!=0:valid=False
        rows[r]=rows[r]|bit;cols[c]=cols[c]|bit;boxes[bx]=boxes[bx]|bit
    o[0]=1 if valid else 0
    return 1
