from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn okt_search(mut board:InlineArray[Int32,25],n:Int,r:Int,c:Int,step:Int)->Bool:
    if step==n*n:return True
    let dr=InlineArray[Int,8](1,-1,1,-1,2,2,-2,-2);let dc=InlineArray[Int,8](2,2,-2,-2,1,-1,1,-1)
    for k in range(8):
        let nr=r+dr[k];let nc=c+dc[k]
        if nr>=0 and nr<n and nc>=0 and nc<n:
            let at=nr*n+nc
            if board[at]==0:
                board[at]=Int32(step+1)
                if okt_search(board,n,nr,nc,step+1):return True
                board[at]=0
    return False
@export("open_knight_tour")
fn open_knight_tour(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or (a[0]!=1 and a[0]!=5):return -1
    let dim=Int(a[0]);let bytes=dim*dim*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var board=InlineArray[Int32,25]()
    var found=false
    for r in range(dim):
        for c in range(dim):
            if not found:
                board[r*dim+c]=1
                if okt_search(board,dim,r,c,1):found=True
                else:board[r*dim+c]=0
    var staged=InlineArray[UInt8,100]()
    for i in range(dim*dim):
        let bits=bitcast[UInt32](board[i])
        for b in range(4):staged[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    for i in range(bytes):o[i]=staged[i]
    return Int64(bytes)
