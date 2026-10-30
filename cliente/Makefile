# 1) ecpg traduce el SQL embebido (.pgc) a C puro (.c)
# 2) gcc compila el .c y lo enlaza con la biblioteca libecpg
CC      = gcc
CFLAGS  = -Wall -O2 -I/usr/include/postgresql
LDLIBS  = -lecpg

iot_crud: iot_crud.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

iot_crud.c: iot_crud.pgc
	ecpg -o $@ $<

clean:
	rm -f iot_crud iot_crud.c
