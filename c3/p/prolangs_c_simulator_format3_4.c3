module prolangs_c_simulator_format3_4;

// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
fn long prolangs_c_simulator_format3_4(long* v, usz n) @export("prolangs_c_simulator_format3_4") {
    if (v == null || n != 7) return -1;
    long pc=v[0], x=v[1], b=v[2];
    if (pc<0 || pc>1048572 || x<0 || x>=16777216 || b<0 || b>=16777216) return -1;
    for (usz j=3;j<7;j++) if (v[j]<0 || v[j]>255) return -1;
    int byte0=v[3].int(), byte1=v[4].int(), byte2=v[5].int(), byte3=v[6].int();
    int nf=(byte0>>1)&1, inf=byte0&1;
    int xf=(byte1>>7)&1, bf=(byte1>>6)&1, pf=(byte1>>5)&1, ef=(byte1>>4)&1;
    bool sic=nf==0 && inf==0;
    long fmt=(ef==1 && !sic)?4:3, nextpc=pc+fmt, address=0;
    if (fmt==4) {
        if (bf!=0 || pf!=0) return -1;
        address=((byte1&15).long()<<16)|(byte2.long()<<8)|byte3.long();
        if (xf!=0) address+=x;
    } else {
        address=((byte1&15).long()<<8)|byte2.long();
        if (sic) return 0;
        if (bf!=0 && pf!=0) return -1;
        if (xf!=0) address+=x;
        if (bf!=0) address+=b;
        if (pf!=0) address=address>=2048?address-4096+nextpc:address+nextpc;
    }
    if (nf==1 && inf==0) return -1;
    if (address<0) return -1;
    if (nf==0 && inf==1 && address>=16777216) return -1;
    return address;
}
