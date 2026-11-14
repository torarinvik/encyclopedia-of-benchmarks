# Bounded Almabench draft; see package README for provenance.
# The pinned benchmark source states no rights reserved; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sin, cos, sqrt, atan2, asin
from std.memory import MutAnyOrigin, UnsafePointer

@extern("C")
fn fmod(value: Float64, divisor: Float64) -> Float64

comptime ALMA_DATA: InlineArray[Float64,600] = [
    0.3870983098, 0.0, 0.0, 0.72332982, 0.0, 0.0,
    1.0000010178, 0.0, 0.0, 1.5236793419, 3e-10, 0.0,
    5.2026032092, 1.9132e-06, -3.9e-09, 9.5549091915, -2.13896e-05, 4.44e-08,
    19.2184460618, -3.716e-07, 9.79e-08, 30.1103868694, -1.6635e-06, 6.86e-08,
    252.25090552, 5381016286.88982, -1.92789, 181.97980085, 2106641364.33548, 0.59381,
    100.46645683, 1295977422.83429, -2.04411, 355.43299958, 689050774.93988, 0.94264,
    34.35151874, 109256603.77991, -30.60378, 50.0774443, 43996098.55732, 75.61614,
    314.05500511, 15424811.93933, -1.75083, 304.34866548, 7865503.20744, 0.21103,
    0.2056317526, 0.0002040653, -2.8349e-06, 0.0067719164, -0.0004776521, 9.8127e-06,
    0.0167086342, -0.0004203654, -1.26734e-05, 0.0934006477, 0.0009048438, -8.0641e-06,
    0.0484979255, 0.0016322542, -4.71366e-05, 0.0555481426, -0.0034664062, -6.43639e-05,
    0.0463812221, -0.0002729293, 7.8913e-06, 0.009455747, 6.03263e-05, 0.0,
    77.45611904, 5719.1159, -4.83016, 131.563703, 175.4864, -498.48184,
    102.93734808, 11612.3529, 53.27577, 336.06023395, 15980.45908, -62.328,
    14.33120687, 7758.75163, 259.95938, 93.05723748, 20395.49439, 190.25952,
    173.00529106, 3215.56238, -34.09288, 48.12027554, 1050.71912, 27.39717,
    7.00498625, -214.25629, 0.28977, 3.39466189, -30.84437, -11.67836,
    0.0, 469.97289, -3.35053, 1.84972648, -293.31722, -8.1183,
    1.30326698, -71.5589, 11.95297, 2.48887878, 91.85195, -17.66225,
    0.77319689, -60.72723, 1.25759, 1.76995259, 8.12333, 0.08135,
    48.33089304, -4515.21727, -31.79892, 76.67992019, -10008.48154, -51.32614,
    174.87317577, -8679.27034, 15.34191, 49.55809321, -10620.90088, -230.57416,
    100.46440702, 6362.03561, 326.52178, 113.66550252, -9240.19942, -66.23743,
    74.00595701, 2669.15033, 145.93964, 131.78405702, -221.94322, -0.78728,
    69613.0, 75645.0, 88306.0, 59899.0, 15746.0, 71087.0,
    142173.0, 3086.0, 0.0, 21863.0, 32794.0, 26934.0,
    10931.0, 26250.0, 43725.0, 53867.0, 28939.0, 0.0,
    16002.0, 21863.0, 32004.0, 10931.0, 14529.0, 16368.0,
    15318.0, 32794.0, 0.0, 6345.0, 7818.0, 15636.0,
    7077.0, 8184.0, 14163.0, 1107.0, 4872.0, 0.0,
    1760.0, 1454.0, 1167.0, 880.0, 287.0, 2640.0,
    19.0, 2047.0, 1454.0, 574.0, 0.0, 880.0,
    287.0, 19.0, 1760.0, 1167.0, 306.0, 574.0,
    204.0, 0.0, 177.0, 1265.0, 4.0, 385.0,
    200.0, 208.0, 204.0, 0.0, 102.0, 106.0,
    4.0, 98.0, 1367.0, 487.0, 204.0, 0.0,
    4.0, -13.0, 11.0, -9.0, -9.0, -3.0,
    -1.0, 4.0, 0.0, -156.0, 59.0, -42.0,
    6.0, 19.0, -20.0, -10.0, -12.0, 0.0,
    64.0, -152.0, 62.0, -8.0, 32.0, -41.0,
    19.0, -11.0, 0.0, 124.0, 621.0, -145.0,
    208.0, 54.0, -57.0, 30.0, 15.0, 0.0,
    -23437.0, -2634.0, 6601.0, 6259.0, -1507.0, -1821.0,
    2620.0, -2115.0, -1489.0, 62911.0, -119919.0, 79336.0,
    17814.0, -24241.0, 12068.0, 8306.0, -4893.0, 8902.0,
    389061.0, -262125.0, -44088.0, 8387.0, -22976.0, -2093.0,
    -615.0, -9720.0, 6633.0, -412235.0, -157046.0, -31430.0,
    37817.0, -9740.0, -13.0, -7449.0, 9644.0, 0.0,
    -29.0, -1.0, 9.0, 6.0, -6.0, 5.0,
    4.0, 0.0, 0.0, -48.0, -125.0, -26.0,
    -37.0, 18.0, -13.0, -20.0, -2.0, 0.0,
    -150.0, -46.0, 68.0, 54.0, 14.0, 24.0,
    -28.0, 22.0, 0.0, -621.0, 532.0, -694.0,
    -20.0, 192.0, -94.0, 71.0, -73.0, 0.0,
    -14614.0, -19828.0, -5869.0, 1881.0, -4372.0, -2255.0,
    782.0, 930.0, 913.0, 139737.0, 0.0, 24667.0,
    51123.0, -5102.0, 7429.0, -4095.0, -1976.0, -9566.0,
    -138081.0, 0.0, 37205.0, -49039.0, -41901.0, -33872.0,
    -27037.0, -12474.0, 18797.0, 0.0, 28492.0, 133236.0,
    69654.0, 52322.0, -49577.0, -26430.0, -3593.0, 0.0,
    3086.0, 15746.0, 69613.0, 59899.0, 75645.0, 88306.0,
    12661.0, 2658.0, 0.0, 0.0, 21863.0, 32794.0,
    10931.0, 73.0, 4387.0, 26934.0, 1473.0, 2157.0,
    0.0, 0.0, 10.0, 16002.0, 21863.0, 10931.0,
    1473.0, 32004.0, 4387.0, 73.0, 0.0, 0.0,
    10.0, 6345.0, 7818.0, 1107.0, 15636.0, 7077.0,
    8184.0, 532.0, 10.0, 0.0, 19.0, 1760.0,
    1454.0, 287.0, 1167.0, 880.0, 574.0, 2640.0,
    19.0, 1454.0, 19.0, 574.0, 287.0, 306.0,
    1760.0, 12.0, 31.0, 38.0, 19.0, 574.0,
    4.0, 204.0, 177.0, 8.0, 31.0, 200.0,
    1265.0, 102.0, 4.0, 204.0, 4.0, 102.0,
    106.0, 8.0, 98.0, 1367.0, 487.0, 204.0,
    4.0, 102.0, 21.0, -95.0, -157.0, 41.0,
    -5.0, 42.0, 23.0, 30.0, 0.0, 0.0,
    -160.0, -313.0, -235.0, 60.0, -74.0, -76.0,
    -27.0, 34.0, 0.0, 0.0, -325.0, -322.0,
    -79.0, 232.0, -52.0, 97.0, 55.0, -41.0,
    0.0, 0.0, 2268.0, -979.0, 802.0, 602.0,
    -668.0, -33.0, 345.0, 201.0, -55.0, 0.0,
    7610.0, -4997.0, -7689.0, -5841.0, -2617.0, 1115.0,
    -748.0, -607.0, 6074.0, 354.0, -18549.0, 30125.0,
    20012.0, -730.0, 824.0, 23.0, 1289.0, -352.0,
    -14767.0, -2062.0, -135245.0, -14594.0, 4197.0, -4030.0,
    -5630.0, -2898.0, 2540.0, -306.0, 2939.0, 1986.0,
    89948.0, 2103.0, 8963.0, 2695.0, 3682.0, 1648.0,
    866.0, -154.0, -1963.0, -283.0, -342.0, 136.0,
    -23.0, 62.0, 66.0, -52.0, -33.0, 17.0,
    0.0, 0.0, 524.0, -149.0, -35.0, 117.0,
    151.0, 122.0, -71.0, -62.0, 0.0, 0.0,
    -105.0, -137.0, 258.0, 35.0, -116.0, -88.0,
    -112.0, -80.0, 0.0, 0.0, 854.0, -205.0,
    -936.0, -240.0, 140.0, -341.0, -97.0, -232.0,
    536.0, 0.0, -56980.0, 8016.0, 1012.0, 1448.0,
    -3024.0, -3710.0, 318.0, 503.0, 3767.0, 577.0,
    138606.0, -13478.0, -4964.0, 1441.0, -1319.0, -1482.0,
    427.0, 1236.0, -9167.0, -1918.0, 71234.0, -41116.0,
    5334.0, -4935.0, -1848.0, 66.0, 434.0, -1748.0,
    3780.0, -701.0, -47645.0, 11647.0, 2166.0, 3194.0,
    679.0, 0.0, -244.0, -419.0, -2531.0, 48.0
]

