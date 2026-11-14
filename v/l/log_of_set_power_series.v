module log_of_set_power_series
const lsps_mod=i64(998244353)
@[export: 'log_of_set_power_series']
fn log_of_set_power_series(input &i64,length usize,output &u8,capacity usize) i64 {
    unsafe {
        if isnil(input) || length<2 || length>33 || input[0]<0 || input[0]>5 { return -1 }
        size:=1 << int(input[0])
        if length!=usize(1+size) || input[1]!=1 { return -1 }
        for i in 0 .. size { if input[1+i]<0 || input[1+i]>=lsps_mod { return -1 } }
        if isnil(output) || capacity<usize(8*size) { return -2 }
        mut coefficients:=[32]i64{}
        for mask in 1 .. size {
            pivot:=mask & -mask; mut sub:=(mask-1)&mask; mut sum:=i64(0)
            for sub!=0 {
                if sub & pivot != 0 { sum=(sum+coefficients[sub]*input[1+(mask^sub)])%lsps_mod }
                sub=(sub-1)&mask
            }
            coefficients[mask]=(input[1+mask]-sum+lsps_mod)%lsps_mod
        }
        for i in 0 .. size {
            bits:=u64(coefficients[i])
            for byte in 0 .. 8 { output[8*i+byte]=u8((bits >> (8*byte)) & 255) }
        }
        return i64(8*size)
    }
}
