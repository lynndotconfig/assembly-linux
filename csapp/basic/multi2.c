long multi2(long, long);

void multistore(long x, long y, long *dest) {
	long t = multi2(x, y);
	*dest = t;
}