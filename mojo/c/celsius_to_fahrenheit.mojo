@export("celsius_to_fahrenheit")
fn celsius_to_fahrenheit(celsius: Float64) abi("C") -> Float64:
    return (celsius * 9.0 / 5.0) + 32.0
