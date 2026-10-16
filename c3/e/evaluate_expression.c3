module evaluate_expression;
fn void put32(uint8 *o, uint32 x) { for (usz k=0;k<4;k++) o[k]=(uint8)(x>>(8*k)); }
fn void putf(uint8 *o, double x) { ulong b=@bitcast(ulong,x); for (usz k=0;k<8;k++) o[4+k]=(uint8)(b>>(8*k)); }
fn long evaluate_expression(long *v, usz n, uint8 *out, usz cap) @export("evaluate_expression") {
    if(v==null||n<3||n>131)return -1; long count=v[0]; if(count<1||count>64||n!=(usz)(1+2*count))return -1;
    double st[64]={0}; usz depth=0; bool valid=true;
    for(long i=0;i<count;i++){long op=v[1+2*i],x=v[2+2*i]; if(op==0){if(x < -1000000000||x>1000000000)return -1;st[depth++]=(double)x/1000.0;}
    else if(op>=1&&op<=4){if(x!=0)return -1;if(depth<2){valid=false;break;}double r=st[--depth],l=st[--depth];if(op==1)st[depth++]=l+r;else if(op==2)st[depth++]=l-r;else if(op==3)st[depth++]=l*r;else if(r==0.0){valid=false;break;}else st[depth++]=l/r;}
    else{valid=false;break;}}
    valid=valid&&depth==1; usz need=valid?12:4; if(out==null||cap<need)return -2; put32(out,valid?1:0);if(valid)putf(out,st[0]);return (long)need;
}
