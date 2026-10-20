// Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
package beta_skeleton
import "core:c"
@(export)
beta_skeleton :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > 65 do return -1
    n_value := input[0]; if n_value < 1 || n_value > 32 || input_length != c.size_t(1+2*n_value) do return -1
    n := int(n_value); x,y: [32]i64
    for i in 0..<n { x[i]=input[1+2*i]; y[i]=input[2+2*i]; if x[i]<-1000 || x[i]>1000 || y[i]<-1000 || y[i]>1000 do return -1; for j in 0..<i { if x[i]==x[j] && y[i]==y[j] do return -1 } }
    edges: [992]u8; count: c.size_t=0
    for i in 0..<n { for j in i+1..<n { dx:=x[i]-x[j];dy:=y[i]-y[j];d2:=dx*dx+dy*dy;blocked:=false
        for k in 0..<n { if k==i || k==j do continue; aix:=x[k]-x[i];aiy:=y[k]-y[i];ajx:=x[k]-x[j];ajy:=y[k]-y[j];if aix*aix+aiy*aiy<d2 && ajx*ajx+ajy*ajy<d2 { blocked=true;break } }
        if !blocked { edges[count]=u8(i);edges[count+1]=u8(j);count+=2 }
    } }
    if output==nil || output_capacity<count do return -2
    for i in 0..<count { output[i]=edges[i] }
    return i64(count)
}
