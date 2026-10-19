from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime DIGITS:UInt16=1022

fn mrv_single(mask:UInt16)->Bool:
    return mask!=0 and (mask & (mask-1))==0
fn mrv_eliminate(c:UnsafePointer[UInt16,MutAnyOrigin],cell:Int,removed:UInt16)->Bool:
    if (c[cell]&removed)==0:return True
    c[cell]=c[cell] & (DIGITS ^ removed)
    let remain=c[cell]
    if remain==0:return False
    if mrv_single(remain):
        for peer in range(81):
            if peer==cell:continue
            let same_row=cell/9==peer/9;let same_col=cell%9==peer%9
            let same_box=cell/27==peer/27 and (cell%9)/3==(peer%9)/3
            if (same_row or same_col or same_box) and not mrv_eliminate(c,peer,remain):return False
    let row=cell/9;let col=cell%9;let br=(row/3)*3;let bc=(col/3)*3
    for unit in range(3):
        var place=0;var count=0
        for off in range(9):
            var at=0
            if unit==0:at=row*9+off
            elif unit==1:at=off*9+col
            else:at=(br+off/3)*9+bc+off%3
            if (c[at]&removed)!=0:place=at;count+=1
        if count==0:return False
        if count==1 and not mrv_assign(c,place,removed):return False
    return True
fn mrv_assign(c:UnsafePointer[UInt16,MutAnyOrigin],cell:Int,selected:UInt16)->Bool:
    if (c[cell]&selected)==0:return False
    for digit in range(1,10):
        let bit=UInt16(1)<<UInt(digit)
        if bit!=selected and (c[cell]&bit)!=0:
            if not mrv_eliminate(c,cell,bit):return False
    return True
fn mrv_search(c:UnsafePointer[UInt16,MutAnyOrigin])->Bool:
    var best=81;var best_n=10
    for cell in range(81):
        var count=0;var bits=c[cell]
        for d in range(1,10):if (bits & (UInt16(1)<<UInt(d)))!=0:count+=1
        if count==0:return False
        if count>1 and count<best_n:best=cell;best_n=count
    if best==81:return True
    for d in range(1,10):
        let bit=UInt16(1)<<UInt(d)
        if (c[best]&bit)==0:continue
        var branch=InlineArray[UInt16,81](fill=0)
        for i in range(81):branch[i]=c[i]
        if mrv_assign(branch.unsafe_ptr(),best,bit) and mrv_search(branch.unsafe_ptr()):
            for i in range(81):c[i]=branch[i]
            return True
    return False

@export("sudoku_solver_mrv")
fn sudoku_solver_mrv(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=81:return -1
    var c=InlineArray[UInt16,81](fill=DIGITS)
    for cell in range(81):if v[cell]<0 or v[cell]>9:return -1
    for cell in range(81):
        if v[cell]!=0 and not mrv_assign(c.unsafe_ptr(),cell,UInt16(1)<<UInt(v[cell])):return -1
    if not mrv_search(c.unsafe_ptr()):return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<324:return -2
    for cell in range(81):
        var digit=1
        while (c[cell]&(UInt16(1)<<UInt(digit)))==0:digit+=1
        for b in range(4):out[cell*4+b]=UInt8((UInt32(digit)>>(UInt(b*8)))&255)
    return 81
