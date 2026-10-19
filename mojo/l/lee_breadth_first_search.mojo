from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("lee_breadth_first_search")
fn lee_breadth_first_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>70:return -2
    let rows=v[0];let cols=v[1];let sr=v[2];let sc=v[3];let dr=v[4];let dc=v[5]
    if rows<1 or rows>8 or cols<1 or cols>8 or n!=c_size_t(6+rows*cols) or sr<0 or sr>=rows or dr<0 or dr>=rows or sc<0 or sc>=cols or dc<0 or dc>=cols:return -2
    var cell=InlineArray[Int64,64](fill=0);var dist=InlineArray[Int64,64](fill=-1);var q=InlineArray[Int64,64](fill=0)
    for i in range(Int(rows*cols)):
        cell[i]=v[6+i]
        if cell[i]!=0 and cell[i]!=1:return -2
    let s=sr*cols+sc;let t=dr*cols+dc
    if cell[s]==0 or cell[t]==0:return -1
    var head=0;var tail=1;dist[s]=0;q[0]=s
    while head<tail:
        let u=q[head];head+=1
        if u==t:return dist[u]
        let r=u/cols;let c=u%cols
        var rr=InlineArray[Int64,4](fill=0);rr[0]=r-1;rr[1]=r;rr[2]=r;rr[3]=r+1
        var cc=InlineArray[Int64,4](fill=0);cc[0]=c;cc[1]=c-1;cc[2]=c+1;cc[3]=c
        for j in range(4):
            if rr[j]>=0 and rr[j]<rows and cc[j]>=0 and cc[j]<cols:
                let w=rr[j]*cols+cc[j]
                if cell[w]==1 and dist[w]<0:dist[w]=dist[u]+1;q[tail]=w;tail+=1
    return -1
