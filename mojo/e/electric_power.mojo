@export("electric_power")
fn electric_power(voltage: Float64, current: Float64, power: Float64) abi("C") -> Float64:
    if voltage < -10000.0 or voltage > 10000.0 or current < -10000.0 or current > 10000.0 or power < 0.0 or power > 100000000.0: return -1.0e300
    if Float64(Int64(voltage))!=voltage or Float64(Int64(current))!=current or Float64(Int64(power))!=power: return -1.0e300
    var zeros=0
    if voltage==0.0: zeros+=1
    if current==0.0: zeros+=1
    if power==0.0: zeros+=1
    if zeros != 1: return -1.0e300
    if voltage==0.0: return power/current
    if current==0.0: return power/voltage
    return abs(voltage*current)
