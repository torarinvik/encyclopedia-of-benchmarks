from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tsp_bit_solve(pos:Int,mask:Int,n:Int,dist:InlineArray[Int64,100],inout memo:InlineArray[Int64,10240],inout seen:InlineArray[Bool,10240])->Int64:
    let all=(1<<n)-1
    if mask==all:return dist[pos*n]
    let ix=pos*1024+mask
    if seen[ix]:return memo[ix]
    seen[ix]=True;var best:Int64=9223372036854775807
    for city in range(n):
        let bit=1<<city
        if (mask&bit)==0:
            let cost=dist[pos*n+city]+tsp_bit_solve(city,mask|bit,n,dist,memo,seen)
            if cost<best:best=cost
    memo[ix]=best;return best
@export("traveling_salesman_bitmask")
fn traveling_salesman_bitmask(a:UnsafePointer[Int64,ImmutAnyOrigin],len:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or len<1 or len>102:return -1
    let nv=a[0]
    if nv<2 or nv>10 or len!=c_size_t(1+nv*nv):return -1
    let n=Int(nv);var dist=InlineArray[Int64,100]()
    for i in range(n*n):
        let x=a[i+1]
        if x<0 or x>1000 or (i/n==i%n and x!=0):return -1
        dist[i]=x
    var memo=InlineArray[Int64,10240]();var seen=InlineArray[Bool,10240]()
    return tsp_bit_solve(0,1,n,dist,memo,seen)
