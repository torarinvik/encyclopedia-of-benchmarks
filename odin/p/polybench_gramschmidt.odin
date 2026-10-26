// Clean-room bounded PolyBench QR port. See package LICENSE.txt.
package polybench_gramschmidt
import "core:c"
import "core:math"

@(export)
polybench_gramschmidt :: proc "c" (input:[^]f64, length:c.size_t, output:[^]f64, capacity:c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    mv, nv := input[0], input[1]
    if mv != mv || nv != nv || math.trunc(mv) != mv || math.trunc(nv) != nv || mv < 1 || mv > 6 || nv < 1 || nv > 6 || nv > mv do return -1
    m, n := int(mv), int(nv)
    q_cells, r_cells := m*n, n*n
    total := q_cells+r_cells
    if output == nil || capacity < c.size_t(total) do return -2
    var a:[36]f64
    var q:[36]f64
    var r:[36]f64
    var staged:[72]f64
    for i:=0;i<m;i+=1 { for j:=0;j<n;j+=1 { a[i*n+j]=f64((i*j)%m)/f64(m)*100.0+10.0 } }
    for k:=0;k<n;k+=1 {
        norm_squared:f64=0.0
        for i:=0;i<m;i+=1 { norm_squared+=a[i*n+k]*a[i*n+k] }
        r[k*n+k]=math.sqrt(norm_squared)
        for i:=0;i<m;i+=1 { q[i*n+k]=a[i*n+k]/r[k*n+k] }
        for j:=k+1;j<n;j+=1 {
            r[k*n+j]=0.0
            for i:=0;i<m;i+=1 { r[k*n+j]+=q[i*n+k]*a[i*n+j] }
            for i:=0;i<m;i+=1 { a[i*n+j]=a[i*n+j]-q[i*n+k]*r[k*n+j] }
        }
    }
    for x:=0;x<r_cells;x+=1 { staged[x]=r[x] }
    for x:=0;x<q_cells;x+=1 { staged[r_cells+x]=q[x] }
    for x:=0;x<total;x+=1 { output[x]=staged[x] }
    return i64(total)
}
