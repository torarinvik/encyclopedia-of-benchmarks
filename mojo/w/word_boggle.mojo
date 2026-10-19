from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wb_dfs(board:InlineArray[UInt8,36],rows:Int,cols:Int,words:InlineArray[InlineArray[UInt8,15],32],lens:InlineArray[Int32,32],wc:Int,cell:Int,depth:Int,inout visited:InlineArray[Bool,36],inout path:InlineArray[UInt8,15],inout found:InlineArray[Bool,32]):
    path[depth]=board[cell];visited[cell]=True;let d=depth+1;var prefix=false
    for w in range(wc):
        if Int(lens[w])>=d:
            var same=true
            for j in range(d):if words[w][j]!=path[j]:same=false
            if same:
                prefix=true
                if Int(lens[w])==d:found[w]=True
    if prefix and d<15:
        let r=cell/cols;let c=cell%cols
        for dr in range(-1,2):for dc in range(-1,2):
            let nr=r+dr;let nc=c+dc
            if (dr!=0 or dc!=0) and nr>=0 and nr<rows and nc>=0 and nc<cols:
                let dest=nr*cols+nc
                if not visited[dest]:wb_dfs(board,rows,cols,words,lens,wc,dest,d,visited,path,found)
    visited[cell]=False
@export("word_boggle")
fn word_boggle(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>551:return -1
    let rows=a[0];let cols=a[1]
    if rows<1 or rows>6 or cols<1 or cols>6:return -1
    let cells=Int(rows*cols);if n<c_size_t(cells+3):return -1
    var board=InlineArray[UInt8,36]()
    for i in range(cells):
        let c=a[i+2]
        if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
        board[i]=UInt8(c)
    let wc=a[cells+2]
    if wc<0 or wc>32:return -1
    var words=InlineArray[InlineArray[UInt8,15],32]();var lens=InlineArray[Int32,32]();var unique=0;var pos=cells+3
    for _ in range(Int(wc)):
        if pos>=Int(n):return -1
        let length=a[pos];pos+=1
        if length<1 or length>15 or pos+Int(length)>Int(n):return -1
        var word=InlineArray[UInt8,15]()
        for j in range(Int(length)):
            let c=a[pos+j]
            if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
            word[j]=UInt8(c)
        var duplicate=false
        for w in range(unique):
            if lens[w]==length:
                var same=true
                for j in range(Int(length)):if words[w][j]!=word[j]:same=false
                if same:duplicate=true
        if not duplicate:words[unique]=word;lens[unique]=Int32(length);unique+=1
        pos+=Int(length)
    if pos!=Int(n):return -1
    var found=InlineArray[Bool,32]();var visited=InlineArray[Bool,36]();var path=InlineArray[UInt8,15]()
    for cell in range(cells):wb_dfs(board,Int(rows),Int(cols),words,lens,unique,cell,0,visited,path,found)
    var order=InlineArray[Int32,32]();var found_count=0;var bytes=0
    for w in range(unique):if found[w]:order[found_count]=Int32(w);found_count+=1;bytes+=Int(lens[w])+1
    for i in range(1,found_count):
        let key=order[i];var j=i
        while j>0:
            let x=Int(order[j-1]);let y=Int(key);var less=false
            for k in range(min(Int(lens[x]),Int(lens[y]))):
                if words[x][k]!=words[y][k]:less=words[x][k]<words[y][k];break
            if not less and lens[x]!=lens[y]:less=lens[x]<lens[y]
            if not less:break
            order[j]=order[j-1];j-=1
        order[j]=key
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var p=0
    for i in range(found_count):
        let w=Int(order[i])
        for j in range(Int(lens[w])):o[p]=words[w][j];p+=1
        o[p]=0;p+=1
    return Int64(p)
