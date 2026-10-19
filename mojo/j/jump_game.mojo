from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("jump_game")
fn jump_game(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1025 or v[0]<1 or v[0]>1024 or n!=c_size_t(v[0]+1):return -2
    let count=Int(v[0])
    for i in range(count):if v[i+1]<0 or v[i+1]>1000000:return -2
    var last=count-1
    for rev in range(count):
        let i=count-1-rev
        if i+Int(v[i+1])>=last:last=i
    return 1 if last==0 else 0
