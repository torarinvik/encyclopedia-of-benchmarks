from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("partition_problem")
fn partition_problem(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>16:return -1
    var total=0
    for i in range(Int(n)):if v[i]<0 or v[i]>256 or total>1024-Int(v[i]):return -1;total+=Int(v[i])
    if total%2!=0:return 0
    let target=total/2;var reach=InlineArray[Int64,1025](fill=0);reach[0]=1
    for i in range(Int(n)):
        let value=Int(v[i]);if value>target:continue
        var s=target
        while True:if reach[s-value]!=0:reach[s]=1;if s==value:break;s-=1
    return reach[target]
