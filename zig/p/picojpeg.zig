const INPUT_BYTES: usize = 139;
const OUTPUT_BYTES: usize = 64;
const IDCT_Q16 = [_]i64{11363,9633,6436,2260,-2260,-6436,-9633,-11363};

fn floorQ16(value:i64)i64 {
    if(value>=0)return @divTrunc(value,65536);
    return -@divTrunc(-value+65535,65536);
}

fn valid(v:[*]const i64)bool {
    if(v[0]!=255 or v[1]!=216 or v[2]!=255 or v[3]!=219 or v[4]!=0 or v[5]!=67 or v[6]!=0)return false;
    for(0..64)|i|{if(v[7+i]<1 or v[7+i]>255 or (i>=2 and v[7+i]!=1))return false;}
    const sof=[_]i64{255,192,0,11,8,0,8,0,8,1,1,17,0};
    for(0..sof.len)|i|{if(v[71+i]!=sof[i])return false;}
    if(v[84]!=255 or v[85]!=196 or v[86]!=0 or v[87]!=39 or v[88]!=0 or v[89]!=1 or v[90]!=0 or v[105]!=4 or v[106]!=16 or v[107]!=1 or v[108]!=1 or v[123]!=4 or v[124]!=0)return false;
    for(91..105)|i|{if(v[i]!=0)return false;}
    for(109..123)|i|{if(v[i]!=0)return false;}
    const sos=[_]i64{255,218,0,8,1,1,0,0,63,0};
    for(0..sos.len)|i|{if(v[125+i]!=sos[i])return false;}
    return v[137]==255 and v[138]==217;
}

pub export fn picojpeg(values:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64 {
    const v=values orelse return -1;
    if(length!=INPUT_BYTES)return -1;
    for(0..length)|i|{if(v[i]<0 or v[i]>255)return -1;}
    if(!valid(v))return -1;
    const scan:u16=@intCast((v[135]<<8)|v[136]);
    if((scan&0x8000)!=0 or (scan&0x0400)!=0 or ((scan>>4)&3)!=2 or (scan&15)!=15)return -1;
    const dcraw:i64=@intCast((scan>>11)&15);
    const acraw:i64=@intCast((scan>>6)&15);
    const dc=(if(dcraw>=8)dcraw else dcraw-15)*v[7];
    const ac=(if(acraw>=8)acraw else acraw-15)*v[8];
    const out=output orelse return -2;
    if(capacity<OUTPUT_BYTES)return -2;
    for(0..8)|y|{for(0..8)|x|{
        const numerator:i64=128*65536+dc*8192+ac*IDCT_Q16[x]+32768;
        const pixel=@max(0,@min(255,floorQ16(numerator)));
        out[y*8+x]=@intCast(pixel);
    }}
    return OUTPUT_BYTES;
}
