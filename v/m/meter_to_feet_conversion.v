module meter_to_feet_conversion
@[export: 'meter_to_feet_conversion']
pub fn meter_to_feet_conversion(v &i64, n usize) f64 {
    if n != 2 { return -1.0e300 }
    unsafe {
        op,units:=v[0],v[1]
        if (op != 0 && op != 1) || units < -1000000000 || units > 1000000000 { return -1.0e300 }
        value:=f64(units)/1000.0
        if op == 0 { return value*0.3048 }
        return value/0.3048
    }
}
