from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hungarian_i32_store(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int):
    let u=bitcast[UInt32](Int32(v))
    for b in range(4):o[at+b]=UInt8((u>>UInt(8*b))&255)
@export("hungarian_algorithm")
fn hungarian_algorithm(a:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int32,ImmutAnyOrigin]() or n<3 or n>67:return -1
    let rows=Int(a[0]);let cols=Int(a[1])
    if rows<1 or rows>8 or cols<1 or cols>8 or n!=c_size_t(2+rows*cols):return -1
    var cost=InlineArray[Int,64](fill=0);let size=max(rows,cols)
    for i in range(rows):for j in range(cols):
        let c=Int(a[2+i*cols+j]);if c<0 or c>1000:return -1
        cost[i*8+j]=c
    var u=InlineArray[Int,9](fill=0);var v=InlineArray[Int,9](fill=0);var p=InlineArray[Int,9](fill=0);var way=InlineArray[Int,9](fill=0)
    for i in range(1,size+1):
        p[0]=i;var j0=0;var minv=InlineArray[Int,9](fill=1000000000);var used=InlineArray[Bool,9](fill=false)
        while true:
            used[j0]=true;let i0=p[j0];var delta=1000000000;var j1=0
            for j in range(1,size+1):
                if not used[j]:
                    let cur=cost[(i0-1)*8+(j-1)]-u[i0]-v[j]
                    if cur<minv[j]:minv[j]=cur;way[j]=j0
                    if minv[j]<delta:delta=minv[j];j1=j
            for j in range(size+1):
                if used[j]:u[p[j]]+=delta;v[j]-=delta
                else:minv[j]-=delta
            j0=j1
            if p[j0]==0:break
        while true:
            let j1=way[j0];p[j0]=p[j1];j0=j1
            if j0==0:break
    var assign=InlineArray[Int,8](fill=-1);var total=0
    for j in range(1,size+1):
        if p[j]>0:
            let r=p[j]-1;let c=j-1
            if r<rows and c<cols:assign[r]=c;total+=cost[r*8+c]
    let bytes=4*(rows+1)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(rows):hungarian_i32_store(o,i*4,assign[i])
    hungarian_i32_store(o,rows*4,total);return Int64(bytes)
