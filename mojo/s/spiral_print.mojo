from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("spiral_print")
fn spiral_print(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>259:return -1
    if v[0]<1 or v[0]>16 or v[1]<2 or v[1]>16:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);let cells=rows*cols
    if n!=c_size_t(2+cells):return -1
    var mat=InlineArray[Int32,256](fill=0)
    for i in range(cells):
        if v[2+i]< -2147483648 or v[2+i]>2147483647:return -1
        mat[i]=Int32(v[2+i])
    let bytes=cells*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var order=InlineArray[Int32,256](fill=0);var written=0;var top=0;var bottom=rows-1;var left=0;var right=cols-1
    while top<=bottom and left<=right:
        for col in range(left,right+1):order[written]=mat[top*cols+col];written+=1
        top+=1
        for row in range(top,bottom+1):order[written]=mat[row*cols+right];written+=1
        right-=1
        if top<=bottom and left<=right:
            var col=right
            while col>=left:order[written]=mat[bottom*cols+col];written+=1;col-=1
            bottom-=1
        if top<=bottom and left<=right:
            var row=bottom
            while row>=top:order[written]=mat[row*cols+left];written+=1;row-=1
            left+=1
    for i in range(written):
        let bits=bitcast[UInt64](Int64(order[i]));for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
