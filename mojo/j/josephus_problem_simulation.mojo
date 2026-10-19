from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("josephus_problem_simulation")
fn josephus_problem_simulation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<1 or v[0]>512 or v[1]<1:return -1
    let count=Int(v[0]);let step=v[1];var people=InlineArray[Int64,512](fill=0)
    for i in range(count):people[i]=Int64(i+1)
    var remaining=count;var current=0
    while remaining>1:
        let offset=Int((step-1)%Int64(remaining));let removed=(current+offset)%remaining
        for i in range(removed,remaining-1):people[i]=people[i+1]
        remaining-=1;current=removed%remaining
    return people[0]
