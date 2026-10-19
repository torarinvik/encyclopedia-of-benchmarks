from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("smith_waterman_java")
fn smith_waterman_java(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>38:return -1
    let qn=a[0];let sn=a[1];let match=a[2];let mismatch=a[3];let gap=a[4]
    if qn<0 or qn>16 or sn<0 or sn>16 or match<1 or match>5 or mismatch< -5 or mismatch> -1 or gap< -5 or gap> -1 or n!=c_size_t(5+qn+sn):return -1
    for i in range(Int(qn+sn)):
        let c=a[i+5];if not ((c>=65 and c<=90) or (c>=97 and c<=122) or c==45):return -1
    var dp=InlineArray[Int32,289]();var best:Int64=0
    for i in range(1,Int(qn)+1):
        for j in range(1,Int(sn)+1):
            let x=a[4+i];let y=a[4+Int(qn)+j];let sc=match if x==y else mismatch
            var v=Int64(dp[(i-1)*17+j-1])+sc
            let u=Int64(dp[(i-1)*17+j])+gap;let l=Int64(dp[i*17+j-1])+gap
            if u>v:v=u
            if l>v:v=l
            if v<0:v=0
            dp[i*17+j]=Int32(v);if v>best:best=v
    return best
