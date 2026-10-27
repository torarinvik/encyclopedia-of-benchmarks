const s_scale = i64(1000000)

fn trunc_div(value i64, denominator i64) i64 {
    if value < 0 { return -((-value)/denominator) }
    return value/denominator
}
fn floor_sqrt(value i64) i64 {
    mut low:=i64(0);mut high:=i64(13000001)
    for low+1<high { middle:=(low+high)/2;if middle<=value/middle {low=middle} else {high=middle} }
    return low
}
fn put64(output &u8,pos int,value i64) {
    unsafe { bits:=u64(value);for j in 0..8 {output[pos+j]=u8((bits>>(8*j))&255)} }
}

@[export: 'private_noisy_power_iteration']
pub fn private_noisy_power_iteration(input &i64,length usize,output &u8,capacity usize)i64 {
    unsafe {
        if input==nil||length<11||length>39{return -1}
        n64:=input[0];rounds64:=input[1];sigma:=input[2]
        if n64<2||n64>4||rounds64<1||rounds64>4||sigma<0||sigma>s_scale{return -1}
        n:=int(n64);rounds:=int(rounds64);expected:=3+n*n+n+rounds*n
        if length!=usize(expected){return -1}
        vector_start:=3+n*n;noise_start:=vector_start+n
        mut matrix:=[]i64{len:n*n,init:0};mut x:=[]i64{len:n,init:0};mut noise:=[]i64{len:rounds*n,init:0}
        for i in 0..n*n {matrix[i]=input[3+i];if matrix[i]<-s_scale||matrix[i]>s_scale{return -1}}
        for i in 0..n {for j in 0..n {if matrix[i*n+j]!=matrix[j*n+i]{return -1}}}
        mut initial_norm:=i64(0)
        for i in 0..n {x[i]=input[vector_start+i];if x[i]<-s_scale||x[i]>s_scale{return -1};initial_norm+=x[i]*x[i]}
        if initial_norm!=s_scale*s_scale{return -1}
        for i in 0..rounds*n {noise[i]=input[noise_start+i];if noise[i]<-2*s_scale||noise[i]>2*s_scale{return -1}}
        mut y:=[]i64{len:n,init:0}
        for step in 0..rounds {
            mut norm_sq:=i64(0)
            for i in 0..n {mut sum:=sigma*noise[step*n+i];for j in 0..n {sum+=matrix[i*n+j]*x[j]};y[i]=trunc_div(sum,s_scale);norm_sq+=y[i]*y[i]}
            if norm_sq==0{return -1}
            radius:=floor_sqrt(norm_sq)
            for i in 0..n {x[i]=trunc_div(y[i]*s_scale,radius)}
        }
        bytes:=8*n
        if output==nil||capacity<bytes{return -2}
        mut staged:=[]u8{len:bytes,init:0}
        for i in 0..n {put64(&staged[0],8*i,x[i])}
        for i in 0..bytes {output[i]=staged[i]}
        return i64(bytes)
    }
}
