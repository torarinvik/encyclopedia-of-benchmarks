from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rotting_oranges")
fn rotting_oranges(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]():return if n==0:0 else:-9223372036854775808
    if n==0:return 0
    if n<2 or n>259:return -9223372036854775808
    let rv=v[0];let cv=v[1]
    if rv==0:return if cv==0 and n==2:0 else:-9223372036854775808
    if rv<1 or rv>16 or cv<0 or cv>16 or Int(n)!=2+Int(rv)*Int(cv):return -9223372036854775808
    let rows=Int(rv);let cols=Int(cv);let cells=rows*cols
    var grid=InlineArray[Int64,256](fill=0);var queue=InlineArray[Int64,256](fill=0);var dist=InlineArray[Int64,256](fill=0);var head=0;var tail=0;var fresh=0
    for i in range(cells):
        let x=v[2+i];if x<0 or x>2:return -9223372036854775808
        grid[i]=x;if x==1:fresh+=1
        if x==2:queue[tail]=Int64(i);tail+=1
    if cols==0 or fresh==0:return 0
    var rotted=0;var minutes:Int64=0
    while head<tail:
        let idx=Int(queue[head]);head+=1;let row=idx/cols;let col=idx%cols;let nd=dist[idx]+1
        var neighbors=InlineArray[Int64,4](fill= -1);var nc=0
        if row>0:neighbors[nc]=Int64(idx-cols);nc+=1
        if col+1<cols:neighbors[nc]=Int64(idx+1);nc+=1
        if row+1<rows:neighbors[nc]=Int64(idx+cols);nc+=1
        if col>0:neighbors[nc]=Int64(idx-1);nc+=1
        for j in range(nc):let next=Int(neighbors[j]);if grid[next]==1:grid[next]=2;dist[next]=nd;if nd>minutes:minutes=nd;rotted+=1;queue[tail]=Int64(next);tail+=1
    if rotted==fresh:return minutes
    return -1
