// lspdb.c - Print all "key:value" pairs in a given PureDB .pdb file
// Build for local use: gcc lspdb.c -o lspdb
// Build for wider use: gcc -static lspdb.c -o lspdb

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

uint32_t getquad(uint8_t *db, uint32_t dblen, uint32_t addr) {
	if (addr+4 > dblen) {
		fprintf(stderr, "Error: PureDB database is corrupted\n");
		exit(1);
	}
	uint8_t a = *(db+addr), b = *(db+addr+1), c = *(db+addr+2), d = *(db+addr+3);
	return a*0x1000000 + b*0x10000 + c*0x100 + d;
}

void out(uint8_t *db, uint32_t dblen, uint32_t addr, uint32_t len) {
	if (addr+len > dblen) {
		fprintf(stderr, "Error: PureDB database is corrupted\n");
		exit(2);
	}
	for (uint32_t i=addr; i<addr+len; ++i) {
		printf("%c", *(db+i));
	}
}

int main(int argc, uint8_t *argv[]){
	if(argc != 2) {
		printf("lspdb - Print all 'key:value' pairs in a given PureDB .pdb file\n");
		printf("Usage: %s <PureDB.pdb>\n", argv[0]);
		exit(0);
	}
	uint8_t *filename = argv[1];
	FILE *file = fopen(filename, "r");
	if(!file){
		fprintf(stderr, "Error: file '%s' not found\n", filename);
		exit(3);
	}
	struct stat finfo;
	if(fstat(fileno(file), &finfo)) {
		fprintf(stderr, "Error: can't read file %s\n", filename);
		exit(4);
	}
	uint32_t dblen = finfo.st_size;
	if(dblen > 4294967296) {
		fprintf(stderr,"Error: too large for a PureDB file (4 GiB  max.)\n");
		exit(5);
	}
	uint8_t *db = malloc(dblen);
	fread(db, sizeof(uint8_t), dblen, file);
	fclose(file);
	if (*db != 'P' || *(db+1) != 'D' || *(db+2) != 'B' || *(db+3) != '2') {
		fprintf(stderr,"Error: wrong file magic for a PureDB file\n");
		exit(6);
	}
	uint32_t addr = getquad(db, dblen, 1028);
	uint32_t len;
	while (addr < dblen) {
		len = getquad(db, dblen, addr);
		out(db, dblen, addr+4, len);
		printf(":");
		addr += 4+len;
		len = getquad(db, dblen, addr);
		out(db, dblen, addr+4, len);
		printf("\n");
		addr += 4+len;
	}
	exit(0);
}
