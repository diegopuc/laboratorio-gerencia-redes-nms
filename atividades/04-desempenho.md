# 04 — Desempenho e contabilização
Execute `docker compose exec servidor1 iperf3 -c servidor2 -t 360 -b 10M`. Compare gráficos de interfaces antes e depois e estime volume de tráfego. Compare throughput com contadores SNMP. Use o menu para simular perda e CPU; compare ping e docker stats. Remova a perda ao terminar. Explique por que tráfego por interface não equivale a contabilização por usuário.
