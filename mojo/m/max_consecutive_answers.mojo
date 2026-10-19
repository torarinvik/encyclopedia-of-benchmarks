from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

fn mca_longest(v:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,k:Int,target:Int64)->Int:
    var left=0;var opposite=0;var best=0
    for right in range(count):
        if v[right+1]!=target:opposite+=1
        while opposite>k:
            if v[left+1]!=target:opposite-=1
            left+=1
        let window=right-left+1
        if window>best:best=window
    return best

@export("max_consecutive_answers")
fn max_consecutive_answers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1025:return -1
    let count=Int(n)-1
    if v[0]<0 or v[0]>count:return -1
    for i in range(count):if v[i+1]!=0 and v[i+1]!=1:return -1
    return Int64(max(mca_longest(v,count,Int(v[0]),1),mca_longest(v,count,Int(v[0]),0)))
