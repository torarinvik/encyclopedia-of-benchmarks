from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rectangle_union_area")
fn rectangle_union_area(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=8:return -1
    for i in range(8):if v[i]< -1000000000 or v[i]>1000000000:return -1
    let ax=v[0];let ay=v[1];let ax2=v[2];let ay2=v[3];let bx=v[4];let by=v[5];let bx2=v[6];let by2=v[7]
    if ax>=ax2 or ay>=ay2 or bx>=bx2 or by>=by2:return -1
    let area1=(ax2-ax)*(ay2-ay);let area2=(bx2-bx)*(by2-by);let w=min(ax2,bx2)-max(ax,bx);let h=min(ay2,by2)-max(ay,by)
    let overlap=if w>0 and h>0:w*h else:0
    return area1+area2-overlap
