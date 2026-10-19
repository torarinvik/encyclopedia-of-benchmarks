from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("n_in_a_row_board_status")
fn n_in_a_row_board_status(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>258 or a[0]<2 or a[0]>16:return -1
    let sz=Int(a[0]);let player=a[1]
    if (player!=1 and player!=2) or n!=c_size_t(2+sz*sz):return -1
    var empty=False;var b=InlineArray[Int64,256]()
    for i in range(sz*sz):let v=a[2+i];if v<0 or v>2:return -1;b[i]=v;if v==0:empty=True
    for i in range(sz):
        var row=True;var col=True;for j in range(sz):if b[i*sz+j]!=player:row=False;if b[j*sz+i]!=player:col=False
        if row or col:return 1
    var d1=True;var d2=True
    for i in range(sz):if b[i*sz+i]!=player:d1=False;if b[i*sz+(sz-1-i)]!=player:d2=False
    if d1 or d2:return 1
    return 0 if empty else 2
