from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mr_solve(mut grid:InlineArray[UInt8,56],row:Int,col:Int,strategy:Int)->Bool:
    if grid[6*7+5]==2:return True
    let idx=row*7+col
    if grid[idx]!=0:return False
    grid[idx]=2
    if strategy==0:
        if mr_solve(mut grid,row+1,col,strategy):return True
        if mr_solve(mut grid,row,col+1,strategy):return True
        if mr_solve(mut grid,row-1,col,strategy):return True
        if mr_solve(mut grid,row,col-1,strategy):return True
    else:
        if mr_solve(mut grid,row-1,col,strategy):return True
        if mr_solve(mut grid,row,col+1,strategy):return True
        if mr_solve(mut grid,row+1,col,strategy):return True
        if mr_solve(mut grid,row,col-1,strategy):return True
    grid[idx]=3;return False
fn mr_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int32):
    let bits=UInt32(x)
    for b in range(4):out[pos+b]=UInt8((bits>>UInt32(8*b))&255)

@export("maze_recursion")
fn maze_recursion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=57 or v[0]<0 or v[0]>1:return -1
    var grid=InlineArray[UInt8,56](fill=0)
    for i in range(56):
        if v[i+1]!=0 and v[i+1]!=1:return -1
        grid[i]=UInt8(v[i+1])
    for r in range(8):for c in range(7):
        if (r==0 or r==7 or c==0 or c==6) and grid[r*7+c]!=1:return -1
    if grid[8]!=0 or grid[47]!=0:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<228:return -2
    let found=mr_solve(mut grid,1,1,Int(v[0]))
    var result=InlineArray[Int32,57](fill=0);result[0]=1 if found else 0
    for i in range(56):result[i+1]=Int32(grid[i])
    for i in range(57):mr_store(out,i*4,result[i])
    return 228
