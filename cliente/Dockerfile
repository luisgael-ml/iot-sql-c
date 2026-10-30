# ---------- Etapa 1: precompilar y compilar el programa en C ----------
FROM debian:bookworm-slim AS compilacion
RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc make libc6-dev libecpg-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY Makefile iot_crud.pgc ./
RUN make            # ecpg iot_crud.pgc -> iot_crud.c -> gcc -> iot_crud

# ---------- Etapa 2: imagen final solo con el ejecutable ----------
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends libecpg6 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=compilacion /src/iot_crud /usr/local/bin/iot_crud
COPY --from=compilacion /src/iot_crud.c /opt/iot/iot_crud.c
CMD ["sleep", "infinity"]
