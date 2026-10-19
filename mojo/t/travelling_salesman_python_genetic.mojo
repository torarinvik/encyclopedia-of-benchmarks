from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite
@export("travelling_salesman_python_genetic")
fn travelling_salesman_python_genetic(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=8:return -1
    for i in range(8):
        if not isfinite(a[i]):return -1
    if a[0]<2.0 or a[0]>8.0 or Float64(Int64(a[0]))!=a[0] or Int64(a[0])%2!=0 or a[1]<0.0 or a[1]>12.0 or Float64(Int64(a[1]))!=a[1] or a[2]<0.0 or a[2]>1.0 or a[3]<0.0 or a[3]>1.0:return -1
    for i in range(4,8):if a[i]< -16.0 or a[i]>16.0 or Float64(Int64(a[i]))!=a[i]:return -1
    if a[4]==a[6] and a[5]==a[7]:return -1
    let dx=a[6]-a[4];let dy=a[7]-a[5];let distance=sqrt(dx*dx+dy*dy)*2.0
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<5:return -2
    o[0]=3.0;o[1]=0.0;o[2]=1.0;o[3]=0.0;o[4]=distance;return 5
