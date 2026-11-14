from std.collections import List
from std.ffi import c_size_t
from std.math import abs, floor, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

fn power_optimize(p0: Float64, q0: Float64, pi_r: Float64, pi_i: Float64) -> (Float64, Float64):
    var p = p0; var q = q0
    let hmag = sqrt(Float64(26.0))
    let hx = 1.0/hmag; let hy = -5.0/hmag
    let h = p-5.0*q
    if abs(h) > 0.000001:
        let t = h/hmag
        p -= t*hx; q -= t*hy
    let g = p*p+q*q-0.8
    if g > 0.000001:
        var gx = 2.0*p; var gy = 2.0*q
        var magnitude = sqrt(gx*gx+gy*gy)
        gx /= magnitude; gy /= magnitude
        let dot = gx*hx+gy*hy
        gx -= dot*hx; gy -= dot*hy
        let norm = sqrt(gx*gx+gy*gy)
        gx /= norm; gy /= norm
        var factor = Float64(0.0)
        if 1.0-dot*dot >= 0.0: factor = sqrt(1.0-dot*dot)
        magnitude *= factor
        let t = g/magnitude
        p -= t*gx; q -= t*gy
    let pinv = 1.0/(1.0+p); let qinv = 1.0/(1.0+q)
    let px = pinv-pi_r; let qy = qinv-pi_i
    var magnitude = sqrt(px*px+qy*qy)
    var fx = px/magnitude; var fy = qy/magnitude
    let ddx = -pinv*pinv*px/magnitude; let ddy = -qinv*qinv*qy/magnitude
    magnitude /= abs(fx*ddx+fy*ddy)
    let dot = fx*hx+fy*hy
    fx -= dot*hx; fy -= dot*hy
    let norm = sqrt(fx*fx+fy*fy)
    fx /= norm; fy /= norm
    var factor = Float64(0.0)
    if 1.0-dot*dot >= 0.0: factor = sqrt(1.0-dot*dot)
    magnitude *= factor
    let grad_x = 2.0*p; let grad_y = 2.0*q
    let gnorm = sqrt(grad_x*grad_x+grad_y*grad_y)
    let total = fx*(grad_x/gnorm)+fy*(grad_y/gnorm)
    if total > 0.0:
        let maximum = -(p*p+q*q-0.8)/total
        if magnitude > maximum: magnitude = maximum
    p += magnitude*fx; q += magnitude*fy
    return (p,q)

fn power_voltage(p0: Float64, q0: Float64, resistance: Float64, reactance: Float64) -> (Float64, Float64, Float64, Float64):
    let a = resistance*resistance+reactance*reactance
    let b = 2.0*resistance*reactance*q0-2.0*reactance*reactance*p0-resistance
    let t = resistance*q0-reactance*p0
    let c = t*t+resistance*p0
    let p = (-b-sqrt(b*b-4.0*a*c))/(2.0*a)
    let q = q0+((p-p0)*reactance)/resistance
    let aa = 2.0*resistance*p; let bb = 2.0*reactance*q
    return (p,q,aa/(1.0-aa-bb),bb/(1.0-aa-bb))

@export("olden_power")
fn olden_power(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let lv = input[0]; let pv = input[1]
    if lv < 1 or lv > 4 or pv < 0 or pv > 4: return -1
    let leaves = Int(lv)
    var leaf_p = List[Float64](length=leaves, fill=1.0)
    var leaf_q = List[Float64](length=leaves, fill=1.0)
    var ba = Float64(0.0); var bb = Float64(0.0)
    var la = Float64(0.0); var lb = Float64(0.0)
    for _ in range(Int(pv)):
        let lr = 0.8+la*(0.8+(0.16*0.000001)/(1.0/300000.0))
        let li = 0.16+lb*(0.16+(0.8*(1.0/300000.0))/0.000001)
        let br = lr+ba*(0.8+(0.16*0.00002)/0.0001)
        let bi = li+bb*(0.16+(0.8*0.0001)/0.00002)
        var bp = Float64(0.0); var bq = Float64(0.0)
        for leaf in range(leaves):
            let (p,q) = power_optimize(leaf_p[leaf],leaf_q[leaf],br,bi)
            leaf_p[leaf] = p; leaf_q[leaf] = q
            if p < 0.0: leaf_p[leaf] = 0.0; leaf_q[leaf] = 0.0
            bp += leaf_p[leaf]; bq += leaf_q[leaf]
        let (p,q,alpha,beta) = power_voltage(bp,bq,0.0001,0.00002)
        ba = alpha; bb = beta
        let (_,_,lalpha,lbeta) = power_voltage(p,q,1.0/300000.0,0.000001)
        la = lalpha; lb = lbeta
    var value = Int64(leaves)*pv
    for leaf in range(leaves):
        value += Int64(floor(leaf_p[leaf]*1000.0+0.5))
        value += 2*Int64(floor(leaf_q[leaf]*1000.0+0.5))
    value += Int64(floor(ba*1000.0+0.5))+2*Int64(floor(bb*1000.0+0.5))
    value += Int64(floor(la*1000.0+0.5))+2*Int64(floor(lb*1000.0+0.5))
    return value
