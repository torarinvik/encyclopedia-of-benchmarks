const INVALID:f64=-1.0e300;
#[no_mangle]
pub unsafe extern "C" fn simple_neural_network(values:*const i64,length:usize)->f64{if values.is_null()||length!=3{return INVALID;}let expected=*values;let initial=*values.add(1);let count=*values.add(2);if expected<0||expected>100||initial<1||initial>199||initial%2!=1||count<1||count>65536{return INVALID;}let target=expected as f64/100.0;let mut weight=initial as f64;let mut layer=0.0;for _ in 0..count{layer=1.0/(1.0+(-0.02*weight).exp());let error=target-layer;let delta=error*layer*(1.0-layer);weight+=0.02*delta;}layer*100.0}
