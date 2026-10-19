from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn st_combine(mode:Int64,a:Int64,b:Int64)->Int64:
    if mode==1:return min(a,b)
    if mode==2:return max(a,b)
    return a+b
@export("segment_tree_benchmark")
fn segment_tree_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1795:return -1
    let mode=a[0];let count=a[1];if mode<0 or mode>2 or count<1 or count>256 or n<c_size_t(count+3):return -1
    let ops=a[2+count];if ops<0 or ops>512 or n!=c_size_t(count+3+3*ops):return -1
    var v=InlineArray[Int64,256]()
    for i in range(Int(count)):if a[i+2]<-1000000 or a[i+2]>1000000:return -1;v[i]=a[i+2]
    for i in range(Int(ops)):
        let b=Int(count)+3+3*i;let op=a[b];let x=a[b+1];let y=a[b+2]
        if op==0:
            if x<0 or x>=count or y< -1000000 or y>1000000:return -1
        elif op==1:
            if x<0 or y<x or y>=count:return -1
        else:return -1
    var base=1;while base<Int(count):base*=2
    let ident=0 if mode==0 else (1000001 if mode==1 else -1000001)
    var tree=InlineArray[Int64,512]();for i in range(512):tree[i]=ident
    for i in range(Int(count)):tree[base+i]=v[i]
    for i in range(base-1,0,-1):tree[i]=st_combine(mode,tree[2*i],tree[2*i+1])
    var sum:Int64=0
    for i in range(Int(ops)):
        let b=Int(count)+3+3*i;let op=a[b];let x=Int(a[b+1])
        if op==0:
            v[x]=a[b+2];var node=base+x;tree[node]=v[x]
            while node>1:node/=2;tree[node]=st_combine(mode,tree[2*node],tree[2*node+1])
        else:
            var l=base+x;var r=base+Int(a[b+2])+1;var ans=ident
            while l<r:
                if l%2==1:ans=st_combine(mode,ans,tree[l]);l+=1
                if r%2==1:r-=1;ans=st_combine(mode,ans,tree[r])
                l/=2;r/=2
            sum+=(i+1)*(ans+256000001)
    for i in range(Int(count)):sum+=(Int(ops)+i+1)*(v[i]+1000001)
    return sum
