from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("tiling_problem")
fn tiling_problem(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let size0=a[0];let mr0=a[1];let mc0=a[2]
    if size0<1 or size0>16 or (size0&(size0-1))!=0 or mr0<0 or mr0>=size0 or mc0<0 or mc0>=size0:return -1
    let size=Int(size0);let bytes=size*size*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var board=InlineArray[Int32,256]()
    var wr=InlineArray[Int,8]();var wc=InlineArray[Int,8]();var ww=InlineArray[Int,8]()
    var mr=InlineArray[Int,8]();var mc=InlineArray[Int,8]();var phase=InlineArray[Int,8]()
    var top=0;wr[0]=0;wc[0]=0;ww[0]=size;mr[0]=Int(mr0);mc[0]=Int(mc0);phase[0]=0
    var tile=1
    while top>=0:
        if ww[top]==1:top-=1;continue
        if phase[top]==0:
            let half=ww[top]/2;let row=wr[top];let col=wc[top]
            let missing= (0 if mr[top]<row+half and mc[top]<col+half else 1 if mr[top]<row+half else 2 if mc[top]<col+half else 3)
            for q in range(4):
                var rr=row+half;var ccol=col+half
                if q==0:rr=row+half-1;ccol=col+half-1
                elif q==1:rr=row+half-1
                elif q==2:ccol=col+half-1
                if q!=missing:board[rr*16+ccol]=Int32(tile)
            tile+=1;phase[top]=1
        if phase[top]<=4:
            let q=phase[top]-1;phase[top]+=1
            let half=ww[top]/2;let row=wr[top];let col=wc[top]
            let missing=(0 if mr[top]<row+half and mc[top]<col+half else 1 if mr[top]<row+half else 2 if mc[top]<col+half else 3)
            var child_row=row;var child_col=col
            var cr=row+half;var cc=col+half
            if q==0:cr=row+half-1;cc=col+half-1
            elif q==1:child_col=col+half;cr=row+half-1
            elif q==2:child_row=row+half;cc=col+half-1
            else:child_row=row+half;child_col=col+half
            top+=1;wr[top]=child_row;wc[top]=child_col;ww[top]=half;phase[top]=0
            if q==missing:mr[top]=mr[top-1];mc[top]=mc[top-1]
            else:mr[top]=cr;mc[top]=cc
        else:top-=1
    for i in range(size*size):
        let v=board[(i/size)*16+(i%size)];let bits=UInt32(v)
        for b in range(4):o[i*4+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
