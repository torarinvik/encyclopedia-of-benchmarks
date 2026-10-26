// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
export fn prolangs_c_simulator_shiftr(v: [*]const i64, n: usize) i64 {
    if (n != 2) return -1;
    const operand=v[0];const raw=v[1];
    if(operand<0 or operand>255 or raw<0 or raw>0xFFFFFF or (operand>>4)>=10)return -1;
    const shift:u5=@intCast((operand&15)+1);const value:u32=@intCast(raw);var result=value>>shift;
    if((value&0x800000)!=0)result|=((@as(u32,1)<<shift)-1)<<(24-shift);
    return @intCast(result&0xFFFFFF);
}
