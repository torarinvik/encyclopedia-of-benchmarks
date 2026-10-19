from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("weddles_rule")
fn weddles_rule(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<9 or n>387:return -1.0e300
    let panels=a[0];let step=a[1]
    if panels<1 or panels>64 or n!=c_size_t(6*panels+3) or step< -1000000000 or step>1000000000:return -1.0e300
    let samples=Int(6*panels+1);var weighted:Float64=0.0
    for i in range(1,samples-1):
        let y=a[i+2]
        if y< -1000000 or y>1000000:return -1.0e300
        let weight=if i%2==0 and i%3!=0 then 1 else (if i%2!=0 and i%3!=0 then 5 else (if i%6==0 then 2 else 6))
        weighted+=Float64(weight)*(Float64(y)/1000000.0)
    let first=a[2];let last=a[samples+1]
    if first< -1000000 or first>1000000 or last< -1000000 or last>1000000:return -1.0e300
    let step_size=Float64(step)/1000000000.0
    return 0.3*step_size*(weighted+Float64(first)/1000000.0+Float64(last)/1000000.0)
