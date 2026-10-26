@[export: 'weighted_random_sampling']
pub fn weighted_random_sampling(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 5 || length > 50 { return -1 }
        n64 := input[0]; m64 := input[1]
        if n64 < 1 || n64 > 16 || m64 < 1 || m64 > n64 || length != usize(2+3*n64) { return -1 }
        n := int(n64); m := int(m64)
        mut weights := []i64{len:n, init:0}; mut nums := []i64{len:n, init:0}; mut dens := []i64{len:n, init:0}
        for i in 0..n {
            weights[i]=input[2+3*i]; nums[i]=input[3+3*i]; dens[i]=input[4+3*i]
            if weights[i]<1 || weights[i]>3 || nums[i]<1 || nums[i]>=dens[i] || dens[i]>100 { return -1 }
        }
        bytes:=8*m
        if output==nil || capacity<usize(bytes) { return -2 }
        mut available:=[]int{len:n,init:0}; mut chosen:=[]int{len:m,init:0}
        for i in 0..n { available[i]=i }
        for rank in 0..m {
            mut best:=0
            for i in 1..(n-rank) {
                left:=available[i]; right:=available[best]
                mut lhs:=i64(1); mut rhs:=i64(1)
                for _ in 0..int(weights[right]) { lhs*=nums[left] }
                for _ in 0..int(weights[left]) { lhs*=dens[right] }
                for _ in 0..int(weights[left]) { rhs*=nums[right] }
                for _ in 0..int(weights[right]) { rhs*=dens[left] }
                if lhs>rhs || (lhs==rhs && left<right) { best=i }
            }
            chosen[rank]=available[best]
            for i in best..(n-rank-1) { available[i]=available[i+1] }
        }
        for i in 0..m {
            bits:=u64(chosen[i])
            for b in 0..8 { output[8*i+b]=u8((bits>>(8*b))&255) }
        }
        return i64(bytes)
    }
}
