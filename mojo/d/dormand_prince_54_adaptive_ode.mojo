from std.ffi import c_size_t
from std.math import isfinite, pow, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT_LENGTH = 7

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

fn finite_value(value: Float64) -> Bool:
    isfinite(value)

fn rhs(id: Int, x: Float64, y: Float64) -> Float64:
    if id == 0: return y
    if id == 1: return x+y
    if id == 2: return sin(x)
    return 1.0

fn trial(id: Int,x: Float64,y: Float64,h: Float64,k1: Float64,
         y5: Float64&,error: Float64&,k7: Float64&) -> Bool:
    let k2=rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1))
    let k3=rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2))
    let k4=rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3))
    let k5=rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4))
    let k6=rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5))
    y5=y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6)
    k7=rhs(id,x+h,y5)
    error=h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)*k7)
    finite_value(y5) and finite_value(error) and finite_value(k7)

fn integrate(id: Int, initial_y: Float64, initial_x: Float64, ending: Float64,
             exponent: Int, attempts: Int, result: Float64&) -> Int64:
    let tolerance=pow(10.0,Float64(-exponent))
    var x=initial_x
    var y=initial_y
    var h=min((ending-initial_x)/4.0,0.25)
    var k1=rhs(id,x,y)
    for _ in range(attempts):
        let remaining=ending-x
        if remaining<=0.0:
            result=y
            return 1
        let step=min(min(h,0.25),remaining)
        if step<=0.0 or x+step==x: return -3
        var y5: Float64=0.0
        var error: Float64=0.0
        var k7: Float64=0.0
        if not trial(id,x,y,step,k1,y5,error,k7): return -3
        let scale=tolerance*(1.0+max(abs(y),abs(y5)))
        let norm=abs(error)/scale
        if not isfinite(norm): return -3
        if norm<=1.0:
            if step==remaining: x=ending
            else: x+=step
            y=y5
            k1=k7
            if x>=ending:
                result=y
                return 1 if finite_value(y) else -3
        var factor: Float64=5.0
        if norm!=0.0: factor=0.9*pow(norm,-0.2)
        factor=min(5.0,max(0.2,factor))
        h=step*factor
    return -3

@export("dormand_prince_54_adaptive_ode")
fn dormand_prince_54_adaptive_ode(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or input_length!=6 or input_length>MAX_INPUT_LENGTH: return -1
    let id_raw=input[0];let y_raw=input[1];let x_raw=input[2];let end_raw=input[3];let exponent_raw=input[4];let attempts_raw=input[5]
    if not exact_integer(id_raw,0,3) or not exact_integer(y_raw,-1000,1000) or not exact_integer(x_raw,-1000,1000) or not exact_integer(end_raw,-1000,1000) or not exact_integer(exponent_raw,8,9) or not exact_integer(attempts_raw,64,128): return -1
    if end_raw<=x_raw: return -1
    if output==UnsafePointer[Float64,MutAnyOrigin]() or output_capacity<1: return -2
    var result: Float64=0.0
    let status=integrate(Int(id_raw),y_raw/1000.0,x_raw/1000.0,end_raw/1000.0,Int(exponent_raw),Int(attempts_raw),result)
    if status!=1 or not finite_value(result): return -3
    output[0]=result
    return 1
