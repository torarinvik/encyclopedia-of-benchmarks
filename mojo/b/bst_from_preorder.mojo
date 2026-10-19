from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bst_pre_valid(values:List[Int64],start:Int,end:Int,lower:Int64,upper:Int64)->Bool:
    if start>=end:return True
    let root=values[start]
    if root<=lower or root>=upper:return False
    var split=start+1
    while split<end and values[split]<root:split+=1
    for i in range(split,end):
        if values[i]<=root:return False
    return bst_pre_valid(values,start+1,split,lower,root) and bst_pre_valid(values,split,end,root,upper)

fn bst_pre_emit(values:List[Int64],start:Int,end:Int,staged:List[UInt8]):
    if start>=end:staged.append(UInt8(0));return
    let root=values[start];var split=start+1
    while split<end and values[split]<root:split+=1
    staged.append(UInt8(1));let bits=UInt32(root)
    for b in range(4):staged.append(UInt8((bits>>UInt(8*b))&255))
    bst_pre_emit(values,start+1,split,staged);bst_pre_emit(values,split,end,staged)

@export("bst_from_preorder")
fn bst_from_preorder(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>15:return -1
    var values=List[Int64](capacity=15)
    for i in range(Int(length)):
        let v=input[i]
        if v< -2147483648 or v>2147483647:return -1
        values.append(v)
    if not bst_pre_valid(values,0,len(values),-2147483649,2147483648):return -1
    var staged=List[UInt8](capacity=6*len(values)+1)
    bst_pre_emit(values,0,len(values),staged)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(staged)):return -2
    for i in range(len(staged)):output[i]=staged[i]
    return Int64(len(values))
