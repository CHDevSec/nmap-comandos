#!/usr/bin/env bash
# Recon com nmap em 2 etapas:
#   1. varre as 65.535 portas TCP só pra achar as abertas (rápido);
#   2. roda detecção de versão (-sV) e scripts padrão (-sC) só nas abertas.
# Opcional (-u): também varre as top portas UDP (SNMP, DNS, NTP...).
# Tudo fica salvo em <pasta>/etapa1.* , <pasta>/etapa2.* e <pasta>/udp.* (.nmap, .xml, .gnmap).
#
# Só use em alvo que você tem autorização pra testar.
# https://github.com/CHDevSec/nmap-comandos
set -euo pipefail

usage() {
  cat <<EOF
Uso: $(basename "$0") [-o pasta] [-t 0-5] [-r pacotes/s] [-u] [-U N] <alvo>

  <alvo>      IP, domínio ou faixa (ex.: scanme.nmap.org, 10.10.10.5)
  -o pasta    onde salvar (padrão: recon-<alvo>-<data>)
  -t 0-5      velocidade do nmap, -T (padrão: 4)
  -r N        pacotes por segundo mínimos na etapa 1, --min-rate (padrão: nenhum)
  -u          também varre as 20 portas UDP mais comuns (precisa de sudo)
  -U N        igual ao -u, mas com as N portas UDP mais comuns
  -h          esta ajuda

Com sudo usa SYN scan (-sS, mais rápido); sem sudo, connect scan (-sT).
O scan UDP (-u) só roda com privilégio (sudo); sem ele, é ignorado com aviso.

Exemplos:
  $(basename "$0") scanme.nmap.org
  sudo $(basename "$0") -u -r 1000 10.10.10.5
  sudo $(basename "$0") -U 100 10.10.10.5
EOF
}

timing=4
rate=""
out=""
udp=0
udp_top=20
while getopts ":o:t:r:uU:h" opt; do
  case $opt in
    o) out=$OPTARG ;;
    t) timing=$OPTARG ;;
    r) rate=$OPTARG ;;
    u) udp=1 ;;
    U) udp=1; udp_top=$OPTARG ;;
    h) usage; exit 0 ;;
    :) echo "erro: -$OPTARG precisa de um valor" >&2; usage >&2; exit 2 ;;
    *) echo "erro: opção -$OPTARG não existe" >&2; usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi
target=$1

command -v nmap >/dev/null || { echo "erro: nmap não instalado (veja o README)" >&2; exit 1; }
[[ $timing =~ ^[0-5]$ ]] || { echo "erro: -t vai de 0 a 5" >&2; exit 2; }
[[ -z $rate || $rate =~ ^[0-9]+$ ]] || { echo "erro: -r precisa ser um número" >&2; exit 2; }
[[ $udp_top =~ ^[0-9]+$ ]] || { echo "erro: -U precisa de um número de portas (ex.: -U 100)" >&2; exit 2; }

if [[ $EUID -eq 0 ]]; then
  scan=-sS
else
  scan=-sT
fi

# UDP exige privilégio pra montar pacote cru; sem sudo, avisa e segue só com TCP.
if [[ $udp -eq 1 && $EUID -ne 0 ]]; then
  echo "[!] -u ignorado: scan UDP precisa de sudo. Rode 'sudo $(basename "$0") -u ...'." >&2
  udp=0
fi

out=${out:-recon-${target//[^A-Za-z0-9._-]/_}-$(date +%Y%m%d-%H%M)}
mkdir -p "$out"

echo "[!] Só continue se você tem autorização pra escanear: $target"
echo "[*] Resultados em: $out/"
echo

echo "[1/2] Todas as portas TCP ($scan -T$timing${rate:+ --min-rate $rate})..."
nmap $scan -p- -T"$timing" ${rate:+--min-rate "$rate"} --open -oA "$out/etapa1" "$target" >/dev/null

ports=$(grep -oE '[0-9]+/open/' "$out/etapa1.gnmap" | cut -d/ -f1 | sort -nu | paste -sd, - || true)
if [[ -z $ports ]]; then
  echo "[-] Nenhuma porta TCP aberta. Se o host bloqueia ping, rode o nmap com -Pn (veja o README)."
else
  echo "      abertas: $ports"
  echo
  echo "[2/2] Versão e scripts padrão nas abertas (-sC -sV)..."
  nmap $scan -sC -sV -p "$ports" -T"$timing" -oA "$out/etapa2" "$target" >/dev/null
fi

# Etapa UDP opcional (top N portas, com -sV pra reduzir o "open|filtered").
if [[ $udp -eq 1 ]]; then
  echo
  echo "[udp] Top $udp_top portas UDP (-sU -sV, costuma ser lento)..."
  nmap -sU -sV --top-ports "$udp_top" -T"$timing" --open -oA "$out/udp" "$target" >/dev/null || \
    echo "[-] Scan UDP falhou ou foi interrompido; o que deu certo está em $out/udp.*"
fi

echo
echo "===== RESUMO ====="
if [[ -f "$out/etapa2.nmap" ]]; then
  grep -E '^[0-9]+/(tcp|udp) +open' "$out/etapa2.nmap" || true
fi
if [[ -f "$out/udp.nmap" ]]; then
  grep -E '^[0-9]+/udp +open' "$out/udp.nmap" || true
fi
echo
echo "[+] Pronto. Relatórios completos em: $out/"
[[ -f "$out/etapa2.nmap" ]] && echo "    TCP: $out/etapa2.nmap"
[[ -f "$out/udp.nmap" ]] && echo "    UDP: $out/udp.nmap"
exit 0
