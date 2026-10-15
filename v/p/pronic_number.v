module pronic_number

import math

@[export: 'pronic_number']
pub fn pronic_number(n i64) i64 {
	if n < 0 || n > 2_147_483_647 { return -1 }
	root := i64(math.sqrt(f64(n)))
	if root * (root + 1) == n { return 1 }
	return 0
}
