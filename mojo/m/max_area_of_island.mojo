from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("max_area_of_island")
fn max_area_of_island(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<0 or v[0]>16 or v[1]<0 or v[1]>16:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);let cells=rows*cols
    if n!=c_size_t(2+cells):return -1
    for i in range(cells):if v[2+i]!=0 and v[2+i]!=1:return -1
    var visited=InlineArray[Bool,256](fill=False);var stack=InlineArray[Int,256](fill=0);var best=0
    for start in range(cells):
        if v[2+start]==0 or visited[start]:continue
        var top=1;var area=0;stack[0]=start;visited[start]=True
        while top>0:
            top-=1;let current=stack[top];area+=1
            let row=current/cols;let col=current%cols
            if row>0:let q=current-cols;if not visited[q] and v[2+q]==1:visited[q]=True;stack[top]=q;top+=1
            if row+1<rows:let q=current+cols;if not visited[q] and v[2+q]==1:visited[q]=True;stack[top]=q;top+=1
            if col>0:let q=current-1;if not visited[q] and v[2+q]==1:visited[q]=True;stack[top]=q;top+=1
            if col+1<cols:let q=current+1;if not visited[q] and v[2+q]==1:visited[q]=True;stack[top]=q;top+=1
        if area>best:best=area
    return Int64(best)
