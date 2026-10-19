from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ria_collect(cells:InlineArray[Int64,16],size:Int,variant:Int,row:Int,col:Int,mut visited:InlineArray[Int64,16],mut current:InlineArray[Int64,15],plen:Int,mut paths:InlineArray[Int64,2760],mut lens:InlineArray[Int64,184],mut count:Int)->Bool:
    if row==size-1 and col==size-1:
        let slot=count;count+=1;lens[slot]=Int64(plen)
        for i in range(plen):paths[slot*15+i]=current[i]
        return variant==1
    let index=row*size+col;visited[index]=1
    for move in range(4):
        var dr=0;var dc=0;var code=0
        if variant==0:
            if move==0:dr=1;code=0
            elif move==1:dc= -1;code=1
            elif move==2:dc=1;code=2
            else:dr= -1;code=3
        else:
            if move==0:dc=1;code=2
            elif move==1:dr=1;code=0
            elif move==2:dr= -1;code=3
            else:dc= -1;code=1
        let nr=row+dr;let nc=col+dc
        if nr<0 or nc<0 or nr>=size or nc>=size:continue
        let ni=nr*size+nc
        if cells[ni]!=1 or visited[ni]!=0:continue
        current[plen]=Int64(code)
        if ria_collect(cells,size,variant,nr,nc,visited,current,plen+1,paths,lens,count):visited[index]=0;return True
    visited[index]=0;return False
fn ria_byte(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("rat_in_amaze")
fn rat_in_amaze(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>19 or (v[0]!=0 and v[0]!=1):return -1
    let variant=Int(v[0]);if n<2 or v[1]<1 or v[1]>4:return -1
    let size=Int(v[1]);if n!=c_size_t(2+size*size):return -1
    var cells=InlineArray[Int64,16](fill=0)
    for i in range(size*size):if v[2+i]!=0 and v[2+i]!=1:return -1;cells[i]=v[2+i]
    var paths=InlineArray[Int64,2760](fill=0);var lens=InlineArray[Int64,184](fill=0);var current=InlineArray[Int64,15](fill=0);var visited=InlineArray[Int64,16](fill=0);var count=0
    if cells[0]==1 and cells[size*size-1]==1:let _=ria_collect(cells,size,variant,0,0,visited,current,0,paths,lens,count)
    if count==0:return -3
    var words=1
    for p in range(count):words+=1+Int(lens[p])
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(words*8):return -2
    var at=0;ria_byte(o,at,Int64(count));at+=8
    for p in range(count):
        ria_byte(o,at,lens[p]);at+=8
        for j in range(Int(lens[p])):ria_byte(o,at,paths[p*15+j]);at+=8
    return Int64(words*8)
