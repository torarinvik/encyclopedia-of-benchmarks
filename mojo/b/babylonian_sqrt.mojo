@export("babylonian_sqrt")
fn babylonian_sqrt(input: Float64) abi("C") -> Float64:
    if not (input >= 0.0 and input <= 1000000.0):
        return -1.0
    if input == 0.0:
        return 0.0
    var estimate = input / 2.0
    while 0.000001 <= abs(estimate * estimate - input):
        estimate = 0.5 * (estimate + input / estimate)
    return estimate
