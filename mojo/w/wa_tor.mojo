from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime WT_ENT=2112
fn wt_move(inout kind:InlineArray[Int32,2112],inout row:InlineArray[Int32,2112],inout col:InlineArray[Int32,2112],inout timer:InlineArray[Int32,2112],inout energy:InlineArray[Int32,2112],inout alive:InlineArray[Bool,2112],inout board:InlineArray[Int32,64],inout ec:Int,width:Int,height:Int,id:Int):
    let oldr=Int(row[id]);let oldc=Int(col[id]);var moved=false
    for direction in range(4):
        var nr=oldr;var nc=oldc
        if direction==0:nr-=1
        elif direction==1:nc+=1
        elif direction==2:nr+=1
        else:nc-=1
        if nr<0 or nr>=height or nc<0 or nc>=width:continue
        let dest=nr*width+nc
        if board[dest]!= -1:continue
        board[oldr*width+oldc]= -1;board[dest]=Int32(id);row[id]=Int32(nr);col[id]=Int32(nc);moved=true;break
    if moved and timer[id]<=0:
        if ec<WT_ENT:
            let child=ec;ec+=1;kind[child]=kind[id];row[child]=Int32(oldr);col[child]=Int32(oldc);timer[child]=5 if kind[id]==1 else 20;energy[child]=0 if kind[id]==1 else 15;alive[child]=True;board[oldr*width+oldc]=Int32(child);timer[id]=timer[child]
    else:timer[id]-=1
fn wt_predator(inout kind:InlineArray[Int32,2112],inout row:InlineArray[Int32,2112],inout col:InlineArray[Int32,2112],inout timer:InlineArray[Int32,2112],inout energy:InlineArray[Int32,2112],inout alive:InlineArray[Bool,2112],inout board:InlineArray[Int32,64],inout ec:Int,width:Int,height:Int,id:Int):
    let current=Int(row[id])*width+Int(col[id])
    if energy[id]==0:board[current]= -1;alive[id]=False;return
    var target= -1
    for direction in range(4):
        var nr=Int(row[id]);var nc=Int(col[id])
        if direction==0:nr-=1
        elif direction==1:nr+=1
        elif direction==2:nc-=1
        else:nc+=1
        if nr<0 or nr>=height or nc<0 or nc>=width:continue
        let dest=nr*width+nc;let occ=board[dest]
        if occ>=0 and kind[Int(occ)]==1:target=dest;break
    if target>=0:
        let prey=Int(board[target]);alive[prey]=False;board[current]= -1;board[target]=Int32(id);row[id]=Int32(target/width);col[id]=Int32(target%width);energy[id]+=5
    else:wt_move(kind,row,col,timer,energy,alive,board,ec,width,height,id)
    energy[id]-=1
@export("wa_tor")
fn wa_tor(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>196:return -1
    let width=a[0];let height=a[1];let chronons=a[2]
    if width<1 or width>8 or height<1 or height>8 or chronons<0 or chronons>32 or n!=c_size_t(3+3*width*height):return -1
    let cells=Int(width*height);var kind=InlineArray[Int32,2112]();var row=InlineArray[Int32,2112]();var col=InlineArray[Int32,2112]();var timer=InlineArray[Int32,2112]();var energy=InlineArray[Int32,2112]();var alive=InlineArray[Bool,2112]();var board=InlineArray[Int32,64]();var snapshot=InlineArray[Int32,64]()
    for i in range(64):board[i]= -1
    var ec=0
    for cell in range(cells):
        let k=a[3+3*cell];let t=a[4+3*cell];let e=a[5+3*cell]
        if k==0:
            if t!=0 or e!=0:return -1
            continue
        if k==1:
            if t<0 or t>5 or e!=0:return -1
        elif k==2:
            if t<0 or t>20 or e<0 or e>15:return -1
        else:return -1
        kind[ec]=Int32(k);row[ec]=Int32(cell/Int(width));col[ec]=Int32(cell%Int(width));timer[ec]=Int32(t);energy[ec]=Int32(e);alive[ec]=True;board[cell]=Int32(ec);ec+=1
    for _ in range(Int(chronons)):
        var sc=0
        for cell in range(cells):if board[cell]>=0:snapshot[sc]=board[cell];sc+=1
        for i in range(sc):
            let id=Int(snapshot[i])
            if not alive[id]:continue
            if kind[id]==1:wt_move(kind,row,col,timer,energy,alive,board,ec,Int(width),Int(height),id)
            else:wt_predator(kind,row,col,timer,energy,alive,board,ec,Int(width),Int(height),id)
    var prey:Int64=0;var predators:Int64=0;var hash:Int64=0
    for cell in range(cells):
        var code:Int64=0
        if board[cell]>=0:
            let id=Int(board[cell])
            if kind[id]==1:prey+=1;code=Int64(timer[id]+33)
            else:predators+=1;code=1000+53*Int64(energy[id])+Int64(timer[id])+32
        hash=(hash*1000003+code)%2147483647
    return hash*4225+65*prey+predators
