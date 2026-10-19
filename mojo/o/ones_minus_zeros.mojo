from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn omz_put(o:UnsafePointer[UInt8,MutAnyOrigin],cell:Int,x:Int64):
    let b=UInt32(Int32(x));let at=cell*4
    for j in range(4):o[at+j]=UInt8((b>>(8*j))&255)
@export("ones_minus_zeros")
fn ones_minus_zeros(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>100000 or v[1]<1 or v[1]>100000:return -1
    let rows=Int(v[0]);let cols=Int(v[1])
    if rows>100000//cols:return -1
    let cells=rows*cols
    if n!=c_size_t(2+cells):return -1
    for i in range(cells):if v[i+2]!=0 and v[i+2]!=1:return -1
    let required=c_size_t(4*cells)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<required:return -2
    var row_ones=InlineArray[Int64,100000](fill=0);var col_ones=InlineArray[Int64,100000](fill=0)
    for r in range(rows):
        for c in range(cols):
            if v[2+r*cols+c]==1:row_ones[r]+=1;col_ones[c]+=1
    for r in range(rows):
        for c in range(cols):
            let val=row_ones[r]+col_ones[c]-(Int64(rows)-row_ones[r])-(Int64(cols)-col_ones[c])
            omz_put(o,r*cols+c,val)
    return Int64(cells)
