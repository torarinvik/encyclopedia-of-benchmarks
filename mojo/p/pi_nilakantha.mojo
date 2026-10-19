@export("pi_nilakantha")
fn pi_nilakantha(input:Float64) abi("C")->Float64:
    if not is_finite(input) or input<0.0 or input>500.0 or input!=Float64(Int(input)):return -1.0
    let iterations=Int(input);var pi=3.0;var divisor=2
    for i in range(iterations):let term=4.0/Float64(divisor*(divisor+1)*(divisor+2));if i%2==0:pi+=term else:pi-=term;divisor+=2
    return pi
