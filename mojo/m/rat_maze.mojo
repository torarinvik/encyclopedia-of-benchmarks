from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn rat_search(maze:InlineArray[Int32,64],mut path:InlineArray[Int32,64],n:Int,r:Int,c:Int)->Bool:
    if r>=n or c>=n or maze[r*n+c]==0:return False
    path[r*n+c]=1
    if r==n-1 and c==n-1:return True
    if rat_search(maze,mut path,n,r,c+1):return True
    if rat_search(maze,mut path,n,r+1,c):return True
    path[r*n+c]=0
    return False
fn rm_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):o[p+4*b]=UInt8((u>>(8*b))&255)
@export("rat_maze")
fn rat_maze(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let size=Int(v[0]);if size<1 or size>8 or Int(n)!=1+size*size:return -1
    var maze=InlineArray[Int32,64](fill=0);var path=InlineArray[Int32,64](fill=0)
    for i in range(size*size):if v[1+i]!=0 and v[1+i]!=1:return -1;maze[i]=v[1+i]
    if maze[0]==0:return -1
    let found=rat_search(maze,mut path,size,0,0);let words=if found:1+size*size else:1;let bytes=4*words
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    rm_put(o,0,Int32(1 if found else 0));if found:for i in range(size*size):rm_put(o,4*(i+1),path[i])
    return Int64(bytes)
