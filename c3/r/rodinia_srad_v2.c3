// Rodinia SRAD v2 kernel profile; source and license provenance: benchmarks/r/rodinia_srad_v2.
module rodinia_srad_v2;
import "math";

const long PIXELS=256, INPUTS=258;
const uint LAMBDA_MIN=0x3c23d70a, LAMBDA_MAX=0x3dcccccd;
const uint Q0_MIN=0x3c23d70a, Q0_MAX=0x3f800000;
const uint J_MIN=0x3f800000, J_MAX=0x3fa00000;
fn float add32(float a,float b) @noinline{return a+b;}
fn float sub32(float a,float b) @noinline{return a-b;}
fn float mul32(float a,float b) @noinline{return a*b;}
fn float div32(float a,float b) @noinline{return a/b;}
fn float from_bits(uint bits) @noinline{return @bitcast(float,bits);}

fn long rodinia_srad_v2(long* values,usz length) @export("rodinia_srad_v2") {
    if(values==null||length!=INPUTS)return -1;
    for(usz i=0;i<length;i++){if(values[i]<0||values[i]>4294967295)return -1;}
    uint lambda_bits=(uint)values[0],q0_bits=(uint)values[1];
    if(lambda_bits<LAMBDA_MIN||lambda_bits>LAMBDA_MAX||q0_bits<Q0_MIN||q0_bits>Q0_MAX)return -1;
    float lambda=from_bits(lambda_bits),q0sqr=from_bits(q0_bits);
    float[256] image,coeff,north,south,west,east;
    for(usz i=0;i<PIXELS;i++){uint bits=(uint)values[i+2];if(bits<J_MIN||bits>J_MAX)return -1;image[i]=from_bits(bits);}
    for(usz row=0;row<16;row++)for(usz col=0;col<16;col++){
        usz i=row*16+col;float jc=image[i];
        float n=sub32(image[(row>0?row-1:row)*16+col],jc),s=sub32(image[(row<15?row+1:row)*16+col],jc);
        float w=sub32(image[row*16+(col>0?col-1:col)],jc),e=sub32(image[row*16+(col<15?col+1:col)],jc);
        north[i]=n;south[i]=s;west[i]=w;east[i]=e;
        float gradient=add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e));
        gradient=div32(gradient,mul32(jc,jc));
        float laplacian=div32(add32(add32(add32(n,s),w),e),jc);
        float lap_sq=mul32(laplacian,laplacian);
        float num=(float)(0.5*(double)gradient-(1.0/16.0)*(double)lap_sq);
        float den=(float)(1.0+0.25*(double)laplacian);if(den==0.0)return -1;
        float qsqr=div32(num,mul32(den,den));
        den=div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(1.0,q0sqr)));if(den==-1.0)return -1;
        float c=(float)(1.0/(1.0+(double)den));if(!math.is_finite((double)c))return -1;
        coeff[i]=c<0.0?0.0:c>1.0?1.0:c;
    }
    long checksum=0;
    for(usz row=0;row<16;row++)for(usz col=0;col<16;col++){
        usz i=row*16+col;float cc=coeff[i],cs=coeff[(row<15?row+1:row)*16+col],ce=coeff[row*16+(col<15?col+1:col)];
        float divergence=add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]));
        float updated=(float)((double)image[i]+0.25*(double)lambda*(double)divergence);
        if(!math.is_finite((double)updated)||updated<0.0)return -1;
        checksum+=(long)((double)updated*1000000.0+0.5);
    }
    return checksum;
}
