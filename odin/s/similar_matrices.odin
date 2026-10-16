package similar_matrices

import "core:c"

SM_MAX_VALUES :: 19

sm_det3 :: proc "contextless" (m: [^]i64) -> i64 {
    return m[0]*(m[4]*m[8]-m[5]*m[7]) - m[1]*(m[3]*m[8]-m[5]*m[6]) + m[2]*(m[3]*m[7]-m[4]*m[6])
}

sm_charpoly :: proc "contextless" (m: [^]i64, n: int, out: [^]i64) {
    trace: i64 = 0
    for i := 0; i < n; i += 1 { trace += m[i*n+i] }
    out[0] = -trace; out[1] = 0; out[2] = 0
    if n == 2 { out[1] = m[0]*m[3] - m[1]*m[2] }
    if n == 3 {
        out[1] = (m[0]*m[4]-m[1]*m[3]) + (m[0]*m[8]-m[2]*m[6]) + (m[4]*m[8]-m[5]*m[7])
        out[2] = -sm_det3(m)
    }
}

sm_disc3 :: proc "contextless" (a,b,cc:i64) -> i64 {
    return a*a*b*b - 4*b*b*b - 4*a*a*a*cc - 27*cc*cc + 18*a*b*cc
}

sm_rank_singular :: proc "contextless" (m: [^]i64, n: int) -> int {
    for r0 := 0; r0 < n; r0 += 1 {
        for r1 := r0+1; r1 < n; r1 += 1 {
            for c0 := 0; c0 < n; c0 += 1 {
                for c1 := c0+1; c1 < n; c1 += 1 {
                    if m[r0*n+c0]*m[r1*n+c1] - m[r0*n+c1]*m[r1*n+c0] != 0 do return 2
                }
            }
        }
    }
    for i := 0; i < n*n; i += 1 { if m[i] != 0 do return 1 }
    return 0
}

sm_shifted :: proc "contextless" (m: [^]i64, n: int, numerator,denominator:i64, out:[^]i64) {
    for i := 0; i < n*n; i += 1 { out[i] = denominator*m[i] }
    for i := 0; i < n; i += 1 { out[i*n+i] -= numerator }
}

sm_multiply :: proc "contextless" (a,b:[^]i64,n:int,out:[^]i64) {
    for row := 0; row < n; row += 1 {
        for col := 0; col < n; col += 1 {
            value: i64 = 0
            for k := 0; k < n; k += 1 { value += a[row*n+k]*b[k*n+col] }
            out[row*n+col] = value
        }
    }
}

sm_similar :: proc "contextless" (a,b:[^]i64,n:int) -> bool {
    ca:[3]i64; cb:[3]i64
    sm_charpoly(a,n,&ca[0]); sm_charpoly(b,n,&cb[0])
    if ca[0]!=cb[0] || ca[1]!=cb[1] || ca[2]!=cb[2] do return false
    if n==1 do return true
    if n==2 {
        if ca[0]*ca[0]-4*ca[1]!=0 do return true
        da:[9]i64; db:[9]i64
        sm_shifted(a,n,-ca[0],2,&da[0]); sm_shifted(b,n,-ca[0],2,&db[0])
        return sm_rank_singular(&da[0],n)==sm_rank_singular(&db[0],n)
    }
    if sm_disc3(ca[0],ca[1],ca[2])!=0 do return true
    q:=ca[0]*ca[0]-3*ca[1]
    da:[9]i64; db:[9]i64
    if q==0 {
        sm_shifted(a,n,-ca[0],3,&da[0]); sm_shifted(b,n,-ca[0],3,&db[0])
        if sm_rank_singular(&da[0],n)!=sm_rank_singular(&db[0],n) do return false
        da2:[9]i64; db2:[9]i64
        sm_multiply(&da[0],&da[0],n,&da2[0]); sm_multiply(&db[0],&db[0],n,&db2[0])
        return sm_rank_singular(&da2[0],n)==sm_rank_singular(&db2[0],n)
    }
    numerator:=9*ca[2]-ca[0]*ca[1]
    denominator:=2*q
    sm_shifted(a,n,numerator,denominator,&da[0]); sm_shifted(b,n,numerator,denominator,&db[0])
    return sm_rank_singular(&da[0],n)==sm_rank_singular(&db[0],n)
}

@(export)
similar_matrices :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<1 || length>SM_MAX_VALUES do return -1
    n_value:=input[0]
    if n_value<1 || n_value>3 do return -1
    n:=int(n_value); matrix_size:=n*n
    if int(length)!=1+2*matrix_size do return -1
    a:[9]i64; b:[9]i64
    for i:=0;i<2*matrix_size;i+=1 {
        value:=input[1+i]
        if value < -5 || value > 5 do return -1
        if i<matrix_size { a[i]=value } else { b[i-matrix_size]=value }
    }
    if sm_similar(&a[0],&b[0],n) do return 1
    return 0
}
