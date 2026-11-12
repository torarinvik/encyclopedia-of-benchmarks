package splash2_fmm

import "core:c"
import "core:math"

MAX_PARTICLES :: 48
BOXES :: 16
ORDER :: 32
STRIDE :: ORDER + 1

@(export, link_name="splash2_fmm")
splash2_fmm :: proc "c" (input: [^]f64, input_length: c.size_t,
                          output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 7 || input_length > 145 do return -1
    requested := input[0]
    if !(requested >= 2.0 && requested <= 48.0) || requested != f64(int(requested)) do return -1
    n := int(requested)
    if input_length != c.size_t(1 + 3*n) do return -1
    x: [MAX_PARTICLES]f64
    y: [MAX_PARTICLES]f64
    charge: [MAX_PARTICLES]f64
    box: [MAX_PARTICLES]int
    for i := 0; i < n; i += 1 {
        px, py, q := input[1+3*i], input[2+3*i], input[3+3*i]
        if !(px >= 0.0 && px < 8.0) || px != f64(int(px)) ||
           !(py >= 0.0 && py < 8.0) || py != f64(int(py)) ||
           !(q >= -3.0 && q <= 3.0) || q != f64(int(q)) do return -1
        x[i] = px; y[i] = py; charge[i] = q
        box[i] = (int(py)/2)*4 + int(px)/2
        for j := 0; j < i; j += 1 { if x[i] == x[j] && y[i] == y[j] do return -1 }
    }
    if output == nil || output_capacity < c.size_t(n) do return -2
    mr: [BOXES][STRIDE]f64 = {}
    mi: [BOXES][STRIDE]f64 = {}
    lr: [BOXES][STRIDE]f64 = {}
    li: [BOXES][STRIDE]f64 = {}
    for i := 0; i < n; i += 1 {
        b := box[i]; bx := b%4; by := b/4
        zr := x[i] - f64(2*bx+1); zi := y[i] - f64(2*by+1)
        pr := 1.0; pi := 0.0
        mr[b][0] += charge[i]
        for k := 1; k <= ORDER; k += 1 {
            nr := pr*zr - pi*zi; ni := pr*zi + pi*zr
            pr = nr; pi = ni
            mr[b][k] += charge[i]*pr; mi[b][k] += charge[i]*pi
        }
    }
    for target := 0; target < BOXES; target += 1 {
        tx := target%4; ty := target/4
        for source := 0; source < BOXES; source += 1 {
            sx := source%4; sy := source/4
            dbx := tx-sx; dby := ty-sy
            if dbx >= -1 && dbx <= 1 && dby >= -1 && dby <= 1 do continue
            dx := 2.0*f64(dbx); dy := 2.0*f64(dby); r2 := dx*dx + dy*dy
            ir: [2*ORDER+1]f64 = {}
            ii: [2*ORDER+1]f64 = {}
            ir[0] = 1.0
            odr := dx/r2; odi := -dy/r2
            for p := 1; p <= 2*ORDER; p += 1 {
                ir[p] = ir[p-1]*odr - ii[p-1]*odi
                ii[p] = ir[p-1]*odi + ii[p-1]*odr
            }
            constant := mr[source][0]*0.5*math.log_f64(r2)
            for k := 1; k <= ORDER; k += 1 {
                constant -= (mr[source][k]*ir[k] - mi[source][k]*ii[k])/f64(k)
            }
            lr[target][0] += constant
            for order := 1; order <= ORDER; order += 1 {
                sr := 0.0; si := 0.0
                for k := 1; k <= ORDER; k += 1 {
                    choose := 1.0
                    for j := 1; j <= order; j += 1 { choose *= f64(k+j-1)/f64(j) }
                    scale := choose/f64(k); p := k+order
                    sr += scale*(mr[source][k]*ir[p] - mi[source][k]*ii[p])
                    si += scale*(mr[source][k]*ii[p] + mi[source][k]*ir[p])
                }
                qscale := (if order%2 == 1 {1.0} else {-1.0})/f64(order)
                mscale := if order%2 == 1 {-1.0} else {1.0}
                lr[target][order] += mr[source][0]*qscale*ir[order] - mscale*sr
                li[target][order] += mr[source][0]*qscale*ii[order] - mscale*si
            }
        }
    }
    for i := 0; i < n; i += 1 {
        b := box[i]; bx := b%4; by := b/4
        wr := x[i]-f64(2*bx+1); wi := y[i]-f64(2*by+1)
        pr := 1.0; pi := 0.0; value := lr[b][0]
        for order := 1; order <= ORDER; order += 1 {
            nr := pr*wr - pi*wi; ni := pr*wi + pi*wr
            pr = nr; pi = ni
            value += lr[b][order]*pr - li[b][order]*pi
        }
        for j := 0; j < n; j += 1 {
            if j == i do continue
            sb := box[j]; sx := sb%4; sy := sb/4
            dbx := bx-sx; dby := by-sy
            if dbx < -1 || dbx > 1 || dby < -1 || dby > 1 do continue
            dx := x[j]-x[i]; dy := y[j]-y[i]
            value += charge[j]*0.5*math.log_f64(dx*dx+dy*dy)
        }
        output[i] = value
    }
    return i64(n)
}
