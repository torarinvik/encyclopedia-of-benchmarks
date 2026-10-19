from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn msd_key(x:Int64)->UInt64:return UInt64(x)^0x8000000000000000
fn msd_rec(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int,bit:Int):
    if hi-lo<2 or bit<0:return
    var l=lo;var r=hi
    while l<r:
        while l<r and ((msd_key(v[l])>>bit)&1)==0:l+=1
        while l<r and ((msd_key(v[r-1])>>bit)&1)!=0:r-=1
        if l<r:let tmp=v[l];v[l]=v[r-1];v[r-1]=tmp;l+=1;r-=1
    msd_rec(v,lo,l,bit-1);msd_rec(v,l,hi,bit-1)
@export("msd_radix_sort")
fn msd_radix_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n>1:msd_rec(v,0,Int(n),63)
