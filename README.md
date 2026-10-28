# nmap-comandos

Os comandos de nmap que eu uso de verdade em pentest, organizados por objetivo e
explicados pra quem está começando. Cada comando tem uma linha dizendo o que ele faz e
quando usar.

Veio do vídeo **"Teu nmap só olha 1.000 portas"** do [@chdevsec](https://www.instagram.com/chdevsec/).

> [!WARNING]
> **Só escaneie o que você tem autorização por escrito pra testar.** Escanear rede dos
> outros sem permissão pode ser crime (no Brasil, Lei 12.737/2012) e, no mínimo, te
> rende bloqueio e dor de cabeça com o provedor. Pra treinar, use `scanme.nmap.org` (o
> próprio projeto Nmap libera, com moderação: nada de flood nem centenas de scans por
> dia), a tua rede de casa ou um laboratório como o
> [Hack The Box](https://www.hackthebox.com/) e o [TryHackMe](https://tryhackme.com/).

## Sumário

- [Instalar](#instalar)
- [Os 3 do vídeo](#os-3-do-vídeo)
- [O scan que eu rodo primeiro](#o-scan-que-eu-rodo-primeiro)
- [Descobrir quem está na rede](#descobrir-quem-está-na-rede)
- [Escolher as portas](#escolher-as-portas)
- [Tipos de scan](#tipos-de-scan)
- [UDP: a metade que todo mundo esquece](#udp-a-metade-que-todo-mundo-esquece)
- [Serviço, versão e sistema](#serviço-versão-e-sistema)
- [Scripts (NSE)](#scripts-nse)
- [Scripts por serviço](#scripts-por-serviço)
- [Firewall no caminho](#firewall-no-caminho)
- [Velocidade](#velocidade)
- [Salvar o resultado](#salvar-o-resultado)
- [Usar o resultado em outras ferramentas](#usar-o-resultado-em-outras-ferramentas)
- [Vários alvos](#vários-alvos)
- [Recon automático em 2 etapas](#recon-automático-em-2-etapas)
- [Fluxo de pentest: interna x externa](#fluxo-de-pentest-interna-x-externa)
- [Deu problema?](#deu-problema)
- [Cheatsheet](#cheatsheet)
- [Pra ir além](#pra-ir-além)

## Instalar

| Sistema | Comando |
|---|---|
| Kali / Parrot | já vem instalado |
| Debian / Ubuntu | `sudo apt install nmap` |
| Fedora | `sudo dnf install nmap` |
| Arch | `sudo pacman -S nmap` |
| macOS | `brew install nmap` |
| Windows | instalador em [nmap.org/download](https://nmap.org/download.html) |

Confere com `nmap --version`.

## Os 3 do vídeo

```bash
nmap scanme.nmap.org           # as 1.000 portas TCP mais comuns
nmap -sV scanme.nmap.org       # + qual programa e versão está em cada porta
nmap -p- scanme.nmap.org       # todas as 65.535 portas TCP
```

No padrão o nmap olha só as 1.000 portas TCP mais comuns. Porta fora dessa lista não
aparece: é por isso que o `-p-` existe. E é com a **versão** (`-sV`) que você procura
CVE: "Apache httpd 2.4.7" você pesquisa, "http" não.

## O scan que eu rodo primeiro

```bash
nmap -p- -sV -T4 alvo
```

Todas as portas, com programa e versão, num ritmo mais rápido que o padrão. Em alvo
real isso pode levar muito tempo; a versão em 2 etapas da seção
[Recon automático](#recon-automático-em-2-etapas) é bem mais rápida.

## Descobrir quem está na rede

```bash
nmap -sn 192.168.0.0/24        # quem está ligado na rede, sem escanear porta
sudo nmap -sn 192.168.0.0/24   # na rede local, com sudo usa ARP: mais rápido e confiável
nmap -sL 192.168.0.0/24        # só lista os IPs que seriam escaneados (não manda pacote pros alvos)
nmap -Pn alvo                  # pula a descoberta e escaneia mesmo que o host "pareça desligado"
nmap -n alvo                   # não faz DNS reverso de cada IP: acelera bastante em rede grande
```

Troque `192.168.0.0/24` pela tua rede (`ip a` no Linux, `ipconfig` no Windows).

## Escolher as portas

```bash
nmap -p 22,80,443 alvo         # só essas
nmap -p 1-1024 alvo            # um intervalo
nmap -p- alvo                  # todas (1 a 65535)
nmap -F alvo                   # rápido: as 100 mais comuns
nmap --top-ports 2000 alvo     # as N mais comuns
nmap -p U:53,161,T:22,80 alvo  # mistura UDP e TCP (precisa de -sU junto, veja abaixo)
nmap --open alvo               # mostra só as portas abertas
```

## Tipos de scan

```bash
sudo nmap -sS alvo             # SYN scan: o padrão com sudo, rápido e não completa a conexão
nmap -sT alvo                  # connect scan: o padrão sem sudo, completa a conexão
sudo nmap -sU --top-ports 20 alvo   # UDP (DNS, SNMP, NTP...): lento, comece pelas mais comuns
```

Sem `sudo` o nmap não consegue montar pacote cru, então cai no `-sT`. Com `sudo`, `-sS`.

## UDP: a metade que todo mundo esquece

Muita coisa boa mora em UDP: DNS (53), DHCP (67), TFTP (69), NTP (123), SNMP (161),
IPMI (623), IKE/VPN (500). E o scan padrão é **só TCP**.

```bash
sudo nmap -sU --top-ports 20 alvo              # as 20 UDP mais comuns: o mínimo em todo recon
sudo nmap -sU --top-ports 100 -T4 alvo         # mais cobertura, ainda dá pra esperar
sudo nmap -sU -sV -p 53,123,161 alvo           # -sV ajuda a tirar a dúvida do "open|filtered"
sudo nmap -sS -sU -p T:22,80,443,U:53,161 alvo # TCP e UDP no mesmo scan
```

UDP é lento porque porta aberta normalmente não responde nada, aí o nmap fica esperando
e retransmitindo. Por isso aparece tanto `open|filtered`: sem resposta, ele não sabe se
é porta aberta ou firewall. `-p-` em UDP leva horas; não comece por aí.

## Serviço, versão e sistema

```bash
nmap -sV alvo                  # programa e versão em cada porta aberta
nmap -sV --version-all alvo    # tenta todos os testes pra acertar a versão (igual a --version-intensity 9, mais lento)
nmap -sC -sV alvo              # versão + scripts padrão (título de site, chaves SSH, etc.)
sudo nmap -O alvo              # tenta adivinhar o sistema operacional
sudo nmap -A alvo              # tudo junto: -O, -sV, -sC e traceroute
```

## Scripts (NSE)

O nmap vem com centenas de scripts (o NSE). Cada script tem **categorias**: `safe` só
observa, `intrusive` pode incomodar o serviço, `brute` tenta senha, `dos` pode derrubar,
`external` manda dado pra um serviço de fora. O `-sC` roda a categoria `default`.

```bash
nmap --script-help http-title                 # explica o que um script faz e as categorias dele
nmap --script "safe" -p 80 alvo               # só scripts que não deveriam causar impacto
nmap --script "http-*" -p 80,443 alvo         # todos que começam com http- (cuidado: inclui intrusivos)
nmap --script "vuln and safe" alvo            # checagem de vulnerabilidade sem os scripts perigosos
```

```bash
nmap --script vuln alvo        # todos os scripts de vulnerabilidade
```

> [!CAUTION]
> A categoria `vuln` inclui scripts **intrusivos** e alguns marcados como `dos` (por
> exemplo `smb-vuln-ms08-067`), que podem derrubar serviço frágil. Só em alvo autorizado,
> combinado com o cliente e de preferência fora do horário de produção. No dia a dia,
> prefira `--script "vuln and safe"`.

A lista completa fica em `/usr/share/nmap/scripts/` e em
[nmap.org/nsedoc](https://nmap.org/nsedoc/). Pra ver as categorias de um script sem abrir
a doc: `grep categories /usr/share/nmap/scripts/http-enum.nse`.

## Scripts por serviço

Achou a porta aberta, e agora? Os scripts que eu rodo primeiro em cada serviço. Os
marcados com ⚠️ são **intrusivos** (fazem muitas requisições, testam login ou forçam o
serviço): só com autorização explícita pra esse tipo de teste.

**HTTP / HTTPS (80, 443, 8080, 8443)**

```bash
nmap -sV --script http-title,http-headers,http-methods,http-robots.txt -p 80,443 alvo   # o básico de todo site
nmap --script ssl-cert -p 443 alvo                 # certificado: os nomes no SAN costumam revelar outros hosts
nmap --script http-security-headers -p 443 alvo    # quais cabeçalhos de segurança faltam
nmap --script ssl-enum-ciphers -p 443 alvo         # ⚠️ versões de TLS e cifras aceitas (abre muitas conexões)
nmap --script http-enum -p 80,443 alvo             # ⚠️ procura painéis e diretórios conhecidos (centenas de requisições)
```

**SMB (139, 445): Windows e compartilhamento de arquivos**

```bash
nmap --script smb-protocols -p 445 alvo                 # quais versões de SMB respondem (SMBv1 ligado já é achado)
nmap --script smb2-security-mode,smb2-time -p 445 alvo  # se a assinatura SMB é exigida e a hora do servidor
nmap --script smb-os-discovery -p 445 alvo              # sistema e nome da máquina (depende de SMBv1 ligado)
nmap --script smb-vuln-ms17-010 -p 445 alvo             # checa o EternalBlue (esse script é marcado como safe)
nmap --script smb-enum-shares -p 445 alvo               # ⚠️ lista compartilhamentos acessíveis
```

**SSH (22)**

```bash
nmap --script ssh2-enum-algos -p 22 alvo   # algoritmos que o SSH aceita (procure os fracos)
nmap --script ssh-hostkey -p 22 alvo       # fingerprint das chaves do servidor
nmap --script ssh-auth-methods -p 22 alvo  # ⚠️ se aceita senha ou só chave
```

**FTP (21)**

```bash
nmap --script ftp-anon,ftp-syst -p 21 alvo   # login anônimo liberado? e qual o sistema
```

**DNS (53)**

```bash
nmap -sU --script dns-recursion,dns-nsid -p 53 alvo   # o servidor responde recursão pra qualquer um?
nmap --script dns-zone-transfer --script-args dns-zone-transfer.domain=dominio.com -p 53 ns.dominio.com   # ⚠️ tenta transferência de zona (AXFR)
nmap -sn --script dns-brute dominio.com               # ⚠️ tenta achar subdomínios comuns por tentativa
```

**SMTP (25, 465, 587)**

```bash
nmap --script smtp-commands,smtp-ntlm-info -p 25,587 alvo   # comandos aceitos e, em Exchange, nome interno do domínio
nmap --script smtp-open-relay -p 25 alvo                    # ⚠️ testa se o servidor é relay aberto (tenta enviar e-mail)
```

**Bancos de dados**

```bash
nmap -sV --script mysql-info -p 3306 alvo                     # MySQL / MariaDB: versão e capacidades
nmap -sV --script ms-sql-info,ms-sql-ntlm-info -p 1433 alvo   # SQL Server: instância e nome do domínio
nmap -sV --script mongodb-info -p 27017 alvo                  # MongoDB: se responde, muitas vezes está sem senha
nmap -sV --script redis-info -p 6379 alvo                     # Redis: idem, sem senha é comum
nmap --script mysql-empty-password -p 3306 alvo              # ⚠️ testa root sem senha (tentativa de login)
```

**SNMP (161/udp)**

```bash
sudo nmap -sU --script snmp-info,snmp-sysdescr -p 161 alvo            # identifica o equipamento
sudo nmap -sU --script snmp-interfaces,snmp-processes -p 161 alvo     # interfaces e processos, se a community "public" valer
sudo nmap -sU --script snmp-brute -p 161 alvo                         # ⚠️ tenta descobrir a community string
```

**Outros que aparecem muito**

```bash
nmap --script rdp-ntlm-info -p 3389 alvo       # RDP: nome da máquina e do domínio
nmap --script nfs-showmount -p 111 alvo        # NFS: pastas exportadas pra rede
nmap --script rpcinfo -p 111 alvo              # serviços registrados no portmapper
nmap --script vnc-info -p 5900 alvo            # VNC: tipo de autenticação
```

## Firewall no caminho

Quando tudo volta `filtered` ou o host "parece desligado", normalmente é firewall
descartando pacote. O que ajuda **sem** entrar em técnica de evasão (isso fica fora deste
repo de propósito):

```bash
nmap -Pn alvo                  # não tenta ping antes: escaneia mesmo sem resposta de descoberta
nmap --reason alvo             # mostra por que cada porta ficou aberta/fechada/filtrada
nmap -sA -p 80,443 alvo        # ACK scan: ajuda a entender se existe firewall com estado no caminho
```

Existe `-g/--source-port` pra usar uma porta de origem fixa (alguns firewalls antigos
confiam em tráfego vindo da 53 ou 80). Use só quando fizer sentido técnico e estiver no
escopo combinado, não como truque pra "passar despercebido".

## Velocidade

```bash
nmap -T4 alvo                  # mais rápido que o padrão (-T3); bom pra rede estável
nmap -T2 alvo                  # mais lento e discreto
nmap --min-rate 1000 alvo      # pelo menos 1000 pacotes por segundo
nmap --max-retries 1 alvo      # desiste antes de porta que não responde
nmap --host-timeout 30m alvo   # pula o host se passar de 30 minutos
nmap --stats-every 30s alvo    # imprime o progresso a cada 30s em scan demorado
```

Rápido demais em rede ruim faz o nmap **perder porta**. Na dúvida, `-T4` e mais nada.

## Salvar o resultado

```bash
nmap -oN scan.txt alvo         # texto, igual à tela
nmap -oX scan.xml alvo         # XML, pra importar em outras ferramentas
nmap -oG scan.gnmap alvo       # "grepável": uma linha por host
nmap -oA scan alvo             # os três de uma vez (scan.nmap, scan.xml, scan.gnmap)
nmap --resume scan.gnmap       # continua um scan interrompido (salvo com -oG ou -oA)
```

Use `-v` pra ver as portas aparecendo enquanto roda e `--reason` pra saber por que o
nmap decidiu que a porta está aberta, fechada ou filtrada. Os estados estão explicados
em [docs/como-ler-a-saida.md](docs/como-ler-a-saida.md).

## Usar o resultado em outras ferramentas

O XML (`-oX` ou `-oA`) é o que outras ferramentas leem. Dois usos que valem o dia a dia:

```bash
nmap -sV -oX scan.xml alvo                                   # salva em XML
xsltproc scan.xml -o scan.html                              # vira um relatório HTML pra abrir no navegador
```

O `xsltproc` usa a folha de estilo que já vem com o nmap, então o HTML fica com cara de
relatório sem configurar nada. Se o `xsltproc` reclamar que não acha o estilo, aponte na
mão: `nmap -sV --stylesheet /usr/share/nmap/nmap.xsl -oX scan.xml alvo`.

Do `-oG` (grepável) dá pra puxar a lista de hosts com uma porta aberta pra jogar na
próxima ferramenta:

```bash
# IPs com a 445 aberta, um por linha (pra alimentar outra ferramenta)
grep '445/open' scan.gnmap | cut -d' ' -f2
```

## Vários alvos

```bash
nmap 192.168.0.10 192.168.0.20     # mais de um IP
nmap 192.168.0.1-50                # intervalo
nmap -iL alvos.txt                 # lista num arquivo, um por linha
nmap 192.168.0.0/24 --exclude 192.168.0.1   # tudo menos o roteador
```

## Recon automático em 2 etapas

Varrer as 65.535 portas com `-sV` em tudo é lento, porque a detecção de versão roda em
cada porta. O jeito rápido é separar:

1. varre todas as portas, só pra saber quais estão abertas;
2. roda versão e scripts **só nas abertas**.

O script [`scripts/recon.sh`](scripts/recon.sh) faz isso e salva tudo numa pasta:

```bash
git clone https://github.com/CHDevSec/nmap-comandos.git
cd nmap-comandos
./scripts/recon.sh scanme.nmap.org
```

Com `sudo` ele usa SYN scan (mais rápido); sem, connect scan. Velocidade e pasta de
saída dá pra mudar, veja `./scripts/recon.sh -h`.

Se preferir na mão:

```bash
nmap -p- -T4 -oA etapa1 alvo
portas=$(grep -oE '[0-9]+/open/' etapa1.gnmap | cut -d/ -f1 | paste -sd, -)
nmap -sC -sV -p "$portas" -oA etapa2 alvo
```

## Fluxo de pentest: interna x externa

O comando certo depende de onde você está. A ideia é sempre a mesma: descobrir o que
está vivo, achar as portas, confirmar versão e só então rodar script por serviço.

**Rede interna** (você está dentro, tipo numa VPN ou na rede do cliente): o alvo são
muitos hosts, então descobre primeiro quem existe.

```bash
sudo nmap -sn 192.168.0.0/24 -oG vivos.gnmap     # 1. quem está ligado (ARP é rápido e confiável na rede local)
grep 'Status: Up' vivos.gnmap | cut -d' ' -f2 > ips.txt   #    extrai os IPs vivos pra uma lista
sudo nmap -sS -p- -T4 --open -iL ips.txt -oA interna      # 2. todas as portas TCP dos que estão vivos
sudo nmap -sU --top-ports 20 --open -iL ips.txt -oA interna-udp   # 3. as UDP mais comuns (SNMP, DNS...)
nmap -sC -sV -p <portas abertas> -iL ips.txt -oA interna-det      # 4. versão + scripts padrão nas abertas
```

**Alvo externo** (um IP ou domínio na internet): é um host só, mas costuma ter firewall
e latência alta. Aqui o `-Pn` e o recon em 2 etapas fazem diferença.

```bash
nmap -Pn -p- -T4 --open -oA externo alvo          # 1. todas as portas (sem depender de ping)
nmap -Pn -sC -sV -p <portas abertas> -oA externo-det alvo   # 2. versão + scripts padrão nas abertas
# 3. a partir daí, scripts por serviço (seção acima) em cada porta que apareceu
```

Em alvo externo, respeite o escopo: só os IPs/domínios autorizados. Subdomínio ou IP
que você descobriu de brinde **não** está automaticamente no escopo.

## Deu problema?

| O que apareceu | O que fazer |
|---|---|
| `Note: Host seems down` | o alvo bloqueia ping: rode de novo com `-Pn` |
| `requires root privileges` | `-sS`, `-sU` e `-O` precisam de `sudo` |
| `-p-` não termina nunca | normal em alvo distante; use `-T4` ou o recon em 2 etapas |
| tudo `filtered` | tem firewall no caminho; teste portas específicas e use `--reason` |
| versão `?` ou `unknown` | tente `--version-all` |
| nada aberto, mas suspeito | faltou olhar UDP: `sudo nmap -sU --top-ports 20 alvo` |

## Cheatsheet

Uma folha com os comandos mais usados pra consulta rápida fica em
[docs/cheatsheet.md](docs/cheatsheet.md).

## Pra ir além

- [Manual oficial do nmap em português](https://nmap.org/man/pt_BR/)
- [Livro "Nmap Network Scanning"](https://nmap.org/book/), do criador do nmap
- [Documentação dos scripts NSE](https://nmap.org/nsedoc/)
- [Questões legais e o alvo de treino scanme](https://nmap.org/book/legal-issues.html)

---

Feito por [CHDEVSEC](https://chdevsec.com.br) · Instagram [@chdevsec](https://www.instagram.com/chdevsec/)

Achou útil? Deixa uma ⭐ e manda pra quem está começando. Licença [MIT](LICENSE).
