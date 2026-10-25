module picojpeg;
const usz INPUT_BYTES = 139;
const usz OUTPUT_BYTES = 64;

fn long floor_q16(long value) {
    if (value >= 0) return value / 65536;
    return -((-value + 65535) / 65536);
}

fn bool valid(long* v) {
    if (v[0]!=255 || v[1]!=216 || v[2]!=255 || v[3]!=219 || v[4]!=0 || v[5]!=67 || v[6]!=0) return false;
    for (usz i=0;i<64;i++) { if(v[7+i]<1 || v[7+i]>255 || (i>=2 && v[7+i]!=1)) return false; }
    long[13] sof={255,192,0,11,8,0,8,0,8,1,1,17,0};
    for(usz i=0;i<13;i++) if(v[71+i]!=sof[i]) return false;
    if(v[84]!=255||v[85]!=196||v[86]!=0||v[87]!=39||v[88]!=0||v[89]!=1||v[90]!=0||v[105]!=4||v[106]!=16||v[107]!=1||v[108]!=1||v[123]!=4||v[124]!=0) return false;
    for(usz i=91;i<105;i++) if(v[i]!=0) return false;
    for(usz i=109;i<123;i++) if(v[i]!=0) return false;
    long[10] sos={255,218,0,8,1,1,0,0,63,0};
    for(usz i=0;i<10;i++) if(v[125+i]!=sos[i]) return false;
    return v[137]==255 && v[138]==217;
}

fn long picojpeg(long* values, usz length, uint8* output, usz capacity) @export("picojpeg") {
    if(values==null || length!=INPUT_BYTES) return -1;
    for(usz i=0;i<length;i++) if(values[i]<0 || values[i]>255) return -1;
    if(!valid(values)) return -1;
    uint16 scan=(uint16)((values[135]<<8)|values[136]);
    if((scan&0x8000)!=0 || (scan&0x0400)!=0 || ((scan>>4)&3)!=2 || (scan&15)!=15) return -1;
    int dcraw=(scan>>11)&15; int acraw=(scan>>6)&15;
    long dc=(dcraw>=8?dcraw:dcraw-15)*values[7];
    long ac=(acraw>=8?acraw:acraw-15)*values[8];
    if(output==null || capacity<OUTPUT_BYTES) return -2;
    long[8] factors={11363,9633,6436,2260,-2260,-6436,-9633,-11363};
    for(usz y=0;y<8;y++) for(usz x=0;x<8;x++) {
        long numerator=128*65536+dc*8192+ac*factors[x]+32768;
        long pixel=floor_q16(numerator);
        if(pixel<0) pixel=0; if(pixel>255) pixel=255;
        output[y*8+x]=(uint8)pixel;
    }
    return OUTPUT_BYTES;
}
