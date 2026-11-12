import math

@[export: 'graphai_ggnn_message_update']
pub fn graphai_ggnn_message_update(input &f64, length usize, mut output &f64,
    capacity usize) i64 {
    unsafe {
        if input==nil || length<3 || length>453 { return -1 }
        for q in 0..length { if !input[q].is_finite() { return -1 } }
        nv,mv,dv:=input[0],input[1],input[2]
        if math.trunc(nv)!=nv || math.trunc(mv)!=mv || math.trunc(dv)!=dv ||
            nv<1 || nv>8 || mv<0 || mv>24 || dv<1 || dv>4 { return -1 }
        n,m,d:=int(nv),int(mv),int(dv)
        if length!=usize(4+n+m+n*d+6*n*n) { return -1 }
        row_at:=3; col_at:=row_at+n+1; h_at:=col_at+m
        wz_at:=h_at+n*d; wr_at:=wz_at+n*n; wc_at:=wr_at+n*n
        uz_at:=wc_at+n*n; ur_at:=uz_at+n*n; uc_at:=ur_at+n*n
        if input[row_at]!=0 || input[col_at-1]!=f64(m) { return -1 }
        mut rows:=[9]int{}; mut cols:=[24]int{}
        for i in 0..n+1 {
            x:=input[row_at+i]
            if math.trunc(x)!=x || x<0 || x>f64(m) { return -1 }
            rows[i]=int(x)
            if i>0 && rows[i]<rows[i-1] { return -1 }
        }
        for e in 0..m {
            x:=input[col_at+e]
            if math.trunc(x)!=x || x<0 || x>=f64(n) { return -1 }
            cols[e]=int(x)
        }
        for q in h_at..wz_at { if input[q] < -1 || input[q]>1 { return -1 } }
        for q in wz_at..length { if input[q] < -0.25 || input[q]>0.25 { return -1 } }
        required:=n*d
        if output==nil || capacity<usize(required) { return -2 }
        mut agg:=[32]f64{}; mut update:=[32]f64{}; mut reset:=[32]f64{}
        mut candidate:=[32]f64{}; mut staged:=[32]f64{}
        for v in 0..n { for e in rows[v]..rows[v+1] { for f in 0..d {
            agg[v*d+f]+=input[h_at+cols[e]*d+f]
        } } }
        for v in 0..n { for f in 0..d {
            mut wz:=0.0; mut wr:=0.0; mut uz:=0.0; mut ur:=0.0
            for k in 0..n {
                a,b:=v*n+k,k*d+f
                wz+=input[wz_at+a]*agg[b]; wr+=input[wr_at+a]*agg[b]
                uz+=input[uz_at+a]*input[h_at+b]; ur+=input[ur_at+a]*input[h_at+b]
            }
            at:=v*d+f
            update[at]=1.0/(1.0+math.exp(-(wz+uz)))
            reset[at]=1.0/(1.0+math.exp(-(wr+ur)))
        } }
        for v in 0..n { for f in 0..d {
            mut from_graph:=0.0; mut from_state:=0.0
            for k in 0..n {
                a,b:=v*n+k,k*d+f
                from_graph+=input[wc_at+a]*agg[b]
                from_state+=input[uc_at+a]*(reset[b]*input[h_at+b])
            }
            at:=v*d+f; x:=from_graph+from_state
            candidate[at]=2.0/(1.0+math.exp(-2.0*x))-1.0
            staged[at]=(1.0-update[at])*input[h_at+at]+update[at]*candidate[at]
        } }
        for q in 0..required { output[q]=staged[q] }
        return i64(required)
    }
}
