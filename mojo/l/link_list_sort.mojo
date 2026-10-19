from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn sort_merge(mut a:InlineArray[Int32,128],mut tmp:InlineArray[Int32,128],start:Int,end:Int):
    if end-start<2:return
    let mid=start+(end-start)/2;sort_merge(a,tmp,start,mid);sort_merge(a,tmp,mid,end);var l=start;var r=mid;var o=start
    while l<mid and r<end:
        if a[l]<=a[r]:tmp[o]=a[l];l+=1
        else:tmp[o]=a[r];r+=1
        o+=1
    while l<mid:tmp[o]=a[l];l+=1;o+=1
    while r<end:tmp[o]=a[r];r+=1;o+=1
    for i in range(start,end):a[i]=tmp[i]
fn sort_sift(mut a:InlineArray[Int32,128],count:Int,root0:Int):
    var root=root0
    while root<count/2:
        var child=2*root+1
        if child+1<count and a[child+1]>a[child]:child+=1
        if a[root]>=a[child]:return
        let z=a[root];a[root]=a[child];a[child]=z;root=child
fn sort_heap(mut a:InlineArray[Int32,128],count:Int):
    var s=count/2
    while s>0:s-=1;sort_sift(a,count,s)
    var end=count
    while end>1:
        end-=1;let z=a[0];a[0]=a[end];a[end]=z;sort_sift(a,end,0)
fn sort_put32(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=bitcast[UInt32](x)
    for j in range(4):out[at+j]=UInt8((b>>(8*j))&255)
@export("link_list_sort")
fn link_list_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let selector=v[0];let m=v[1]
    if selector<1 or selector>3 or m<0 or m>128 or n!=c_size_t(2+m):return -1
    var a=InlineArray[Int32,128](fill=0);var temp=InlineArray[Int32,128](fill=0)
    for i in range(Int(m)):
        if v[2+i]<-2147483648 or v[2+i]>2147483647:return -1
        a[i]=Int32(v[2+i])
    if selector==1:sort_merge(a,temp,0,Int(m))
    elif selector==2:
        for i in range(1,Int(m)):
            let x=a[i];var j=i
            while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1
            a[j]=x
    else:sort_heap(a,Int(m))
    let bytes=4*Int(m)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(m)):sort_put32(out,i*4,a[i])
    return Int64(bytes)
