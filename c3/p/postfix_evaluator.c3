module postfix_evaluator;
const i64 ADD = -9000000000000000001;
const i64 SUB = -9000000000000000002;
const i64 MUL = -9000000000000000003;
const i64 DIV = -9000000000000000004;
fn long postfix_evaluator(long* v, usz n) @export("postfix_evaluator") {
 if (v == null || n < 2 || n > 129 || v[0] < 1 || v[0] > 128 || n != (usz)(v[0] + 1)) return -1;
 int[128] stack; usz sp = 0;
 for (usz i=1; i<n; i+=1) { long t=v[i];
  if (t==ADD || t==SUB || t==MUL || t==DIV) { if(sp<2)return -1; int b=stack[sp-1], a=stack[sp-2], z=0; sp-=2;
   if(t==ADD) z=(int)((uint)a+(uint)b); else if(t==SUB) z=(int)((uint)a-(uint)b); else if(t==MUL) z=(int)((uint)a*(uint)b); else { if(b==0)return -1; z=(a==-2147483648 && b==-1)?-2147483648:a/b; }
   stack[sp]=z; sp+=1;
  } else { if(t < -2147483648 || t > 2147483647 || sp>=128)return -1; stack[sp]=(int)t; sp+=1; }
 }
 return sp==1 ? stack[0] : -1;
}
