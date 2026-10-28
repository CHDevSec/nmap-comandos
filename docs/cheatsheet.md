# Cheatsheet de nmap

Folha de consulta rápida. A explicação de cada comando está no
[README](../README.md). **Só rode em alvo autorizado.** `⚠️` = intrusivo.

## Começar

```bash
nmap alvo                         # as 1.000 portas TCP mais comuns
nmap -p- -sV -T4 alvo             # todas as portas TCP, com versão
sudo nmap -A alvo                 # OS + versão + scripts padrão + traceroute
```

## Descoberta

```bash
sudo nmap -sn 192.168.0.0/24      # quem está vivo na rede (ARP com sudo)
nmap -sL 192.168.0.0/24           # só lista os IPs, sem mandar pacote
nmap -Pn alvo                     # escaneia sem depender de ping
```

## Portas

```bash
nmap -p 22,80,443 alvo            # só essas
nmap -p- alvo                     # todas (1-65535)
nmap -F alvo                      # as 100 mais comuns
nmap --top-ports 2000 alvo        # as N mais comuns
nmap --open alvo                  # só as abertas
```

## Tipo de scan

```bash
sudo nmap -sS alvo                # SYN (padrão com sudo)
nmap -sT alvo                     # connect (padrão sem sudo)
sudo nmap -sU --top-ports 20 alvo # UDP, as mais comuns
```

## Versão e scripts

```bash
nmap -sV alvo                     # programa e versão
nmap -sC -sV alvo                 # versão + scripts padrão
nmap --script "vuln and safe" alvo   # vulnerabilidade sem os scripts perigosos
nmap --script-help NOME           # o que um script faz
```

## Scripts por serviço (os primeiros)

```bash
nmap -sV --script http-title,http-headers,http-methods -p 80,443 alvo   # HTTP
nmap --script ssl-cert,ssl-enum-ciphers -p 443 alvo                     # TLS  (⚠️ enum-ciphers)
nmap --script smb-protocols,smb-os-discovery -p 445 alvo                # SMB
nmap --script ssh2-enum-algos,ssh-hostkey -p 22 alvo                    # SSH
nmap --script ftp-anon,ftp-syst -p 21 alvo                             # FTP
sudo nmap -sU --script snmp-info -p 161 alvo                            # SNMP
```

## Salvar e reaproveitar

```bash
nmap -oA scan alvo                # salva nos 3 formatos (.nmap .xml .gnmap)
xsltproc scan.xml -o scan.html    # XML vira relatório HTML
nmap --resume scan.gnmap          # continua scan interrompido
grep '445/open' scan.gnmap | cut -d' ' -f2   # IPs com a 445 aberta
```

## Firewall / "parece desligado"

```bash
nmap -Pn alvo                     # não tenta ping antes
nmap --reason alvo                # por que cada porta ficou nesse estado
sudo nmap -sA -p 80,443 alvo      # ACK scan: mapeia firewall com estado
```

## Recon em 2 etapas

```bash
./scripts/recon.sh alvo           # varre tudo e detalha só as portas abertas
sudo ./scripts/recon.sh -u -r 1000 alvo   # + top UDP, SYN scan, min-rate 1000
```
