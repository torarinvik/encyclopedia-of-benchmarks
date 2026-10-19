from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ws_visit(board:InlineArray[UInt8,36],word:InlineArray[UInt8,15],wordlen:Int,rows:Int,cols:Int,cell:Int,index:Int,inout seen:InlineArray[Bool,36])->Bool:
    if seen[cell] or board[cell]!=word[index]:return False
    if index+1>=wordlen:return True
    seen[cell]=True
    let r=cell/cols;let c=cell%cols
    var found=false
    if r>0 and ws_visit(board,word,wordlen,rows,cols,cell-cols,index+1,seen):found=true
    elif r+1<rows and ws_visit(board,word,wordlen,rows,cols,cell+cols,index+1,seen):found=true
    elif c>0 and ws_visit(board,word,wordlen,rows,cols,cell-1,index+1,seen):found=true
    elif c+1<cols and ws_visit(board,word,wordlen,rows,cols,cell+1,index+1,seen):found=true
    seen[cell]=False
    return found
fn ws_letter(c:Int64)->Bool:return (c>=65 and c<=90) or (c>=97 and c<=122)
@export("word_search")
fn word_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>58:return -1
    let rows=a[0];let cols=a[1]
    if rows<1 or rows>6 or cols<1 or cols>6:return -1
    let cells=Int(rows*cols);let wi=2+cells
    if n<=c_size_t(wi):return -1
    let wl=a[wi]
    if wl<1 or wl>15 or n!=c_size_t(wi+1+wl):return -1
    var board=InlineArray[UInt8,36]();var word=InlineArray[UInt8,15]()
    for i in range(cells):if not ws_letter(a[2+i]):return -1;else:board[i]=UInt8(a[2+i])
    for i in range(Int(wl)):if not ws_letter(a[wi+1+i]):return -1;else:word[i]=UInt8(a[wi+1+i])
    if wl>cells:return 0
    var visited=InlineArray[Bool,36]();for i in range(cells):if ws_visit(board,word,Int(wl),Int(rows),Int(cols),i,0,visited):return 1
    return 0
