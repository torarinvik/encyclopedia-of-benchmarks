from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor
fn wus_frac(x:Float64)->Float64:return x-floor(x)
fn wus_rev(x:Float64)->Float64:return 1.0-wus_frac(x)
fn wus_add(inout xs:InlineArray[Int64,258],inout ys:InlineArray[Int64,258],inout ins:InlineArray[Float64,258],inout n:Int,x0:Int64,y0:Int64,intensity:Float64,steep:Bool):
    let x=y0 if steep else x0;let y=x0 if steep else y0
    xs[n]=x;ys[n]=y;ins[n]=min(1.0,max(0.0,intensity));n+=1
fn wus_endpoint(inout xs:InlineArray[Int64,258],inout ys:InlineArray[Int64,258],inout ins:InlineArray[Float64,258],inout n:Int,x:Int64,y:Int64,yend:Float64,gap:Float64,steep:Bool):
    let base=Int64(floor(yend));let f=wus_frac(yend)
    wus_add(xs,ys,ins,n,x,base,wus_rev(yend)*gap,steep)
    wus_add(xs,ys,ins,n,x,base+1,f*gap,steep)
fn wus_i32(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let bits=bitcast[UInt32](Int32(v));for b in range(4):o[p+b]=UInt8((bits>>UInt(8*b))&255)
@export("wus_line")
fn wus_line(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    for i in range(4):if a[i]< -64 or a[i]>64:return -1
    var x0=a[0];var y0=a[1];var x1=a[2];var y1=a[3]
    let steep=abs(y1-y0)>abs(x1-x0)
    if steep:let tx=x0;x0=y0;y0=tx;let tx2=x1;x1=y1;y1=tx2
    if x0>x1:let tx=x0;x0=x1;x1=tx;let ty=y0;y0=y1;y1=ty
    let dx=Float64(x1-x0);let dy=Float64(y1-y0);let gradient=1.0 if dx==0.0 else dy/dx
    let xend0=floor(Float64(x0)+0.5);let yend0=Float64(y0)+gradient*(xend0-Float64(x0));let px0=Int64(xend0)
    let xgap0=wus_rev(Float64(x0)+0.5)
    let xend1=floor(Float64(x1)+0.5);let yend1=Float64(y1)+gradient*(xend1-Float64(x1));let px1=Int64(xend1)
    let xgap1=wus_frac(Float64(x1)+0.5)
    var xs=InlineArray[Int64,258]();var ys=InlineArray[Int64,258]();var intensities=InlineArray[Float64,258]();var count=0
    wus_endpoint(xs,ys,intensities,count,px0,Int64(floor(yend0)),yend0,xgap0,steep)
    wus_endpoint(xs,ys,intensities,count,px1,Int64(floor(yend1)),yend1,xgap1,steep)
    var inter=yend0+gradient
    for x in range(px0+1,px1):
        let yf=Int64(floor(inter));let f=wus_frac(inter)
        wus_add(xs,ys,intensities,count,x,yf,wus_rev(inter),steep)
        wus_add(xs,ys,intensities,count,x,yf+1,f,steep)
        inter+=gradient
    let bytes=count*16
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        wus_i32(o,i*16,xs[i]);wus_i32(o,i*16+4,ys[i]);let bits=bitcast[UInt64](intensities[i]);for b in range(8):o[i*16+8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
