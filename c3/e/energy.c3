module energy;
const long MAX_VALUE_MICRO=1000000000000;
const long SCALE=1000000;
const usz MAX_INPUT_LENGTH=4;
const double INVALID_RESULT=-1.0e300;
const double[55] JOULES_PER_UNIT={
    1.0, 1000.0, 1000000.0, 1000000000.0, 0.001,
    1.0e-6, 1.0e-9, 1.0e-18, 1.0, 3600.0,
    1000.0, 3600000.0, 3600000000.0, 3600000000000.0, 1.0,
    1.0e-7, 1.0e-7, 4186.8, 4186800.0, 4.1868,
    4186.8, 4.184, 4184.0, 1.602176634e-19, 1.602176634e-16,
    1.602176634e-13, 1055.05585262, 1054.3499999744, 1055055852.62, 1.3558179483,
    1.3558179483, 0.112984829, 0.112984829, 0.0070615518, 0.0070615518,
    0.04214011, 2684519.5368856, 2647795.5, 9.8066499997, 0.0980665,
    9.8066499997, 0.00980665, 9.80665e-5, 105505600.0, 105505600.0,
    105480400.0, 12660670.23144, 40197627984.822, 6383087908.3509, 4184000000.0,
    4184000000000.0, 4.184e15, 4.184e18, 4.3597482e-18, 2.1798741e-18
};
fn double energy(long* values,usz length) @export("energy") {
 if(values==null||length!=3||length>MAX_INPUT_LENGTH)return INVALID_RESULT;
 long value_micro=values[0],from_unit=values[1],to_unit=values[2];
 if(value_micro < -MAX_VALUE_MICRO || value_micro > MAX_VALUE_MICRO || from_unit<0 || from_unit>54 || to_unit<0 || to_unit>54)return INVALID_RESULT;
 double value=(double)value_micro/(double)SCALE;
 double joules=value*JOULES_PER_UNIT[(usz)from_unit];
 return joules/JOULES_PER_UNIT[(usz)to_unit];
}
