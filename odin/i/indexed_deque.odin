package indexed_deque
import "core:c"

@(export)
indexed_deque :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<1 || length>513 || input[0]<1 || input[0]>256 { return -1 }
    q:=int(input[0])
    if length!=c.size_t(1+2*q) { return -1 }
    items, answers: [256]i64
    head, size, count := 0, 0, 0
    for i:=0;i<q;i+=1 {
        op:=input[1+2*i]; arg:=input[2+2*i]
        if op==0 || op==1 {
            if arg < -1000000 || arg > 1000000 || size==256 { return -1 }
            if op==0 { head=(head+255)%256; items[head]=arg } else { items[(head+size)%256]=arg }
            size+=1
        } else if op==2 || op==3 {
            if arg!=0 || size==0 { return -1 }
            if op==2 { head=(head+1)%256 }
            size-=1
        } else if op==4 {
            if arg<0 || arg>=i64(size) { return -1 }
            answers[count]=items[(head+int(arg))%256]; count+=1
        } else { return -1 }
    }
    if count==0 { return -1 }
    if output==nil || capacity<c.size_t(8*count) { return -2 }
    for i:=0;i<count;i+=1 {
        bits:=transmute(u64)answers[i]
        for byte:=0;byte<8;byte+=1 { output[8*i+byte]=u8((bits >> u64(8*byte)) & 255) }
    }
    return i64(8*count)
}
