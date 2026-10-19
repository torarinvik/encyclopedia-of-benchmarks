from std.math import pow

fn energy_factor(code:Int)->Float64:
    if code==0 or code==4 or code==7:return 1.0
    if code==1:return 1000.0
    if code==2:return 1000000.0
    if code==3:return 1000000000.0
    if code==5:return 3600.0
    if code==6:return 3600000.0
    if code==8:return 4186.8
    if code==9:return 4186800.0
    if code==10:return 1.602176634e-19
    if code==11:return 1055.05585
    if code==12:return 1.355818
    return 0.0
@export("energy_conversions")
fn energy_conversions(value:Float64,from_code:Float64,to_code:Float64) abi("C")->Float64:
    if value!=value or from_code!=from_code or to_code!=to_code or value< -1000000.0 or value>1000000.0:return -1.0e300
    if Float64(Int64(from_code))!=from_code or Float64(Int64(to_code))!=to_code:return -1.0e300
    let source=energy_factor(Int(from_code));let target=energy_factor(Int(to_code))
    if source==0.0 or target==0.0:return -1.0e300
    return (value*source)/target
