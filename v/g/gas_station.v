module gas_station

@[export: 'gas_station']
pub fn gas_station(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 1 { return -2 }
    unsafe {
        n64:=input[0]
        if n64<0 || n64>128 { return -2 }
        n:=int(n64)
        if length!=2*n+1 { return -2 }
        for i in 0 .. 2*n { if input[i+1]<0 || input[i+1]>1000000 { return -2 } }
        mut total:=i64(0); mut current:=i64(0); mut start:=0
        for i in 0 .. n {
            net:=input[1+i]-input[1+n+i]
            total+=net; current+=net
            if current<0 { start=i+1; current=0 }
        }
        if total<0 { return -1 }
        return i64(start)
    }
}
