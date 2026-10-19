from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rim_search(cells:InlineArray[Int64,64],rows:Int,cols:Int,variant:Int,startrow:Int,startcol:Int,destrow:Int,destcol:Int,mut path:InlineArray[Int64,64])->Bool:
    if variant==1 and startrow==destrow and startcol==destcol:path[startrow*cols+startcol]=1;return True
    if startrow<0 or startcol<0 or startrow>=rows or startcol>=cols:return False
    let index=startrow*cols+startcol;let open=if variant==0:0 else:1
    if cells[index]!=open or path[index]!=0:return False
    path[index]=1
    if variant==0 and startrow==destrow and startcol==destcol:return True
    for move in range(4):
        var dr=0;var dc=0
        if variant==0:
            if move==0:dr=1
            elif move==1:dc=1
            elif move==2:dr= -1
            else:dc= -1
        else:
            if move==0:dc=1
            elif move==1:dr=1
            elif move==2:dc= -1
            else:dr= -1
        if rim_search(cells,rows,cols,variant,startrow+dr,startcol+dc,destrow,destcol,path):return True
    path[index]=0;return False
fn rim_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("rat_in_maze")
fn rat_in_maze(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>71 or (v[0]!=0 and v[0]!=1):return -1
    let variant=Int(v[0]);var rows=0;var cols=0;var sr=0;var sc=0;var dr=0;var dc=0;var off=0
    if variant==0:
        if n<7 or v[1]<1 or v[1]>8:return -1
        rows=Int(v[1]);cols=rows;off=6
        if n!=c_size_t(6+rows*rows):return -1
        for i in range(4):if v[2+i]<0 or v[2+i]>=rows:return -1
        sr=Int(v[2]);sc=Int(v[3]);dr=Int(v[4]);dc=Int(v[5])
    else:
        if n<6 or v[1]<1 or v[1]>8 or v[2]<1 or v[2]>8:return -1
        rows=Int(v[1]);cols=Int(v[2]);off=5
        if n!=c_size_t(5+rows*cols) or v[3]<0 or v[3]>=rows or v[4]<0 or v[4]>=cols:return -1
        sr=Int(v[3]);sc=Int(v[4]);dr=rows-1;dc=cols-1
    var cells=InlineArray[Int64,64](fill=0);var path=InlineArray[Int64,64](fill=0)
    for i in range(rows*cols):if v[off+i]!=0 and v[off+i]!=1:return -1;cells[i]=v[off+i]
    if not rim_search(cells,rows,cols,variant,sr,sc,dr,dc,path):return -3
    let total=rows*cols*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(total):return -2
    for i in range(rows*cols):
        let value=if variant==0:(if path[i]!=0:0 else:1) else:(if path[i]!=0:1 else:0)
        rim_put(o,i*8,Int64(value))
    return Int64(total)
