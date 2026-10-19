from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn meoa_rng(mut s:UInt32)->UInt32:
    var x=s;x^=x<<13;x^=x>>17;x^=x<<5;s=if x==0:UInt32(0x9e3779b9) else:x;return x
fn meoa_select(mut a:InlineArray[Int64,128],lo:Int,hi:Int,k:Int,mut state:UInt32)->Int64:
    if lo==hi:return a[lo]
    let pivot=lo+Int(meoa_rng(mut state))%(hi-lo+1);let tmp=a[pivot];a[pivot]=a[hi];a[hi]=tmp;let key=a[hi];var i=lo
    for j in range(lo,hi):
        if a[j]<=key:let t=a[i];a[i]=a[j];a[j]=t;i+=1
    let t=a[i];a[i]=a[hi];a[hi]=t;let rank=i-lo+1
    if k==rank:return a[i]
    if k<rank:return meoa_select(mut a,lo,i-1,k,mut state)
    return meoa_select(mut a,i+1,hi,k-rank,mut state)
@export("minimum_element_of_array")
fn minimum_element_of_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>131 or v[0]<1 or v[0]>128 or Int(n)!=Int(v[0])+3 or v[1]<1 or v[1]>v[0] or v[2]<0 or v[2]>2147483647:return -1
    let count=Int(v[0]);var a=InlineArray[Int64,128](fill=0)
    for i in range(count):
        let x=v[i+3]
        if x < -1000000 or x>1000000:return -1
        for j in range(i):if a[j]==x:return -1
        a[i]=x
    var state=if v[2]==0:UInt32(0x9e3779b9) else:UInt32(v[2])
    return meoa_select(mut a,0,count-1,Int(v[1]),mut state)
