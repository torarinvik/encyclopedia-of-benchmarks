from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn ssr(a:UnsafePointer[Int64,MutAnyOrigin],n:Int,i:Int):
    if i>=n-1:return
    var m=i
    for j in range(i+1,n):if a[j]<a[m]:m=j
    if m!=i:let t=a[i];a[i]=a[m];a[m]=t
    ssr(a,n,i+1)
@export("selection_sort_recursive")
fn selection_sort_recursive(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n>0:ssr(a,Int(n),0)
