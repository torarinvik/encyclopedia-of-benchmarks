module indexed_deque

@[export: 'indexed_deque']
pub fn indexed_deque(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length<1 || length>513 || input[0]<1 || input[0]>256 { return -1 }
        q:=int(input[0])
        if length!=usize(1+2*q) { return -1 }
        mut items:=[256]i64{}
        mut answers:=[256]i64{}
        mut head:=0; mut size:=0; mut count:=0
        for i in 0 .. q {
            op:=input[1+2*i]; arg:=input[2+2*i]
            if op==0 || op==1 {
                if arg < -1000000 || arg > 1000000 || size==256 { return -1 }
                if op==0 { head=(head+255)%256; items[head]=arg } else { items[(head+size)%256]=arg }
                size++
            } else if op==2 || op==3 {
                if arg!=0 || size==0 { return -1 }
                if op==2 { head=(head+1)%256 }
                size--
            } else if op==4 {
                if arg<0 || arg>=i64(size) { return -1 }
                answers[count]=items[(head+int(arg))%256]; count++
            } else { return -1 }
        }
        if count==0 { return -1 }
        if isnil(output) || capacity<usize(8*count) { return -2 }
        for i in 0 .. count {
            bits:=u64(answers[i])
            for byte in 0 .. 8 { output[8*i+byte]=u8((bits >> (8*byte)) & 255) }
        }
        return i64(8*count)
    }
}
