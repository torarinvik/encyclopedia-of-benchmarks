from std.math import pow

@export("equated_monthly_installments")
fn equated_monthly_installments(principal:Float64,rate:Float64,years:Float64) abi("C")->Float64:
    if principal!=principal or rate!=rate or years!=years or principal<=0.0 or principal>1000000.0 or rate<0.0001 or rate>0.2 or years<1.0 or years>30.0 or Float64(Int64(years))!=years:return -1.0e300
    let monthly=rate/12.0;let payments=years*12.0;let factor=pow(1.0+monthly,payments)
    return principal*monthly*factor/(factor-1.0)
