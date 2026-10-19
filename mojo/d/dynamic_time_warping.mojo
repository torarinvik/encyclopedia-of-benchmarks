from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("dynamic_time_warping")
fn dynamic_time_warping(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>35:return -1.0e300
    let av=values[0];let bv=values[1];let bandv=values[2]
    if av<1 or av>16 or bv<1 or bv>16:return -1.0e300
    let n=Int(av);let m=Int(bv);let diff=n-m if n>m else m-n
    if bandv<diff or bandv>16 or length!=c_size_t(3+n+m):return -1.0e300
    for i in range(n+m):if values[3+i]< -1000 or values[3+i]>1000:return -1.0e300
    let band=Int(bandv);var previous=List[Float64](length=17,fill=1.0e300);var current=List[Float64](length=17,fill=1.0e300);previous[0]=0.0
    for i in range(1,n+1):
        for j in range(17):current[j]=1.0e300
        let start=i-band if i>band else 1;let finish=i+band if i+band<m else m
        for j in range(start,finish+1):
            let delta=values[2+i]-values[2+n+j];let cost=Float64(delta if delta>=0 else -delta)
            var best=previous[j]
            if current[j-1]<best:best=current[j-1]
            if previous[j-1]<best:best=previous[j-1]
            current[j]=cost+best
        let temp=previous;previous=current;current=temp
    return previous[m]
