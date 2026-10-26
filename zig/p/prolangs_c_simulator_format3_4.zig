// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
export fn prolangs_c_simulator_format3_4(v: [*]const i64, n: usize) i64 {
    if (n != 7) return -1;
    const pc=v[0]; const x=v[1]; const b=v[2];
    if (pc<0 or pc>1048572 or x<0 or x>=16777216 or b<0 or b>=16777216) return -1;
    for (3..7) |j| { if(v[j]<0 or v[j]>255)return -1; }
    const byte0: i64=v[3]; const byte1: i64=v[4]; const byte2: i64=v[5]; const byte3: i64=v[6];
    const nf=(byte0>>1)&1; const inf=byte0&1;
    const xf=(byte1>>7)&1; const bf=(byte1>>6)&1; const pf=(byte1>>5)&1; const ef=(byte1>>4)&1;
    const sic=nf==0 and inf==0; const fmt: i64=if(ef==1 and !sic) 4 else 3; const nextpc=pc+fmt;
    var address: i64=0;
    if(fmt==4){
        if(bf!=0 or pf!=0)return -1;
        address=((byte1&15)<<16)|(byte2<<8)|byte3;if(xf!=0)address+=x;
    }else{
        address=((byte1&15)<<8)|byte2;if(sic)return 0;
        if(bf!=0 and pf!=0)return -1;if(xf!=0)address+=x;if(bf!=0)address+=b;
        if(pf!=0){if(address>=2048)address=address-4096+nextpc else address+=nextpc;}
    }
    if(nf==1 and inf==0)return -1;if(address<0)return -1;if(nf==0 and inf==1 and address>=16777216)return -1;
    return address;
}
