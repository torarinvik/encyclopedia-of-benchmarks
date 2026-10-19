module nbench_neural_network;

import "math";

fn void put_i64(char* out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b=0;b<8;b++) out[offset+b]=(char)(bits>>(8*b));
}

fn long nbench_neural_network(long* input, usz length, char* output, usz capacity) @export("nbench_neural_network") {
    if (input==null || length!=1 || input[0]<1 || input[0]>8) return -1;
    if (output==null || capacity<88) return -2;
    double[35] pattern={0,1,1,1,0,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1,1,1,0};
    double[8] target={0,1,0,0,1,1,1,1};
    double[8][35] mw={}; double[8][8] ow={};
    double[8][35] mc={}; double[8][8] oc={}; double[8][35] mm={}; double[8][8] om={};
    double[8] mout={}; double[8] oout={};
    for (usz n=0;n<8;n++) for (usz w=0;w<35;w++) mw[n][w]=((double)((n*17+w*7)%101)-50.0)/1000.0;
    for (usz n=0;n<8;n++) for (usz w=0;w<8;w++) ow[n][w]=((double)((n*13+w*5)%71)-35.0)/1000.0;
    for (long pass=0;pass<input[0];pass++) {
        for (usz n=0;n<8;n++) for (usz w=0;w<35;w++) { mc[n][w]=mm[n][w]; mm[n][w]=0.0; }
        for (usz n=0;n<8;n++) for (usz w=0;w<8;w++) { oc[n][w]=om[n][w]; om[n][w]=0.0; }
        for (usz f=0;f<2;f++) for (usz n=0;n<8;n++) { double sum=0.0; for (usz w=0;w<35;w++) sum+=mw[n][w]*pattern[w]; mout[n]=1.0/(1.0+exp(-sum)); }
        for (usz n=0;n<8;n++) { double sum=0.0; for (usz w=0;w<8;w++) sum+=ow[n][w]*mout[w]; oout[n]=1.0/(1.0+exp(-sum)); }
        double[8] oe={}; double[8] me={};
        for (usz n=0;n<8;n++) oe[n]=target[n]-oout[n];
        for (usz n=0;n<8;n++) { double sum=0.0; for (usz i=0;i<8;i++) sum+=ow[i][n]*oe[i]; me[n]=mout[n]*(1.0-mout[n])*sum; }
        for (usz n=0;n<8;n++) for (usz w=0;w<8;w++) { double d=0.09*oe[n]*mout[w]; d+=0.09*oc[n][w]; ow[n][w]+=d; om[n][w]+=d; }
        for (usz n=0;n<8;n++) for (usz w=0;w<35;w++) { double d=0.09*me[n]*pattern[w]; d+=0.09*mc[n][w]; mw[n][w]+=d; mm[n][w]+=d; }
    }
    long[11] result={}; result[0]=input[0];
    for (usz n=0;n<8;n++) result[n+1]=(long)(oout[n]*1000000.0);
    double ms=0.0, os=0.0;
    for (usz n=0;n<8;n++) for (usz w=0;w<35;w++) ms+=mw[n][w];
    for (usz n=0;n<8;n++) for (usz w=0;w<8;w++) os+=ow[n][w];
    result[9]=(long)(ms*1000000.0); result[10]=(long)(os*1000000.0);
    for (usz i=0;i<11;i++) put_i64(output,i*8,result[i]);
    return 88;
}
