package prefix_evaluation
import "core:c"
INVALID :: -1e300
is_op :: proc(c:u8)->bool{return c=='+'||c=='-'||c=='*'||c=='/'}
@(export)
prefix_evaluation :: proc "c" (v:[^]i64,n:c.size_t)->f64{if v==nil||n<2||n>63||v[0]<1||v[0]>62||n!=c.size_t(v[0]+1) do return INVALID;tokens:[31]u8;count:=0;need:=true;for i:=1;i<int(n);i+=1{x:=v[i];if x<0||x>127 do return INVALID;c:=u8(x);if c==' '{if need do return INVALID;need=true;continue};if !(is_op(c)||(c>='0'&&c<='9'))||!need||count>=31 do return INVALID;tokens[count]=c;count+=1;need=false};if need||count==0 do return INVALID;stack:[31]f64;top:=0;for p:=count-1;p>=0;p-=1{c:=tokens[p];if c>='0'&&c<='9'{stack[top]=f64(c-'0');top+=1;continue};if top<2 do return INVALID;top-=1;a:=stack[top];top-=1;b:=stack[top];result:=f64(0);if c=='+'{result=a+b}else if c=='-'{result=a-b}else if c=='*'{result=a*b}else{if b==0 do return INVALID;result=a/b};stack[top]=result;top+=1};if top==1&&abs(stack[0])<1e300 do return stack[0];return INVALID}
