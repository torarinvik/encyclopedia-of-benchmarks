fn put_i64_le(mut output &u8, offset int, value i64) {
    mut bits:=u64(value)
    for b in 0..8 {unsafe{output[offset+b]=u8(bits&255)};bits>>=8}
}
@[export:'floor_and_ceiling']
pub fn floor_and_ceiling(input &i64,length usize,mut output &u8,capacity usize) i64 {
    if unsafe{input==nil} || length<3 || length>384 {return -1}
    unsafe {
        raw_n,root,key:=input[0],input[1],input[2]
        if raw_n<0 || raw_n>127 || key < -1_000_000 || key>1_000_000 || length!=usize(3+3*raw_n) {return -1}
        n:=int(raw_n)
        if (n==0 && root!=-1)||(n>0 && (root<0 || root>=raw_n)) {return -1}
        mut floor:=i64(-9223372036854775808);mut ceiling:=i64(-9223372036854775808)
        mut current:=n
        if n>0 {current=int(root)}
        for step in 0..n {
            if current>=n {break}
            base:=3+3*current;value,left,right:=input[base],input[base+1],input[base+2]
            if value < -1_000_000 || value>1_000_000 || left < -1 || right < -1 || left>=raw_n || right>=raw_n {return -1}
            if value==key {floor=value;ceiling=value;break}
            if key<value {ceiling=value;if left<0 {current=n}else{current=int(left)}}
            else {floor=value;if right<0 {current=n}else{current=int(right)}}
        }
        if output==nil || capacity<16 {return -2}
        put_i64_le(mut output,0,floor);put_i64_le(mut output,8,ceiling);return 16
    }
}
