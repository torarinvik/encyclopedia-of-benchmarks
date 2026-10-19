from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("sort_the_odd_benchmark")
fn sort_the_odd_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var a=InlineArray[Int64,256](fill=0);var odds=InlineArray[Int64,256](fill=0);var m=0
    for i in range(Int(n)):
        let x=v[i]
        if x < -1000000 or x>1000000:return -1
        a[i]=x
        if x%2!=0:odds[m]=x;m+=1
    for i in range(1,m):
        let x=odds[i];var j=i
        while j>0 and odds[j-1]>x:odds[j]=odds[j-1];j-=1
        odds[j]=x
    var oi=0;var sum:Int64=0
    for i in range(Int(n)):
        var x=a[i]
        if x%2!=0:x=odds[oi];oi+=1
        sum+=Int64(i+1)*(x+1000001)
    return sum
