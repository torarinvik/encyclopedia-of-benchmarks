from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn stu_query(t:UnsafePointer[Int32,MutAnyOrigin],node:Int,sl:Int,sr:Int,ql:Int,qr:Int)->Int32:
    if ql<=sl and sr<=qr:return t[node]
    if qr<sl or sr<ql:return 0
    let mid=sl+(sr-sl)/2;return stu_query(t,node*2,sl,mid,ql,qr)+stu_query(t,node*2+1,mid+1,sr,ql,qr)
fn stu_hash(h0:UInt64,v:Int64)->UInt64:
    var h=h0;let z=bitcast[UInt64](v)
    for b in range(8):h=(h^((z>>UInt(8*b))&255))*1099511628211
    return h
@export("segment_tree_update_benchmark")
fn segment_tree_update_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258:return -1
    let count=a[0];if count<1 or count>64 or n<c_size_t(count+2):return -1
    let ops=a[1+count];if ops<1 or ops>64 or n!=c_size_t(count+2+3*ops):return -1
    for i in range(Int(count)):if a[i+1]< -1000000 or a[i+1]>1000000:return -1
    var q=0
    for i in range(Int(ops)):
        let b=Int(count)+2+3*i;let op=a[b];let x=a[b+1];let y=a[b+2]
        if op==0:if x<0 or x>y or y>=count:return -1;q+=1
        elif op==1:if x<0 or x>=count or y< -1000000 or y>1000000:return -1
        else:return -1
    if q==0:return -1
    var base=1;while base<Int(count):base*=2
    var tree=InlineArray[Int32,128]();for i in range(Int(count)):tree[base+i]=Int32(a[i+1])
    for i in range(base-1,0,-1):tree[i]=tree[2*i]+tree[2*i+1]
    var h:UInt64=14695981039346656037;h=stu_hash(h,Int64(q))
    for i in range(Int(ops)):
        let b=Int(count)+2+3*i;let op=a[b];let x=Int(a[b+1]);let y=a[b+2]
        if op==0:h=stu_hash(h,Int64(stu_query(tree.unsafe_ptr(),1,1,base,x+1,Int(y)+1)))
        else:
            var node=base+x;tree[node]=Int32(y)
            while node>1:node/=2;tree[node]=tree[2*node]+tree[2*node+1]
    return Int64(h&0x7fffffffffffffff)
