from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ss_l(k:Int)->Int:
    if k==0:return 1
    if k==1:return 1
    var a=1;var b=1
    for _ in range(2,k+1):let t=a+b+1;a=b;b=t
    return b
fn ss_shift(p:UInt64)->Int:
    var x=p;var n=0
    while (x&1)==0 and n<64:x>>=1;n+=1
    return n
fn ss_sift(v:UnsafePointer[Int64,MutAnyOrigin],order:Int,root0:Int):
    var root=root0;let value=v[root];var k=order
    while k>1:
        let right=root-1;let left=root-1-ss_l(k-2)
        if value>=v[left] and value>=v[right]:break
        if v[left]>=v[right]:v[root]=v[left];root=left;k-=1
        else:v[root]=v[right];root=right;k-=2
    v[root]=value
fn ss_trinkle(v:UnsafePointer[Int64,MutAnyOrigin],pp:UInt64,order0:Int,root0:Int,trust0:Bool):
    var p=pp;var order=order0;var root=root0;var trusty=trust0;let value=v[root]
    while p!=1:
        let step=root-ss_l(order)
        if value>=v[step]:break
        if not trusty and order>1:
            let right=root-1;let left=root-1-ss_l(order-2)
            if v[right]>=v[step] or v[left]>=v[step]:break
        v[root]=v[step];root=step
        let shift=ss_shift(p&(~UInt64(1)));p>>=shift;order+=shift;trusty=false
    if not trusty:v[root]=value;ss_sift(v,order,root)
fn ss_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:Int):
    if n<2:return
    let last=n-1;var p:UInt64=1;var order=1;var head=0
    while head<last:
        if (p&3)==3:ss_sift(v,order,head);p>>=2;order+=2
        else:
            if ss_l(order-1)>=last-head:ss_trinkle(v,p,order,head,false)
            else:ss_sift(v,order,head)
            if order==1:p<<=1;order=0
            else:p<<=(order-1);order=1
        p|=1;head+=1
    ss_trinkle(v,p,order,head,false)
    while order!=1 or p!=1:
        if order<=1:
            let shift=ss_shift(p&(~UInt64(1)));p>>=shift;order+=shift
        else:
            p<<=2;p^=7;order-=2
            ss_trinkle(v,p>>1,order+1,head-ss_l(order)-1,true)
            ss_trinkle(v,p,order,head-1,true)
        head-=1
@export("smooth_sort_benchmark")
fn smooth_sort_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>514:return -1
    let count=a[0];if count<0 or count>512 or n!=c_size_t(count+1):return -1
    var v=InlineArray[Int64,512]()
    for i in range(Int(count)):v[i]=a[i+1];if v[i]< -1000000 or v[i]>1000000:return -1
    ss_sort(v.unsafe_ptr(),Int(count));var sum:Int64=0
    for i in range(Int(count)):sum+=(i+1)*(v[i]+1000001)
    return sum
