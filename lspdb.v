// lspdb.v - Print all "key: value" pairs in a given PureDB .pdb file
// Build for local use: v -cc clang -prod lspdb.v
// Build for wider distribution: v -cc clang -cflags -static -prod lspdb.v

import os

fn getquad(db []u8, addr u32) u32 {
	return u32(db[addr])<<24 + u32(db[addr+1])<<16 + u32(db[addr+2])<<8 + db[addr+3]
}

fn out(db []u8, addr u32, len u32) {
	for i in addr..addr+len {
		print(db[i].ascii_str())
	}
}

fn main(){
	if os.args.len != 2 {
		eprintln('Error: a PureDB .pdb file needed as an argument to print out')
		exit(1)
	}
	file := os.args[1]
	db := os.read_bytes(file) or {
		eprintln('Error: file "${file}" not found')
		exit(2)
	}
	if db[0] != `P` && db[1] != `D` && db[2] != `B` && db[3] != `2` {
		eprintln('Error: file magic wrong for a PureDB file')
		exit(3)
	}
	mut addr := getquad(db, 1028)
	mut len := u32(0)
	for addr < db.len {
		len = getquad(db, addr)
		out(db, addr+4, len)
		print(': ')
		addr += 4+len
		len = getquad(db, addr)
		out(db, addr+4, len)
		println('')
		addr += 4+len
	}
}
