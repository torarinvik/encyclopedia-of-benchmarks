from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn nq_count(n:Int,col:Int,mut rows:InlineArray[Int64,8],mut count:Int64):
    if col==n:count+=1;return
    for r in range(n):
        var ok=True
        for c in range(col):if rows[c]==r or abs(rows[c]-r)==col-c:ok=False
        if ok:rows[col]=r;nq_count(n,col+1,rows,count)
@export("n_queens_solution_count")
fn n_queens_solution_count(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<0 or a[0]>8:return -1
    var rows=InlineArray[Int64,8]();var cnt:Int64=0;nq_count(Int(a[0]),0,rows,cnt);return cnt
