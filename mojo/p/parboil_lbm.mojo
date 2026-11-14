# Clean-room Parboil D3Q19 profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn lbm_factor(u: Float32, positive: Bool, u2: Float32) -> Float32:
    var value = Float32(4.5)*u
    if positive: value += Float32(3.0)
    else: value -= Float32(3.0)
    value = u*value
    value = Float32(1.0)+value
    return value-u2

fn lbm_collide(source: Float32, rho: Float32, factor: Float32, weight: Float64) -> Float32:
    let omega = Float32(1.95)
    let base = (Float32(1.0)-omega)*source
    var equilibrium = weight*Float64(omega)
    equilibrium *= Float64(rho)
    equilibrium *= Float64(factor)
    return Float32(Float64(base)+equilibrium)

@export("parboil_lbm")
fn parboil_lbm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 19: return -1
    var f = List[Float32](capacity=19)
    var any = False
    for q in range(19):
        let value = input[q]
        if value < 0 or value > 100000: return -1
        if value != 0: any = True
        f.append(Float32(value)/Float32(1000000.0))
    if not any: return -1
    var dx = List[Int](capacity=19); var dy = List[Int](capacity=19); var dz = List[Int](capacity=19); var opposite = List[Int](capacity=19)
    dx.append(0); dx.append(0); dx.append(0); dx.append(1); dx.append(-1); dx.append(0); dx.append(0); dx.append(1); dx.append(-1); dx.append(1); dx.append(-1); dx.append(0); dx.append(0); dx.append(0); dx.append(0); dx.append(1); dx.append(1); dx.append(-1); dx.append(-1)
    dy.append(0); dy.append(1); dy.append(-1); dy.append(0); dy.append(0); dy.append(0); dy.append(0); dy.append(1); dy.append(1); dy.append(-1); dy.append(-1); dy.append(1); dy.append(1); dy.append(-1); dy.append(-1); dy.append(0); dy.append(0); dy.append(0); dy.append(0)
    dz.append(0); dz.append(0); dz.append(0); dz.append(0); dz.append(0); dz.append(1); dz.append(-1); dz.append(0); dz.append(0); dz.append(0); dz.append(0); dz.append(1); dz.append(-1); dz.append(1); dz.append(-1); dz.append(1); dz.append(-1); dz.append(1); dz.append(-1)
    opposite.append(0); opposite.append(2); opposite.append(1); opposite.append(4); opposite.append(3); opposite.append(6); opposite.append(5); opposite.append(10); opposite.append(9); opposite.append(8); opposite.append(7); opposite.append(14); opposite.append(13); opposite.append(12); opposite.append(11); opposite.append(18); opposite.append(17); opposite.append(16); opposite.append(15)
    var rho = f[0]
    for q in range(1,19): rho += f[q]
    var ux = f[3]
    ux -= f[4]; ux += f[7]; ux -= f[8]; ux += f[9]; ux -= f[10]; ux += f[15]; ux += f[16]; ux -= f[17]; ux -= f[18]
    var uy = f[1]
    uy -= f[2]; uy += f[7]; uy += f[8]; uy -= f[9]; uy -= f[10]; uy += f[11]; uy += f[12]; uy -= f[13]; uy -= f[14]
    var uz = f[5]
    uz -= f[6]; uz += f[11]; uz -= f[12]; uz += f[13]; uz -= f[14]; uz += f[15]; uz -= f[16]; uz += f[17]; uz -= f[18]
    ux /= rho; uy /= rho; uz /= rho
    var u2 = ux*ux
    u2 += uy*uy; u2 += uz*uz; u2 = Float32(1.5)*u2
    var post = List[Float32](length=19, fill=0.0)
    post[0] = lbm_collide(f[0],rho,Float32(1.0)-u2,1.0/3.0)
    post[1] = lbm_collide(f[1],rho,lbm_factor(uy,True,u2),1.0/18.0)
    post[2] = lbm_collide(f[2],rho,lbm_factor(uy,False,u2),1.0/18.0)
    post[3] = lbm_collide(f[3],rho,lbm_factor(ux,True,u2),1.0/18.0)
    post[4] = lbm_collide(f[4],rho,lbm_factor(ux,False,u2),1.0/18.0)
    post[5] = lbm_collide(f[5],rho,lbm_factor(uz,True,u2),1.0/18.0)
    post[6] = lbm_collide(f[6],rho,lbm_factor(uz,False,u2),1.0/18.0)
    var cu = List[Float32](capacity=12)
    cu.append(ux+uy); cu.append(-ux+uy); cu.append(ux-uy); cu.append(-ux-uy)
    cu.append(uy+uz); cu.append(uy-uz); cu.append(-uy+uz); cu.append(-uy-uz)
    cu.append(ux+uz); cu.append(ux-uz); cu.append(-ux+uz); cu.append(-ux-uz)
    for q in range(7,19): post[q] = lbm_collide(f[q],rho,lbm_factor(cu[q-7],True,u2),1.0/36.0)
    var destination = List[Float32](length=125*19, fill=0.0)
    for z in range(3):
        for y in range(3):
            for x in range(3):
                for q in range(19):
                    var weight = Float32(1.0/36.0)
                    if q == 0: weight = Float32(1.0/3.0)
                    elif q <= 6: weight = Float32(1.0/18.0)
                    destination[(((z+1)*5+y+1)*5+x+1)*19+q] = weight
    for z in range(3):
        for y in range(3):
            for x in range(3):
                let obstacle = x != 1 or y != 1 or z != 1
                for q in range(19):
                    var outgoing = post[q]
                    if obstacle:
                        let source_q = opposite[q]
                        outgoing = Float32(1.0/36.0)
                        if source_q == 0: outgoing = Float32(1.0/3.0)
                        elif source_q <= 6: outgoing = Float32(1.0/18.0)
                    let index = ((((z+dz[q]+1)*5+y+dy[q]+1)*5+x+dx[q]+1)*19+q)
                    destination[index] = outgoing
    var checksum = Int64(0)
    for z in range(3):
        for y in range(3):
            for x in range(3):
                let cell = x+3*y+9*z
                for q in range(19):
                    let value = destination[(((z+1)*5+y+1)*5+x+1)*19+q]*Float32(1000000.0)
                    var magnitude = value
                    if magnitude < 0.0: magnitude = -magnitude
                    var rounded = Int64(magnitude)
                    if magnitude-Float32(rounded) >= Float32(0.5): rounded += 1
                    if value < 0.0: rounded = -rounded
                    checksum += Int64(cell+1)*rounded
    return checksum
