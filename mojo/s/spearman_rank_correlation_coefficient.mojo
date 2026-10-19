from std.ffi import c_size_t
from std.math import floor
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
fn assign_rank(v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,n:Int,ranks:UnsafePointer[Float64,MutAnyOrigin]):
    var order=InlineArray[Int,3](fill=0)
    for i in range(n):order[i]=i
    for i in range(1,n):
        let key=order[i];var j=i
        while j>0 and v[start+order[j-1]]>v[start+key]:order[j]=order[j-1];j-=1
        order[j]=key
    var i=0
    while i<n:
        var j=i
        while j<n-1 and v[start+order[j+1]]==v[start+order[i]]:j+=1
        let rank=(Float64(i)+Float64(j))/2.0+1.0
        for k in range(i,j+1):ranks[order[k]]=rank
        i=j+1
fn round_even_tenth(value:Float64)->Float64:
    let scaled=value*10.0;let low=floor(scaled);let frac=scaled-low;var rounded=low
    if frac>0.5 or (frac==0.5 and Int64(low)%2!=0):rounded=low+1.0
    return rounded/10.0
@export("spearman_rank_correlation_coefficient")
fn spearman_rank_correlation_coefficient(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5:return BAD
    let nv=v[0]
    if nv<2 or nv>3 or n!=c_size_t(1+2*nv):return BAD
    let count=Int(nv)
    for i in range(1,Int(n)):if v[i]< -1000 or v[i]>1000:return BAD
    var rx=InlineArray[Float64,3](fill=0.0);var ry=InlineArray[Float64,3](fill=0.0)
    assign_rank(v,1,count,rx.unsafe_ptr());assign_rank(v,1+count,count,ry.unsafe_ptr())
    var d2=0.0
    for i in range(count):let d=rx[i]-ry[i];d2+=d*d
    let nf=Float64(count);let rho=1.0-(6.0*d2)/(nf*(nf*nf-1.0))
    return round_even_tenth(rho)
