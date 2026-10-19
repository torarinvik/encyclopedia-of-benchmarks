from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sudoku_search(board: UnsafePointer[Int64, MutAnyOrigin], rows: UnsafePointer[UInt16, MutAnyOrigin], cols: UnsafePointer[UInt16, MutAnyOrigin], boxes: UnsafePointer[UInt16, MutAnyOrigin], pos: Int) -> Bool:
    var cell=pos
    while cell<81 and board[cell]!=0: cell+=1
    if cell==81: return True
    let row=cell/9; let col=cell%9; let box=(row/3)*3+col/3
    for digit in range(1,10):
        let bit=UInt16(1)<<UInt(digit)
        if (rows[row]&bit)!=0 or (cols[col]&bit)!=0 or (boxes[box]&bit)!=0: continue
        board[cell]=Int64(digit); rows[row]|=bit; cols[col]|=bit; boxes[box]|=bit
        if sudoku_search(board,rows,cols,boxes,cell+1): return True
        board[cell]=0; rows[row]^=bit; cols[col]^=bit; boxes[box]^=bit
    return False

@export("sudoku_solver")
fn sudoku_solver(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v==UnsafePointer[Int64, ImmutAnyOrigin]() or n!=81: return -1
    var board=InlineArray[Int64,81](fill=0); var rows=InlineArray[UInt16,9](fill=0); var cols=InlineArray[UInt16,9](fill=0); var boxes=InlineArray[UInt16,9](fill=0)
    for p in range(81):
        let d=v[p]
        if d<0 or d>9:return -1
        board[p]=d
        if d==0:continue
        let r=p/9;let c=p%9;let b=(r/3)*3+c/3;let bit=UInt16(1)<<UInt(d)
        if (rows[r]&bit)!=0 or (cols[c]&bit)!=0 or (boxes[b]&bit)!=0:return -1
        rows[r]|=bit;cols[c]|=bit;boxes[b]|=bit
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<324:return -2
    if not sudoku_search(board.unsafe_ptr(),rows.unsafe_ptr(),cols.unsafe_ptr(),boxes.unsafe_ptr(),0):return -1
    for p in range(81):
        let bits=bitcast[UInt32](Int32(board[p]))
        for b in range(4):out[p*4+b]=UInt8((bits>>UInt(b*8))&255)
    return 81
