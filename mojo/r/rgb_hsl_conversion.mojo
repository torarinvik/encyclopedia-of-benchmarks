from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("rgb_hsl_conversion")
fn rgb_hsl_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    for i in range(3):if v[i]<0 or v[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<4:return -2
    let r=Float64(v[0])/255.0;let g=Float64(v[1])/255.0;let b=Float64(v[2])/255.0
    let minc=if r<g:if r<b:r else:b else:if g<b:g else:b
    let maxc=if r>g:if r>b:r else:b else:if g>b:g else:b
    let channel=if maxc==g:1 elif maxc==b:2 else:0
    let lum=(minc+maxc)/2.0;var sat:Float64=0.0
    if minc!=maxc:if lum<=0.5:sat=(maxc-minc)/(maxc+minc) else:sat=(maxc-minc)/(2.0-maxc-minc)
    var hue:Float64=0.0
    if sat!=0.0:
        if channel==0:hue=(g-b)/(maxc-minc)
        elif channel==1:hue=2.0+(b-r)/(maxc-minc)
        else:hue=4.0+(r-g)/(maxc-minc)
    hue*=60.0;if hue<0.0:hue+=360.0
    let h=UInt32(Int(hue+0.5));o[0]=UInt8(h&UInt32(255));o[1]=UInt8((h>>8)&UInt32(255));o[2]=UInt8(Int(sat*100.0+0.5));o[3]=UInt8(Int(lum*100.0+0.5));return 4
