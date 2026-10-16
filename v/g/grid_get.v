@[export: 'grid_get']
pub fn grid_get(values &i64, length usize) i64 {
 if unsafe { values == nil } || length < 3 || length > 4 { return -1 }
 operation, columns, index := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }
 if (operation != 0 && operation != 1) || columns < 1 || columns > 1000 || index < 0 || index > 10000 { return -1 }
 if operation == 0 {
  mut remaining := index
  for remaining + 1 > columns { remaining -= columns }
  return remaining + 1
 }
 return index / columns + 1
}
