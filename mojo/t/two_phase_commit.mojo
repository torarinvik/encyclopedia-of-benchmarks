from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("two_phase_commit")
fn two_phase_commit(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>68:return -1
    let count=a[0];let timeout=a[1];let start=a[2];let now=a[3]
    if count<1 or count>64 or n!=c_size_t(count+4) or timeout<=0 or start<0 or now<start:return -1
    var received:Int64=0;var commits:Int64=0;var aborted=false
    for i in range(Int(count)):
        let vote=a[i+4]
        if vote<0 or vote>2:return -1
        if vote!=2:received+=1;if vote==0:commits+=1;else:aborted=true
    var state:Int64=1
    if received==count:state=2 if not aborted else 3
    let timed:Int64=1 if now-start>timeout else 0
    return (((state*65+received)*65+commits)*2+timed)
