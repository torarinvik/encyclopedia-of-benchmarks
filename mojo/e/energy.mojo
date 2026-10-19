from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime ENERGY_FACTORS:InlineArray[Float64,55]=[1.0,1000.0,1000000.0,1000000000.0,0.001,1.0e-6,1.0e-9,1.0e-18,1.0,3600.0,1000.0,3600000.0,3600000000.0,3600000000000.0,1.0,1.0e-7,1.0e-7,4186.8,4186800.0,4.1868,4186.8,4.184,4184.0,1.602176634e-19,1.602176634e-16,1.602176634e-13,1055.05585262,1054.3499999744,1055055852.62,1.3558179483,1.3558179483,0.112984829,0.112984829,0.0070615518,0.0070615518,0.04214011,2684519.5368856,2647795.5,9.8066499997,0.0980665,9.8066499997,0.00980665,9.80665e-5,105505600.0,105505600.0,105480400.0,12660670.23144,40197627984.822,6383087908.3509,4184000000.0,4184000000000.0,4.184e15,4.184e18,4.3597482e-18,2.1798741e-18]
@export("energy")
fn energy(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1.0e300
    let value=values[0];let from=values[1];let to=values[2]
    if value< -1000000000000 or value>1000000000000 or from<0 or from>54 or to<0 or to>54:return -1.0e300
    let physical=Float64(value)/1000000.0
    let joules=physical*ENERGY_FACTORS[Int(from)]
    return joules/ENERGY_FACTORS[Int(to)]
