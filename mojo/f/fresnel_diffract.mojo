from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
from std.collections import InlineArray

@export("fresnel_diffract")
fn fresnel_diffract(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,
                    output:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length!=12 or input[0]!=4.0 or input[1]!=1.0 or input[2]!=1.0 or input[3]!=16.0:return -1
    for i in range(4,12):
        if not isfinite(input[i]) or input[i]<-100.0 or input[i]>100.0:return -1
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<8:return -2
    var xr=InlineArray[Float64,4](fill=0.0);var xi=InlineArray[Float64,4](fill=0.0)
    xr[0]=input[6];xr[1]=input[7];xr[2]=input[4];xr[3]=input[5]
    xi[0]=input[10];xi[1]=input[11];xi[2]=input[8];xi[3]=input[9]
    var fr=InlineArray[Float64,4](fill=0.0);var fi=InlineArray[Float64,4](fill=0.0)
    for k in range(4):
        for j in range(4):
            let t=(k*j)&3
            let cr=Float64(1 if t==0 else -1 if t==2 else 0)
            let si=Float64(-1 if t==1 else 1 if t==3 else 0)
            fr[k]+=xr[j]*cr-xi[j]*si
            fi[k]+=xr[j]*si+xi[j]*cr
    for k in range(1,4,2):fr[k]= -fr[k];fi[k]= -fi[k]
    var zr=InlineArray[Float64,4](fill=0.0);var zi=InlineArray[Float64,4](fill=0.0)
    for j in range(4):
        for k in range(4):
            let t=(k*j)&3
            let cr=Float64(1 if t==0 else -1 if t==2 else 0)
            let si=Float64(-1 if t==1 else 1 if t==3 else 0)
            let s= -si
            zr[j]+=(fr[k]*cr-fi[k]*s)*0.25
            zi[j]+=(fr[k]*s+fi[k]*cr)*0.25
    output[0]=zr[2];output[1]=zr[3];output[2]=zr[0];output[3]=zr[1]
    output[4]=zi[2];output[5]=zi[3];output[6]=zi[0];output[7]=zi[1]
    return 8
