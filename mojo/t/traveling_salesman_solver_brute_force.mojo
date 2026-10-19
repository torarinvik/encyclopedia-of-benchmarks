from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tspbf_visit(m:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,pos:Int,inout used:InlineArray[Bool,8],inout order:InlineArray[Int,7],inout best:Int64,inout route:InlineArray[Int,9]):
    if pos==n-1:
        var dist:Int64=0;var prev=0
        for i in range(n-1):let city=order[i];dist+=m[prev*n+city];prev=city
        dist+=m[prev*n]
        if dist<best:
            best=dist;route[0]=0
            for i in range(n-1):route[i+1]=order[i]
            route[n]=0
        return
    for city in range(1,n):
        if not used[city]:
            used[city]=True;order[pos]=city;tspbf_visit(m,n,pos+1,used,order,best,route);used[city]=False
@export("traveling_salesman_solver_brute_force")
fn traveling_salesman_solver_brute_force(a:UnsafePointer[Int64,ImmutAnyOrigin],len:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or len<2 or len>67:return -1.0e300
    let selector=a[0];let nv=a[1]
    if nv<2 or nv>8 or selector<0 or selector>nv+1 or len!=c_size_t(2+nv*nv):return -1.0e300
    let n=Int(nv)
    for i in range(n*n):if a[i+2]<0 or a[i+2]>1000:return -1.0e300
    var used=InlineArray[Bool,8]();used[0]=True;var order=InlineArray[Int,7]();var route=InlineArray[Int,9]();var best:Int64=8001
    tspbf_visit(a+2,n,0,used,order,best,route)
    if selector==0:return Float64(best)
    return Float64(route[Int(selector-1)])
