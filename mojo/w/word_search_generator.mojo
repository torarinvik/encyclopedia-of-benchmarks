from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wsg_rand(inout state:Int64)->Int:
    state=(state*48271)%2147483647;return Int(state)
fn wsg_shuffle(inout items:InlineArray[Int32,32],length:Int,inout state:Int64):
    var rem=length
    while rem>1:
        let other=wsg_rand(state)%rem;let t=items[rem-1];items[rem-1]=items[other];items[other]=t;rem-=1
@export("word_search_generator")
fn word_search_generator(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>4096:return -1
    let width=a[0];let height=a[1];let seed=a[2];let wc=a[3]
    if width<1 or width>32 or height<1 or height>32 or seed<1 or seed>=2147483647 or wc<0 or wc>96:return -1
    var pos=4
    for _ in range(Int(wc)):
        if pos>=Int(n):return -1
        let wl=a[pos];pos+=1
        if wl<1 or wl>32 or pos+Int(wl)>Int(n):return -1
        for j in range(Int(wl)):let c=a[pos+j];if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
        pos+=Int(wl)
    if pos!=Int(n):return -1
    let cells=Int(width*height)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(cells):return -2
    var board=InlineArray[UInt8,1024]();var state=seed;pos=4
    var row_delta=InlineArray[Int32,8]();row_delta[0]= -1;row_delta[1]= -1;row_delta[2]=0;row_delta[3]=1;row_delta[4]=1;row_delta[5]=1;row_delta[6]=0;row_delta[7]= -1
    var col_delta=InlineArray[Int32,8]();col_delta[0]=0;col_delta[1]=1;col_delta[2]=1;col_delta[3]=1;col_delta[4]=0;col_delta[5]= -1;col_delta[6]= -1;col_delta[7]= -1
    for _ in range(Int(wc)):
        let wl=Int(a[pos]);pos+=1;let wordpos=pos;pos+=wl
        var rows=InlineArray[Int32,32]();var cols=InlineArray[Int32,32]();for i in range(Int(height)):rows[i]=Int32(i);for i in range(Int(width)):cols[i]=Int32(i)
        wsg_shuffle(rows,Int(height),state);wsg_shuffle(cols,Int(width),state);let dir=wsg_rand(state)%8;var placed=false
        for ri in range(Int(height)):
            if placed:break
            for ci in range(Int(width)):
                let r=Int(rows[ri]);let c=Int(cols[ci]);let lr=r+(wl-1)*Int(row_delta[dir]);let lc=c+(wl-1)*Int(col_delta[dir])
                if lr<0 or lr>=Int(height) or lc<0 or lc>=Int(width):continue
                var fit=true
                for off in range(wl):
                    let cell=(r+off*Int(row_delta[dir]))*Int(width)+c+off*Int(col_delta[dir])
                    if board[cell]!=0:fit=false
                if not fit:continue
                for off in range(wl):
                    let cell=(r+off*Int(row_delta[dir]))*Int(width)+c+off*Int(col_delta[dir]);board[cell]=UInt8(a[wordpos+off])
                placed=true;break
    for i in range(cells):o[i]=board[i]
    return Int64(cells)
