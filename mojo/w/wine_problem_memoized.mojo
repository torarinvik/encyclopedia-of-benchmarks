from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn wpm_solve(a:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,l:Int,r:Int,inout memo:InlineArray[Int64,4096])->Int64:
    let slot=l*64+r;let year=n-(r-l+1)+1
    if l==r:memo[slot]=a[l]*Int64(year);return memo[slot]
    if memo[slot]!=0:return memo[slot]
    let x=a[l]*Int64(year)+wpm_solve(a,n,l+1,r,memo)
    let y=a[r]*Int64(year)+wpm_solve(a,n,l,r-1,memo)
    memo[slot]=max(x,y);return memo[slot]
@export("wine_problem_memoized")
fn wine_problem_memoized(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    for i in range(Int(n)):if a[i]<1 or a[i]>1000000:return -1
    var memo=InlineArray[Int64,4096]()
    return wpm_solve(a,Int(n),0,Int(n)-1,memo)
