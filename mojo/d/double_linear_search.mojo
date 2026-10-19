from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("double_linear_search")
fn double_linear_search(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>100002:return -1
    let target=values[0];let countv=values[1]
    if target< -9007199254740991 or target>9007199254740991 or countv<0 or countv>100000 or length!=c_size_t(countv+2):return -1
    let count=Int(countv)
    for i in range(count):if values[i+2]< -9007199254740991 or values[i+2]>9007199254740991:return -1
    var left=0;var right=count
    while left<right:
        if values[left+2]==target:return Int64(left)
        if values[right+1]==target:return Int64(right-1)
        left+=1;right-=1
    return -1
