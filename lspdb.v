// lspdb.v - Print all "key:value" pairs in a given PureDB .pdb file
// Build for local use: v -cc clang -prod lspdb.v
// Build for wider distribution: v -cc clang -cflags -static -prod lspdb.v

import encoding.binary
import os

fn getquad(db []u8, addr u32) u32 {
	if addr+4 > db.len {
		eprintln('Error: bad address, PureDB database is corrupted')
		exit(3)
	}
	return binary.big_endian_u32_at(db, int(addr))
}

fn out(db []u8, addr u32, len u32) {
	if addr+len > db.len {
		eprintln('Error: bad length, PureDB database is corrupted')
		exit(4)
	}
	for i in addr..addr+len {
		print_character(db[i])
	}
}

fn main(){
	if os.args.len != 2 {
		eprintln('lspdb - Print all "key:value" pairs in a given PureDB .pdb file')
		eprintln('Usage: '+os.args[0]+' <PureDB.pdb>')
		exit(0)
	}
	file := os.args[1]
	db := os.read_bytes(file) or {
		eprintln('Error: file "${file}" not found')
		exit(1)
	}
	if db[0] != `P` || db[1] != `D` || db[2] != `B` || db[3] != `2` {
		eprintln('Error: file magic wrong for a PureDB file')
		exit(2)
	}
	mut addr := getquad(db, 1028)
	mut len := u32(0)
	for addr < db.len {
		len = getquad(db, addr)
		out(db, addr+4, len)
		print(':')
		addr += 4+len
		len = getquad(db, addr)
		out(db, addr+4, len)
		println('')
		addr += 4+len
	}
}
