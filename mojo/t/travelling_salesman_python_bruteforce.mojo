from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite
fn pyts_dist(x:InlineArray[Float64,8],y:InlineArray[Float64,8],a:Int,b:Int)->Float64:
    let dx=x[b]-x[a];let dy=y[b]-y[a];return sqrt(dx*dx+dy*dy)
fn pyts_bf_visit(n:Int,pos:Int,inout used:InlineArray[Bool,8],inout order:InlineArray[Int,7],x:InlineArray[Float64,8],y:InlineArray[Float64,8],inout best:Float64,inout bestpath:InlineArray[Int,9]):
    if pos==n-1:
        var total:Float64=0.0;var previous=0
        for i in range(n-1):let city=order[i];total+=pyts_dist(x,y,previous,city);previous=city
        total+=pyts_dist(x,y,previous,0)
        if total<best:best=total;bestpath[0]=0;for i in range(n-1):bestpath[i+1]=order[i];bestpath[n]=0
        return
    for city in range(1,n):
        if not used[city]:used[city]=True;order[pos]=city;pyts_bf_visit(n,pos+1,used,order,x,y,best,bestpath);used[city]=False
@export("travelling_salesman_brute_force")
fn travelling_salesman_brute_force(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>17:return -1
    for i in range(Int(n)):
        if not isfinite(a[i]):return -1
    let nv=a[0]
    if nv<2.0 or nv>8.0 or Float64(Int64(nv))!=nv or n!=c_size_t(1+2*nv):return -1
    let count=Int(nv);var x=InlineArray[Float64,8]();var y=InlineArray[Float64,8]()
    for i in range(count):
        x[i]=a[1+2*i];y[i]=a[2+2*i]
        if x[i]< -16.0 or x[i]>16.0 or y[i]< -16.0 or y[i]>16.0 or Float64(Int64(x[i]))!=x[i] or Float64(Int64(y[i]))!=y[i]:return -1
    var used=InlineArray[Bool,8]();used[0]=True;var order=InlineArray[Int,7]();var path=InlineArray[Int,9]();var best:Float64=1.0e300
    pyts_bf_visit(count,0,used,order,x,y,best,path)
    let outn=count+3
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    o[0]=Float64(count+1)
    for i in range(count+1):o[i+1]=Float64(path[i])
    o[count+2]=best;return Int64(outn)
