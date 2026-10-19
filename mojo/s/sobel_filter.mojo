from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import atan2, sqrt

fn sobel_write_f64(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("sobel_filter")
fn sobel_filter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>258:return -1
    let side64=input[0]
    if side64<3 or side64>16:return -1
    let side=Int(side64);let pixels=side*side
    if length!=c_size_t(pixels+1):return -1
    var image=InlineArray[Int32,256](fill=0)
    for i in range(pixels):
        if input[i+1]<0 or input[i+1]>255:return -1
        image[i]=Int32(input[i+1])
    var gx_values=InlineArray[Int32,256](fill=0);var gy_values=InlineArray[Int32,256](fill=0)
    var max_x=0;var max_y=0
    for y in range(side):
        for x in range(side):
            var gx=0;var gy=0
            for ky in range(3):
                var sy=y+ky-1
                if sy<0:sy=0
                if sy>=side:sy=side-1
                for kx in range(3):
                    var sx=x+kx-1
                    if sx<0:sx=0
                    if sx>=side:sx=side-1
                    let pixel=Int(image[sy*side+sx]);let kernel=ky*3+kx
                    if kernel==0 or kernel==6:gx-=pixel
                    elif kernel==2 or kernel==8:gx+=pixel
                    elif kernel==3:gx-=2*pixel
                    elif kernel==5:gx+=2*pixel
                    if kernel==0 or kernel==2:gy+=pixel
                    elif kernel==6 or kernel==8:gy-=pixel
                    elif kernel==1:gy+=2*pixel
                    elif kernel==7:gy-=2*pixel
            if gx<0:gx= -gx
            if gy<0:gy= -gy
            let index=y*side+x;gx_values[index]=Int32(gx);gy_values[index]=Int32(gy)
            if gx>max_x:max_x=gx
            if gy>max_y:max_y=gy
    if max_x==0 or max_y==0:return -1
    var scaled_x=InlineArray[Float64,256](fill=0);var scaled_y=InlineArray[Float64,256](fill=0);var magnitude=InlineArray[Float64,256](fill=0)
    var max_magnitude=Float64(0.0)
    for i in range(pixels):
        scaled_x[i]=(Float64(gx_values[i])*255.0)/Float64(max_x)
        scaled_y[i]=(Float64(gy_values[i])*255.0)/Float64(max_y)
        magnitude[i]=sqrt((scaled_x[i]*scaled_x[i])+(scaled_y[i]*scaled_y[i]))
        if magnitude[i]>max_magnitude:max_magnitude=magnitude[i]
    if max_magnitude==0:return -1
    for i in range(pixels):
        let normalized=(magnitude[i]*255.0)/max_magnitude
        magnitude[i]=Float64(Int(UInt8(Int(normalized))))
    let elements=2*pixels;let bytes=elements*8
    if elements>512 or bytes>4096:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(pixels):
        sobel_write_f64(output,i*8,magnitude[i])
        sobel_write_f64(output,(pixels+i)*8,atan2(scaled_y[i],scaled_x[i]))
    return Int64(elements)