comptime ALMA_PI=3.14159265358979323846
comptime ALMA_MASS: InlineArray[Float64,8] = [6023600.0,408523.5,328900.5,3098710.0,1047.355,3498.5,22869.0,19314.0]

fn alma_table(offset: Int, width: Int, planet: Int, term: Int) -> Float64:
    return ALMA_DATA[offset+width*planet+term]

fn alma_remainder(value: Float64, divisor: Float64) -> Float64:
    return fmod(value,divisor)

fn alma_angle(value: Float64) -> Float64:
    var result=alma_remainder(value,2.0*ALMA_PI)
    if abs(result)>=ALMA_PI:
        result-=(-2.0*ALMA_PI if value<0.0 else 2.0*ALMA_PI)
    return result

fn alma_position(planet: Int, day: Int) -> (Float64,Float64,Float64,Float64,Float64,Float64):
    let t=Float64(day)/365250.0
    var axis=alma_table(0,3,planet,0)+(alma_table(0,3,planet,1)+alma_table(0,3,planet,2)*t)*t
    var longitude=(3600.0*alma_table(24,3,planet,0)+(alma_table(24,3,planet,1)+alma_table(24,3,planet,2)*t)*t)*(ALMA_PI/648000.0)
    let eccentricity=alma_table(48,3,planet,0)+(alma_table(48,3,planet,1)+alma_table(48,3,planet,2)*t)*t
    let perihelion=alma_angle((3600.0*alma_table(72,3,planet,0)+(alma_table(72,3,planet,1)+alma_table(72,3,planet,2)*t)*t)*(ALMA_PI/648000.0))
    let inclination=(3600.0*alma_table(96,3,planet,0)+(alma_table(96,3,planet,1)+alma_table(96,3,planet,2)*t)*t)*(ALMA_PI/648000.0)
    let node=alma_angle((3600.0*alma_table(120,3,planet,0)+(alma_table(120,3,planet,1)+alma_table(120,3,planet,2)*t)*t)*(ALMA_PI/648000.0))
    let phase=0.35953620*t
    for term in range(8):
        let a=alma_table(144,9,planet,term)*phase
        let l=alma_table(360,10,planet,term)*phase
        axis+=(alma_table(216,9,planet,term)*cos(a)+alma_table(288,9,planet,term)*sin(a))*0.0000001
        longitude+=(alma_table(440,10,planet,term)*cos(l)+alma_table(520,10,planet,term)*sin(l))*0.0000001
    let extra=alma_table(144,9,planet,8)*phase
    axis+=t*(alma_table(216,9,planet,8)*cos(extra)+alma_table(288,9,planet,8)*sin(extra))*0.0000001
    for term in range(8,10):
        let l=alma_table(360,10,planet,term)*phase
        longitude+=t*(alma_table(440,10,planet,term)*cos(l)+alma_table(520,10,planet,term)*sin(l))*0.0000001
    longitude=alma_remainder(longitude,2.0*ALMA_PI)
    let mean=longitude-perihelion
    var eccentric=mean+eccentricity*sin(mean)
    for _ in range(10):
        let delta=(mean-eccentric+eccentricity*sin(eccentric))/(1.0-eccentricity*cos(eccentric))
        eccentric+=delta
        if abs(delta)<1.0e-12: break
    let anomaly=2.0*atan2(sqrt((1.0+eccentricity)/(1.0-eccentricity))*sin(eccentric/2.0),cos(eccentric/2.0))
    let radius=axis*(1.0-eccentricity*cos(eccentric))
    let speed=0.01720209895*sqrt((1.0+1.0/ALMA_MASS[planet])/(axis*axis*axis))
    let half_sin=sin(inclination/2.0); let half_cos=cos(inclination/2.0)
    let nc=half_sin*cos(node); let ns=half_sin*sin(node)
    let angle=anomaly+perihelion; let s=sin(angle); let c=cos(angle)
    let correction=2.0*(ns*c-nc*s)
    let scale=axis/sqrt(1.0-eccentricity*eccentricity)
    let ms=(eccentricity*sin(perihelion)+s)*scale
    let mc=(eccentricity*cos(perihelion)+c)*scale
    let cross=2.0*ns*nc
    let vx=speed*((-1.0+2.0*ns*ns)*ms+cross*mc)
    let vy0=speed*((1.0-2.0*nc*nc)*mc-cross*ms)
    let vz0=speed*(2.0*half_cos*(ns*ms+nc*mc))
    let vy=vy0*0.9174820620691818-vz0*0.3977771559319137
    let vz=vy0*0.3977771559319137+vz0*0.9174820620691818
    let px=radius*(c-correction*ns)
    let py0=radius*(s+correction*nc); let pz0=radius*(-correction*half_cos)
    let py=py0*0.9174820620691818-pz0*0.3977771559319137
    let pz=py0*0.3977771559319137+pz0*0.9174820620691818
    let distance=sqrt(px*px+py*py+pz*pz)
    var ra=atan2(py,px)*(12.0/ALMA_PI)
    if ra<0.0: ra+=24.0
    return (ra,asin(pz/distance)*(180.0/ALMA_PI),distance,vx,vy,vz)

