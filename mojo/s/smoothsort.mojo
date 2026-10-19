from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn so_leo(k:Int)->Int:
    if k<2:return 1
    var a=1;var b=1
    for _ in range(2,k+1):let t=a+b+1;a=b;b=t
    return b
fn so_sift(v:UnsafePointer[Int64,MutAnyOrigin],root0:Int,order0:Int):
    var root=root0;var order=order0
    while order>1:
        let right=root-1;let left=root-1-so_leo(order-2)
        if v[left]>=v[right] and v[root]<v[left]:let t=v[root];v[root]=v[left];v[left]=t;root=left;order-=1
        elif v[left]<v[right] and v[root]<v[right]:let t=v[root];v[root]=v[right];v[right]=t;root=right;order-=2
        else:break
fn so_trinkle(v:UnsafePointer[Int64,MutAnyOrigin],pos0:Int,orders:UnsafePointer[Int32,MutAnyOrigin],idx0:Int):
    var pos=pos0;var idx=idx0
    while idx>0:
        let prev=pos-so_leo(Int(orders[idx]))
        if v[pos]>=v[prev]:break
        if orders[idx]>1:
            let right=pos-1;let left=pos-1-so_leo(Int(orders[idx])-2)
            if v[right]>=v[prev] or v[left]>=v[prev]:break
        let t=v[pos];v[pos]=v[prev];v[prev]=t;pos=prev;idx-=1
    so_sift(v,pos,Int(orders[idx]))
fn so_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:Int):
    if n<2:return
    var orders=InlineArray[Int32,64]();var hc=0
    for pos in range(n):
        if hc>=2 and orders[hc-2]==orders[hc-1]+1:hc-=1;orders[hc-1]+=1
        elif hc>0 and orders[hc-1]==1:orders[hc]=0;hc+=1
        else:orders[hc]=1;hc+=1
        so_trinkle(v,pos,orders.unsafe_ptr(),hc-1)
    for ri in range(n):
        let pos=n-1-ri;hc-=1;let order=Int(orders[hc])
        if order>1:
            let ro=order-2;let lo=order-1;let rp=pos-1;let lp=pos-1-so_leo(ro)
            orders[hc]=Int32(lo);hc+=1;so_trinkle(v,lp,orders.unsafe_ptr(),hc-1)
            orders[hc]=Int32(ro);hc+=1;so_trinkle(v,rp,orders.unsafe_ptr(),hc-1)
fn so_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[p+j]=UInt8((b>>(8*j))&255)
@export("smoothsort")
fn smoothsort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66:return -1
    let count=a[0];if count<0 or count>64 or n!=c_size_t(count+1):return -1
    var vals=InlineArray[Int64,64]();for i in range(Int(count)):vals[i]=a[i+1]
    so_sort(vals.unsafe_ptr(),Int(count));let bytes=Int(count)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(count)):so_put(o,i*8,vals[i])
    return bytes
