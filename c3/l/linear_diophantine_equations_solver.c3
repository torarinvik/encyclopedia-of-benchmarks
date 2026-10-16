module linear_diophantine_equations_solver;
fn long linear_diophantine_equations_solver(long*v,usz n) @export("linear_diophantine_equations_solver") {
 if(v==null||n!=3)return -1;
 long a=v[0],b=v[1],c=v[2];if(a< -1000||a>1000||b< -1000||b>1000||c< -10000||c>10000)return -1;
 if(a==0&&b==0)return c==0?-3:-2;if(a==0)return c%b==0?(0+10000001)*20000003+(c/b+10000001):-2;if(b==0)return c%a==0?(c/a+10000001)*20000003+10000001:-2;
 long or=a,r=b,os=1,s=0,ot=0,t=1;while(r!=0){long q=or/r;long z=or-q*r;or=r;r=z;z=os-q*s;os=s;s=z;z=ot-q*t;ot=t;t=z;}
 if(c%or!=0)return -2;long x=os*(c/or),y=ot*(c/or);return (x+10000001)*20000003+(y+10000001);
}