fn alma_micro_units(bits: UInt64) -> UInt64:
    # Multiply the binary significand by 1,000,000 in 32-bit limbs, then
    # perform exact round-to-nearest, ties-to-even at the binary exponent.
    let exponent=(bits >> 52) & UInt64(0x7ff)
    if exponent==0: return 0
    let significand=(bits & UInt64(0x000fffffffffffff)) | UInt64(0x0010000000000000)
    let shift=1075-Int(exponent)
    if shift>=74: return 0
    let low=(significand & UInt64(0xffffffff))*UInt64(1000000)
    let high=(significand >> 32)*UInt64(1000000)
    let middle=(low >> 32)+(high & UInt64(0xffffffff))
    let limb0=low & UInt64(0xffffffff)
    let limb1=middle & UInt64(0xffffffff)
    let limb2=(high >> 32)+(middle >> 32)
    var quotient=UInt64(0); var half=UInt64(0); var lower=False
    if shift<64:
        let part=shift-32
        quotient=(limb1 >> UInt(part)) | (limb2 << UInt(32-part))
        half=(limb1 >> UInt(part-1)) & 1
        lower=limb0!=0 or (limb1 & ((UInt64(1) << UInt(part-1))-1))!=0
    elif shift==64:
        quotient=limb2; half=limb1 >> 31
        lower=limb0!=0 or (limb1 & UInt64(0x7fffffff))!=0
    else:
        let part=shift-64
        quotient=limb2 >> UInt(part)
        half=(limb2 >> UInt(part-1)) & 1
        lower=limb0!=0 or limb1!=0 or (limb2 & ((UInt64(1) << UInt(part-1))-1))!=0
    if half!=0 and (lower or (quotient & 1)!=0): quotient+=1
    return quotient

