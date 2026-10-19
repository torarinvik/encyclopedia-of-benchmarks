from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sta_up(t:UnsafePointer[Int64,MutAnyOrigin],m:UnsafePointer[Int64,MutAnyOrigin],ql:Int,qr:Int,node:Int,l:Int,r:Int,f:Int64):
    if ql<=l and r<=qr:m[node]*=f;t[node]*=f;return
    if qr<=l or r<=ql:return
    let mid=(l+r)/2;sta_up(t,m,ql,qr,node*2,l,mid,f);sta_up(t,m,ql,qr,node*2+1,mid,r,f);t[node]=m[node]*(t[node*2]+t[node*2+1])
fn sta_q(t:UnsafePointer[Int64,MutAnyOrigin],m:UnsafePointer[Int64,MutAnyOrigin],ql:Int,qr:Int,node:Int,l:Int,r:Int)->Int64:
    if ql<=l and r<=qr:return t[node]
    if qr<=l or r<=ql:return 0
    let mid=(l+r)/2;return m[node]*(sta_q(t,m,ql,qr,node*2,l,mid)+sta_q(t,m,ql,qr,node*2+1,mid,r))
@export("segment_tree_apply_benchmark")
fn segment_tree_apply_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>147:return -1
    let count=a[0];if count<1 or count>64 or n<c_size_t(count+2):return -1
    let ops=a[1+count];if ops<0 or ops>20 or n!=c_size_t(count+2+4*ops):return -1
    for i in range(Int(count)):if a[i+1]<-1 or a[i+1]>1:return -1
    for i in range(Int(ops)):
        let b=Int(count)+2+4*i;let op=a[b];let l=a[b+1];let r=a[b+2];let x=a[b+3]
        if l<0 or l>r or r>=count or (op==0 and (x< -2 or x>2)) or (op==1 and x!=0) or (op!=0 and op!=1):return -1
    var base=1;while base<Int(count):base*=2
    var tree=InlineArray[Int64,128]();var mul=InlineArray[Int64,128]();for i in range(128):mul[i]=1
    for i in range(Int(count)):tree[base+i]=a[i+1]
    for i in range(base-1,0,-1):tree[i]=tree[2*i]+tree[2*i+1]
    var checksum:Int64=0
    for i in range(Int(ops)):
        let b=Int(count)+2+4*i;let l=Int(a[b+1]);let r=Int(a[b+2])+1
        if a[b]==0:sta_up(tree.unsafe_ptr(),mul.unsafe_ptr(),l,r,1,0,base,a[b+3])
        else:checksum+=(i+1)*(sta_q(tree.unsafe_ptr(),mul.unsafe_ptr(),l,r,1,0,base)+67108865)
    return checksum
