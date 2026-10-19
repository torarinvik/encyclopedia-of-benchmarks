from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn msr_range(v:UnsafePointer[Int64,MutAnyOrigin],s:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int):
    if hi-lo<=1:return
    let mid=lo+(hi-lo)//2;msr_range(v,s,lo,mid);msr_range(v,s,mid,hi);var i=lo;var j=mid;var k=lo
    while i<mid and j<hi:
        if v[i]<=v[j]:s[k]=v[i];i+=1
        else:s[k]=v[j];j+=1
        k+=1
    while i<mid:s[k]=v[i];i+=1;k+=1
    while j<hi:s[k]=v[j];j+=1;k+=1
    for x in range(lo,hi):v[x]=s[x]
@export("merge_sorter")
fn merge_sorter(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n>1024 or v==UnsafePointer[Int64,MutAnyOrigin]():return
    var scratch=InlineArray[Int64,1024](fill=0)
    # Inline storage is copied into a stable pointer-free merge path below.
    msr_inline(mut v,mut scratch,0,Int(n))
fn msr_inline(mut v:UnsafePointer[Int64,MutAnyOrigin],mut s:InlineArray[Int64,1024],lo:Int,hi:Int):
    if hi-lo<=1:return
    let mid=lo+(hi-lo)//2;msr_inline(mut v,mut s,lo,mid);msr_inline(mut v,mut s,mid,hi);var i=lo;var j=mid;var k=lo
    while i<mid and j<hi:
        if v[i]<=v[j]:s[k]=v[i];i+=1
        else:s[k]=v[j];j+=1
        k+=1
    while i<mid:s[k]=v[i];i+=1;k+=1
    while j<hi:s[k]=v[j];j+=1;k+=1
    for x in range(lo,hi):v[x]=s[x]
