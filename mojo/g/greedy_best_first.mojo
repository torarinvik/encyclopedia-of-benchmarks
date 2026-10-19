from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gbf_h(cell:Int,goal:Int,cols:Int)->Int:
    let r=cell//cols;let c=cell%cols;let gr=goal//cols;let gc=goal%cols
    return (r-gr if r>gr else gr-r)+(c-gc if c>gc else gc-c)
@export("greedy_best_first")
fn greedy_best_first(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>9:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);if rows<1 or rows>3 or cols<1 or cols>3 or n!=c_size_t(6+rows):return -1
    let sr=Int(v[2]);let sc=Int(v[3]);let gr=Int(v[4]);let gc=Int(v[5])
    if sr<0 or sr>=rows or gr<0 or gr>=rows or sc<0 or sc>=cols or gc<0 or gc>=cols:return -1
    var masks=InlineArray[Int,3](fill=0)
    for r in range(rows):if v[6+r]<0 or v[6+r]>=(1<<cols):return -1;masks[r]=Int(v[6+r])
    let start=sr*cols+sc;let goal=gr*cols+gc
    if (masks[start//cols]&(1<<(start%cols)))!=0 or (masks[goal//cols]&(1<<(goal%cols)))!=0:return -1
    var opened=InlineArray[Int,9](fill=0);var parent=InlineArray[Int,9](fill= -1);var closed=InlineArray[Bool,9](fill=False);var inopen=InlineArray[Bool,9](fill=False)
    var open_count=1;opened[0]=start;inopen[start]=True;var found=False
    while open_count>0:
        for idx in range(1,open_count):
            let cur=opened[idx];var pos=idx
            while pos>0 and gbf_h(opened[pos-1],goal,cols)>gbf_h(cur,goal,cols):opened[pos]=opened[pos-1];pos-=1
            opened[pos]=cur
        let current=opened[0]
        for i in range(1,open_count):opened[i-1]=opened[i]
        open_count-=1;inopen[current]=False
        if current==goal:found=True;break
        closed[current]=True;let row=current//cols;let col=current%cols
        let nr=InlineArray[Int,4](row-1,row,row+1,row);let nc=InlineArray[Int,4](col,col-1,col,col+1)
        for direction in range(4):
            let r=nr[direction];let c=nc[direction]
            if r<0 or r>=rows or c<0 or c>=cols:continue
            let child=r*cols+c
            if (masks[r]&(1<<c))!=0 or closed[child] or inopen[child]:continue
            parent[child]=current;opened[open_count]=child;open_count+=1;inopen[child]=True
    var path=InlineArray[Int,9](fill=0);var path_count=0
    if found:
        var cur=goal
        while cur>=0 and path_count<9:path[path_count]=cur;path_count+=1;cur=parent[cur]
    else:path[0]=start;path_count=1
    var packed=UInt64(0)
    for i in range(path_count):packed|=UInt64(path[path_count-1-i]+1)<<UInt64(4*i)
    return bitcast[Int64]((UInt64(path_count)<<36)|packed)
