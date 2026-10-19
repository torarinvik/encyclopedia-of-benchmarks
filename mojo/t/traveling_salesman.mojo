from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tsp_enum(m:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,inout order:InlineArray[Int,7],pos:Int,inout best:Int64):
    if pos==n-1:
        var cost:Int64=0;var prev=0
        for i in range(n-1):
            let city=order[i];let edge=m[prev*n+city]
            if edge==2147483647:return
            cost+=edge;prev=city
        let edge=m[prev*n]
        if edge==2147483647:return
        cost+=edge
        if cost<best:best=cost
        return
    for i in range(pos,n-1):
        let t=order[pos];order[pos]=order[i];order[i]=t
        tsp_enum(m,n,order,pos+1,best)
        order[i]=order[pos];order[pos]=t
@export("traveling_salesman")
fn traveling_salesman(a:UnsafePointer[Int64,ImmutAnyOrigin],len:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or len<1 or len>66 or a[0]<0 or a[0]>8:return -1
    let n=Int(a[0])
    if len!=c_size_t(1+n*n):return -1
    for i in range(n*n):
        let v=a[i+1]
        if v< -2147483648 or v>2147483647:return -1
    if n<=1:return 0
    for i in range(n):
        for j in range(n):
            if i!=j:
                let edge=a[1+i*n+j]
                if edge!=2147483647 and (edge<0 or edge>1000):return -1
    var order=InlineArray[Int,7]();for i in range(n-1):order[i]=i+1
    var best:Int64=2147483647
    tsp_enum(a+1,n,order,0,best)
    return best
