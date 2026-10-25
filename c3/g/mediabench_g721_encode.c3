/*
 * This source code is a product of Sun Microsystems, Inc. and is provided
 * for unrestricted use.  Users may copy or modify this source code without
 * charge.
 *
 * SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
 * THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 *
 * Sun source code is provided with no support and without any obligation on
 * the part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 *
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
 * OR ANY PART THEREOF.
 *
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 *
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

module mediabench_g721_encode;

const long[15] POWER2 = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384};
const long[7] QTAB = {-124,80,178,246,300,349,400};
const long[16] DQLNTAB = {-2048,4,135,213,273,323,373,425,425,373,323,273,213,135,4,-2048};
const long[16] WITAB = {-12,18,41,64,112,198,355,1122,1122,355,198,112,64,41,18,-12};
const long[16] FITAB = {0,0,0,512,512,512,1536,3584,3584,1536,512,512,512,0,0,0};

struct State { long yl; long yu; long dms; long dml; long ap; long[2] a; long[6] b; long[2] pk; long[6] dq; long[2] sr; long td; }

fn long wrap16(long value) { ulong low = (ulong)value & 0xffff; return low >= 0x8000 ? (long)low - 65536 : (long)low; }
fn long qtable(long value, long* table, int count) { int i=0; for (; i<count && value>=table[i]; i++) {} return i; }
fn long fmult(long coefficient,long encoded) {
    long magnitude=coefficient>0?coefficient:((-coefficient)&0x1fff); long exponent=qtable(magnitude,&POWER2[0],15)-6;
    long mantissa=magnitude==0?32:(exponent>=0?magnitude>>exponent:magnitude<<-exponent);
    long product_exponent=exponent+((encoded>>6)&15)-13; long product_mantissa=(mantissa*(encoded&077)+0x30)>>4;
    long result=product_exponent>=0?((product_mantissa<<product_exponent)&0x7fff):(product_mantissa>>-product_exponent);
    return ((coefficient^encoded)<0)?-result:result;
}
fn long predictor_zero(State* s) { long sum=fmult(s.b[0]>>2,s.dq[0]); for(int i=1;i<6;i++)sum+=fmult(s.b[i]>>2,s.dq[i]); return sum; }
fn long predictor_pole(State* s) { return fmult(s.a[1]>>2,s.sr[1])+fmult(s.a[0]>>2,s.sr[0]); }
fn long stepsize(State* s) { if(s.ap>=256)return s.yu; long y=s.yl>>6; long d=s.yu-y; long al=s.ap>>2; if(d>0)y+=(d*al)>>6; else if(d<0)y+=(d*al+0x3f)>>6; return y; }
fn long quantize(long difference,long step) {
    long magnitude=difference<0?-difference:difference; long exponent=qtable(magnitude>>1,&POWER2[0],15);
    long mantissa=((magnitude<<7)>>exponent)&0x7f; long normalized=((exponent<<7)+mantissa)-(step>>2); long index=qtable(normalized,&QTAB[0],7);
    return difference<0?15-index:(index==0?15:index);
}
fn long reconstruct(long sign,long dqln,long step) {
    long dql=dqln+(step>>2); if(dql<0)return sign?-32768:0;
    long exponent=(dql>>7)&15; long mantissa=128+(dql&127); long value=(mantissa<<7)>>(14-exponent);
    return sign?value-32768:value;
}
fn long abs64(long x) { return x<0?-x:x; }

fn void update(long step,long wi,long fi,long dq,long sr,long dqsez,State* s) {
    long mag=dq&0x7fff; long ylint=s.yl>>15; long ylfrac=(s.yl>>10)&0x1f; long thr1=(32+ylfrac)<<ylint;
    long thr2=ylint>9?31<<10:thr1; long dqthr=(thr2+(thr2>>1))>>1; bool tr=s.td!=0&&mag>dqthr;
    s.yu=wrap16(step+((wi-step)>>5)); if(s.yu<544)s.yu=544;else if(s.yu>5120)s.yu=5120;
    s.yl+=s.yu+((-s.yl)>>6);
    if(tr){s.a[0]=0;s.a[1]=0;for(int i=0;i<6;i++)s.b[i]=0;}
    else {
        long pk0=dqsez<0?1:0; long pks1=pk0^s.pk[0]; long a2p=s.a[1]-(s.a[1]>>7);
        if(dqsez!=0){long fa1=pks1?s.a[0]:-s.a[0];if(fa1< -8191)a2p-=0x100;else if(fa1>8191)a2p+=0xff;else a2p+=fa1>>5;
            if(pk0^s.pk[1]){if(a2p<=-12160)a2p=-12288;else if(a2p>=12416)a2p=12288;else a2p-=0x80;}
            else{if(a2p<=-12416)a2p=-12288;else if(a2p>=12160)a2p=12288;else a2p+=0x80;}}
        a2p=wrap16(a2p);s.a[1]=a2p;s.a[0]=wrap16(s.a[0]-(s.a[0]>>8));
        if(dqsez!=0)s.a[0]=wrap16(s.a[0]+(pks1==0?192:-192));long limit=15360-a2p;
        if(s.a[0]<-limit)s.a[0]=-limit;else if(s.a[0]>limit)s.a[0]=limit;s.a[0]=wrap16(s.a[0]);
        for(int i=0;i<6;i++){s.b[i]=wrap16(s.b[i]-(s.b[i]>>8));if((dq&0x7fff)!=0)s.b[i]=wrap16(s.b[i]+(((dq^s.dq[i])>=0)?128:-128));}
    }
    for(int i=5;i>0;i--)s.dq[i]=s.dq[i-1];
    if(mag==0)s.dq[0]=dq>=0?0x20:wrap16(0xfc20);else{long e=qtable(mag,&POWER2[0],15);long z=(e<<6)+((mag<<6)>>e);s.dq[0]=wrap16(dq>=0?z:z-0x400);}
    s.sr[1]=s.sr[0];
    if(sr==0)s.sr[0]=0x20;else if(sr>0){long e=qtable(sr,&POWER2[0],15);s.sr[0]=wrap16((e<<6)+((sr<<6)>>e));}
    else if(sr> -32768){long m=-sr;long e=qtable(m,&POWER2[0],15);s.sr[0]=wrap16((e<<6)+((m<<6)>>e)-0x400);}else s.sr[0]=wrap16(0xfc20);
    s.pk[1]=s.pk[0];s.pk[0]=dqsez<0?1:0;s.td=tr?0:(s.a[1]<-11776?1:0);
    s.dms=wrap16(s.dms+((fi-s.dms)>>5));s.dml=wrap16(s.dml+(((fi<<2)-s.dml)>>7));
    if(tr)s.ap=256;else if(step<1536||s.td==1||abs64((s.dms<<2)-s.dml)>=(s.dml>>3))s.ap=wrap16(s.ap+((0x200-s.ap)>>4));else s.ap=wrap16(s.ap+((-s.ap)>>4));
}
fn void init_state(State* s) {
    s.yl=34816;s.yu=544;s.dms=0;s.dml=0;s.ap=0;s.td=0;
    for(int i=0;i<2;i++){s.a[i]=0;s.pk[i]=0;s.sr[i]=32;}for(int i=0;i<6;i++){s.b[i]=0;s.dq[i]=32;}
}
fn long ulaw2linear(long input) { long v=(~input)&0xff;long t=((v&15)<<3)+0x84;t<<=(v&0x70)>>4;return(v&0x80)!=0?0x84-t:t-0x84; }
fn long encode_one(long input,State* s) {
    long sample=ulaw2linear(input)>>2;long sezi=wrap16(predictor_zero(s));long sez=sezi>>1;long se=wrap16((sezi+predictor_pole(s))>>1);
    long d=wrap16(sample-se);long y=wrap16(stepsize(s));long code=quantize(d,y);long dq=wrap16(reconstruct(code&8,DQLNTAB[code],y));
    long sr=wrap16(dq<0?se-(dq&0x3fff):se+dq);long dqsez=wrap16(sr+sez-se);update(y,WITAB[code]<<5,FITAB[code],dq,sr,dqsez,s);return code;
}

fn long mediabench_g721_encode(long* input,usz input_length,char* output,usz output_capacity) @export("mediabench_g721_encode") {
    if(input==null||input_length<1||input_length>17)return -1;long count=input[0];if(count<0||count>16||input_length!=(usz)count+1)return -1;
    for(usz i=0;i<(usz)count;i++)if(input[i+1]<0||input[i+1]>255)return -1;
    usz required=((usz)count+1)/2;if(required==0)return 0;if(output==null||output_capacity<required)return -2;
    State state;init_state(&state);for(usz i=0;i<(usz)count;i++){char code=(char)encode_one(input[i+1],&state);if((i&1)==0)output[i/2]=code;else output[i/2]|=(char)(code<<4);}
    return (long)required;
}
