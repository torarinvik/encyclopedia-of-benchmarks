const BAD:f64=-1.0e300;
fn fact(n:i64)->f64{let mut f=1.0;for i in 2..=n{f*=i as f64;}f}
fn term(m:i64,x:f64,i:i64)->f64{let(e,s)=if m==0{(i,1.0)}else if m==1{(2*i+1,if i%2==0{1.0}else{-1.0})}else{(2*i,if i%2==0{1.0}else{-1.0})};if m==0{x.powf(e as f64)/fact(e)}else{s/fact(e)*x.powf(e as f64)}}
#[no_mangle] pub extern "C" fn maclaurin(v:*const i64,n:usize)->f64{if v.is_null()||n!=3{return BAD;}let(m,xm,em)=unsafe{(*v,*v.add(1),*v.add(2))};if !(0..=2).contains(&m)||!(-2000..=2000).contains(&xm)||!(1..=250).contains(&em){return BAD;}let x=xm as f64/1000.0;let error=em as f64/1000.0;let(mut coefficient,mut result)=(0.0,0.0);for i in 0..32{result+=coefficient;coefficient=term(m,x,i);if coefficient.abs()<=error{return result;}}BAD}