fn alma_append_fixed(mut output: InlineArray[UInt8,248], mut used: Int, value: Float64):
    let bits=bitcast[UInt64](value)
    let units=alma_micro_units(bits & UInt64(0x7fffffffffffffff))
    if bits >> 63 != 0:
        output[used]=45; used+=1
    var whole=units // UInt64(1000000)
    var digits=InlineArray[UInt8,20](fill=0); var count=0
    while True:
        digits[count]=UInt8(48+whole%10); count+=1; whole //= 10
        if whole==0: break
    while count>0:
        count-=1; output[used]=digits[count]; used+=1
    output[used]=46; used+=1
    var fraction=units%UInt64(1000000); var place=UInt64(100000)
    while place>0:
        output[used]=UInt8(48+fraction//place); used+=1
        fraction%=place; place//=10

@export("almabench")
fn almabench(days: Int64, output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if days<1 or days>36525: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin](): return -2
    var positions=InlineArray[Float64,48](fill=0)
    for day in range(1,Int(days)+1):
        for planet in range(8):
            let p=alma_position(planet,day)
            positions[6*planet]=p[0]; positions[6*planet+1]=p[1]
            positions[6*planet+2]=p[2]; positions[6*planet+3]=p[3]
            positions[6*planet+4]=p[4]; positions[6*planet+5]=p[5]
    var staged=InlineArray[UInt8,248](fill=0); var used=0
    for planet in range(8):
        for column in range(3):
            alma_append_fixed(staged,used,positions[6*planet+column])
            staged[used]=10 if column==2 else 32
            used+=1
    if capacity<c_size_t(used): return -2
    for i in range(used): output[i]=staged[i]
    return Int64(used)
