from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn wpr_solve(a:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,l:Int,r:Int)->Int64:
    let year=n-(r-l+1)+1
    if l==r:return a[l]*Int64(year)
    let x=a[l]*Int64(year)+wpr_solve(a,n,l+1,r)
    let y=a[r]*Int64(year)+wpr_solve(a,n,l,r-1)
    return max(x,y)
@export("wine_problem_recursive")
fn wine_problem_recursive(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>14:return -1
    for i in range(Int(n)):if a[i]<0 or a[i]>1000000:return -1
    return wpr_solve(a,Int(n),0,Int(n)-1)
