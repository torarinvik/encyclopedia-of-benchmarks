package graphai_ggnn_message_update

import "core:c"
import "core:math"

@(export)
graphai_ggnn_message_update :: proc "c" (input:[^]f64, length:c.size_t,
    output:[^]f64, capacity:c.size_t)->i64 {
    N :: 8; M :: 24; D :: 4
    if input==nil || length<3 || length>c.size_t(453) do return -1
    for q:=0; q<int(length); q+=1 { if !math.is_finite(input[q]) do return -1 }
    nv,mv,dv:=input[0],input[1],input[2]
    if math.trunc(nv)!=nv || math.trunc(mv)!=mv || math.trunc(dv)!=dv ||
        nv<1 || nv>N || mv<0 || mv>M || dv<1 || dv>D do return -1
    n,m,d:=int(nv),int(mv),int(dv)
    if length!=c.size_t(4+n+m+n*d+6*n*n) do return -1
    row_at:=3; col_at:=row_at+n+1; h_at:=col_at+m
    wz_at:=h_at+n*d; wr_at:=wz_at+n*n; wc_at:=wr_at+n*n
    uz_at:=wc_at+n*n; ur_at:=uz_at+n*n; uc_at:=ur_at+n*n
    if input[row_at]!=0 || input[col_at-1]!=f64(m) do return -1
    var rows:[9]int; var cols:[24]int
    for i:=0; i<=n; i+=1 {
        x:=input[row_at+i]
        if math.trunc(x)!=x || x<0 || x>f64(m) do return -1
        rows[i]=int(x)
        if i>0 && rows[i]<rows[i-1] do return -1
    }
    for e:=0; e<m; e+=1 {
        x:=input[col_at+e]
        if math.trunc(x)!=x || x<0 || x>=f64(n) do return -1
        cols[e]=int(x)
    }
    for q:=h_at; q<wz_at; q+=1 { if input[q] < -1 || input[q]>1 do return -1 }
    for q:=wz_at; q<int(length); q+=1 { if input[q] < -0.25 || input[q]>0.25 do return -1 }
    required:=n*d
    if output==nil || capacity<c.size_t(required) do return -2
    var agg:[32]f64; var update:[32]f64; var reset:[32]f64
    var candidate:[32]f64; var staged:[32]f64
    for v:=0; v<n; v+=1 {
        for e:=rows[v]; e<rows[v+1]; e+=1 {
            for f:=0; f<d; f+=1 { agg[v*d+f]+=input[h_at+cols[e]*d+f] }
        }
    }
    for v:=0; v<n; v+=1 { for f:=0; f<d; f+=1 {
        wz,wr,uz,ur:=0.0,0.0,0.0,0.0
        for k:=0; k<n; k+=1 {
            a,b:=v*n+k,k*d+f
            wz+=input[wz_at+a]*agg[b]; wr+=input[wr_at+a]*agg[b]
            uz+=input[uz_at+a]*input[h_at+b]; ur+=input[ur_at+a]*input[h_at+b]
        }
        at:=v*d+f
        update[at]=1.0/(1.0+math.exp_f64(-(wz+uz)))
        reset[at]=1.0/(1.0+math.exp_f64(-(wr+ur)))
    } }
    for v:=0; v<n; v+=1 { for f:=0; f<d; f+=1 {
        from_graph,from_state:=0.0,0.0
        for k:=0; k<n; k+=1 {
            a,b:=v*n+k,k*d+f
            from_graph+=input[wc_at+a]*agg[b]
            from_state+=input[uc_at+a]*(reset[b]*input[h_at+b])
        }
        at:=v*d+f; x:=from_graph+from_state
        candidate[at]=2.0/(1.0+math.exp_f64(-2.0*x))-1.0
        staged[at]=(1.0-update[at])*input[h_at+at]+update[at]*candidate[at]
    } }
    for q:=0; q<required; q+=1 { output[q]=staged[q] }
    return i64(required)
}
