from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn nqb_search(n:Int,col:Int,mut rows:InlineArray[Int64,8],mut out:InlineArray[Int64,737],mut count:Int):
    if col==n:
        for i in range(n):out[count]=rows[i];count+=1
        return
    for r in range(n):
        var ok=True
        for c in range(col):if rows[c]==r or abs(rows[c]-r)==col-c:ok=False
        if ok:rows[col]=r;nqb_search(n,col+1,rows,out,count)
@export("n_queens_backtracking_csharp")
fn n_queens_backtracking_csharp(n:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n<0 or n>8:return -1
    var rows=InlineArray[Int64,8]();var out=InlineArray[Int64,737]();var count=1
    nqb_search(Int(n),0,rows,out,count)
    # Index zero is reserved for solution_count; DFS appends each placement after it.
    let solutions=(count-1)//Int(n) if n>0 else 0
    if n==0:count=1;out[0]=0
    else:out[0]=solutions
    let bytes=count*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):let bits=UInt64(out[i]);for b in range(8):o[8*i+b]=UInt8((bits>>(8*b))&255)
    return bytes
