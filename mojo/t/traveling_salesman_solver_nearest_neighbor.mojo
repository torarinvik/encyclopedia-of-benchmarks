from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("traveling_salesman_solver_nearest_neighbor")
fn traveling_salesman_solver_nearest_neighbor(a:UnsafePointer[Int64,ImmutAnyOrigin],len:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or len<4 or len>68:return -1.0e300
    let selector=a[0];let nv=a[1];let start0=a[2]
    if nv<1 or nv>8 or selector<0 or selector>nv+1 or start0<0 or start0>=nv or len!=c_size_t(3+nv*nv):return -1.0e300
    let n=Int(nv);for i in range(n*n):if a[i+3]<0 or a[i+3]>1000:return -1.0e300
    var route=InlineArray[Int,9]();var visited=InlineArray[Bool,8]();let start=Int(start0);var current=start;route[0]=start;visited[start]=True;var total:Int64=0
    for step in range(1,n):
        var min_distance:Int64=1001;var next=8
        for city in range(n):
            if not visited[city]:
                let d=a[3+current*n+city]
                if d<min_distance:min_distance=d;next=city
        if next==8:return -1.0e300
        route[step]=next;visited[next]=True;total+=min_distance;current=next
    total+=a[3+current*n+start];route[n]=start
    if selector==0:return Float64(total)
    return Float64(route[Int(selector-1)])
