// Independent bounded port of the classic five-body solar-system kernel.
import math
struct Body { mut: x f64; y f64; z f64; vx f64; vy f64; vz f64; mass f64 }
fn put_f64(mut outp &u8, off int, value f64) {
    bits := u64(math.bits_from_f64(value))
    for k in 0..8 { unsafe { outp[off+k] = u8(bits & 255) }; bits >>= 8 }
}
fn energy(b []Body) f64 {
    mut e := f64(0)
    for i in 0..5 {
        e += 0.5*b[i].mass*(b[i].vx*b[i].vx+b[i].vy*b[i].vy+b[i].vz*b[i].vz)
        for j in i+1..5 {
            dx := b[i].x-b[j].x; dy := b[i].y-b[j].y; dz := b[i].z-b[j].z
            d := math.sqrt(dx*dx+dy*dy+dz*dz)
            e -= (b[i].mass*b[j].mass)/d
        }
    }
    return e
}
@[export: 'benchmarkgame_nbody']
pub fn benchmarkgame_nbody(input &i64, length usize, output &u8, capacity usize) i64 {
    if input == nil || length != 1 { return -1 }
    steps := unsafe { input[0] }
    if steps < 0 || steps > 1000 { return -1 }
    if output == nil || capacity < 16 { return -2 }
    pi := 3.141592653589793; solar := 4.0*pi*pi; days := 365.24
    mut b := [5]Body{}
    b[0] = Body{0,0,0,0,0,0,solar}
    b[1] = Body{4.84143144246472090e+00,-1.16032004402742839e+00,-1.03622044471123109e-01,1.66007664274403694e-03*days,7.69901118419740425e-03*days,-6.90460016972063023e-05*days,9.54791938424326609e-04*solar}
    b[2] = Body{8.34336671824457987e+00,4.12479856412430479e+00,-4.03523417114321381e-01,-2.76742510726862411e-03*days,4.99852801234917238e-03*days,2.30417297573763929e-05*days,2.85885980666130812e-04*solar}
    b[3] = Body{1.28943695621391310e+01,-1.51111514016986312e+01,-2.23307578892655734e-01,2.96460137564761618e-03*days,2.37847173959480950e-03*days,-2.96589568540237556e-05*days,4.36624404335156298e-05*solar}
    b[4] = Body{1.53796971148509165e+01,-2.59193146099879641e+01,1.79258772950371181e-01,2.68067772490389322e-03*days,1.62824170038242295e-03*days,-9.51592254519715870e-05*days,5.15138902046611451e-05*solar}
    mut px := f64(0); mut py := f64(0); mut pz := f64(0)
    for i in 0..5 { px += b[i].vx*b[i].mass; py += b[i].vy*b[i].mass; pz += b[i].vz*b[i].mass }
    b[0].vx = -px/solar; b[0].vy = -py/solar; b[0].vz = -pz/solar
    initial := energy(b[..])
    for _ in 0..int(steps) {
        for i in 0..5 {
            for j in i+1..5 {
                dx := b[i].x-b[j].x; dy := b[i].y-b[j].y; dz := b[i].z-b[j].z
                d := math.sqrt(dx*dx+dy*dy+dz*dz); mag := 0.01/(d*d*d)
                b[i].vx -= dx*b[j].mass*mag; b[i].vy -= dy*b[j].mass*mag; b[i].vz -= dz*b[j].mass*mag
                b[j].vx += dx*b[i].mass*mag; b[j].vy += dy*b[i].mass*mag; b[j].vz += dz*b[i].mass*mag
            }
        }
        for i in 0..5 { b[i].x += 0.01*b[i].vx; b[i].y += 0.01*b[i].vy; b[i].z += 0.01*b[i].vz }
    }
    put_f64(mut output,0,initial);put_f64(mut output,8,energy(b[..]));return 16
}
