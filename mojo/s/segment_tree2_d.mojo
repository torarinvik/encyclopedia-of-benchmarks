from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("segment_tree2_d_benchmark")
fn segment_tree2_d_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1284:return -1
    let rows=a[0];let cols=a[1];let ops=a[2]
    if rows<1 or rows>16 or cols<1 or cols>16 or ops<0 or ops>256 or n!=c_size_t(3+5*ops):return -1
    var mat=InlineArray[Int64,256]();var checksum:Int64=0
    for i in range(Int(ops)):
        let b=3+5*i;let op=a[b];let x=a[b+1];let y=a[b+2];let z=a[b+3];let w=a[b+4]
        if op==0:
            if x<0 or x>=rows or y<0 or y>=cols or z< -1000 or z>1000 or w!=0:return -1
            mat[Int(x*cols+y)]=z
        elif op==1:
            if x<0 or x>y or y>rows or z<0 or z>w or w>cols:return -1
            var sum:Int64=0
            for r in range(Int(x),Int(y)):for c in range(Int(z),Int(w)):sum+=mat[r*Int(cols)+c]
            checksum+=(i+1)*(sum+256001)
        else:return -1
    return checksum
