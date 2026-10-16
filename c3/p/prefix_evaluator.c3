module prefix_evaluator;
const i64 ADD=-9000000000000000001;const i64 SUB=-9000000000000000002;const i64 MUL=-9000000000000000003;const i64 DIV=-9000000000000000004;
fn long prefix_evaluator(long* v,usz n) @export("prefix_evaluator") {
 if(v==null||n<2||n>129||v[0]<1||v[0]>128||n!=(usz)(v[0]+1))return -1;
 int[128] st;usz sp=0;usz i=n;
 while(i>1){i-=1;long t=v[i];if(t==ADD||t==SUB||t==MUL||t==DIV){if(sp<2)return -1;int a=st[sp-1],b=st[sp-2];sp-=2;int z=0;if(t==ADD)z=(int)((uint)a+(uint)b);else if(t==SUB)z=(int)((uint)a-(uint)b);else if(t==MUL)z=(int)((uint)a*(uint)b);else{if(b==0)return -1;z=(a==-2147483648&&b==-1)?-2147483648:a/b;}st[sp]=z;sp+=1;}else{if(t < -2147483648||t>2147483647||sp>=128)return -1;st[sp]=(int)t;sp+=1;}}
 return sp==1?st[0]:-1;
}
