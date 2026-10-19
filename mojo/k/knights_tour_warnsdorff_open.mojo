from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime KDX:InlineArray[Int64,8]=[1,2,2,1,-1,-2,-2,-1]
comptime KDY:InlineArray[Int64,8]=[-2,-1,1,2,2,1,-1,-2]
fn kw_degree(board:InlineArray[Int64,64],r:Int,c:Int)->Int:
    var d=0
    for m in range(8):let y=r+Int(KDY[m]);let x=c+Int(KDX[m]);if y>=0 and y<8 and x>=0 and x<8 and board[y*8+x]==0:d+=1
    return d
fn kw_orphan(board:InlineArray[Int64,64],step:Int,r:Int,c:Int)->Bool:
    if step>=63:return False
    for m in range(8):
        let y=r+Int(KDY[m]);let x=c+Int(KDX[m])
        if y>=0 and y<8 and x>=0 and x<8 and board[y*8+x]==0:
            if kw_degree(board,y,x)==0:return True
    return False
fn kw_solve(mut board:InlineArray[Int64,64],mut path:InlineArray[Int64,64],r:Int,c:Int,step:Int)->Bool:
    if step==64:return True
    var rr=InlineArray[Int64,8]();var cc=InlineArray[Int64,8]();var deg=InlineArray[Int64,8]();var n=0
    for m in range(8):
        let y=r+Int(KDY[m]);let x=c+Int(KDX[m])
        if y>=0 and y<8 and x>=0 and x<8 and board[y*8+x]==0:rr[n]=y;cc[n]=x;deg[n]=kw_degree(board,y,x);n+=1
    for i in range(1,n):
        let y=rr[i];let x=cc[i];let d=deg[i];var j=i
        while j>0 and deg[j-1]>d:rr[j]=rr[j-1];cc[j]=cc[j-1];deg[j]=deg[j-1];j-=1
        rr[j]=y;cc[j]=x;deg[j]=d
    if n==0:return False
    for i in range(n):
        let y=Int(rr[i]);let x=Int(cc[i]);board[y*8+x]=step;path[step-1]=y*8+x
        if not kw_orphan(board,step,y,x) and kw_solve(board,path,y,x,step+1):return True
        board[y*8+x]=0
    return False
@export("knights_tour_warnsdorff_open")
fn knights_tour_warnsdorff_open(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n!=0:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<512:return -2
    var board=InlineArray[Int64,64]();var path=InlineArray[Int64,64]();board[0]=1;path[0]=0
    if not kw_solve(board,path,0,0,2):return -1
    for i in range(64):let bits=UInt64(path[i]);for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return 512
