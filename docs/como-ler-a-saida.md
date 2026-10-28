# Como ler a saída do nmap

Um scan real contra `scanme.nmap.org` (o alvo de treino do próprio projeto Nmap), feito
em outubro de 2026:

```text
$ nmap -sV scanme.nmap.org
Nmap scan report for scanme.nmap.org (45.33.32.156)
Host is up (0.20s latency).
Not shown: 991 closed tcp ports (conn-refused)
PORT     STATE    SERVICE     VERSION
19/tcp   filtered chargen
22/tcp   open     ssh         OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 (Ubuntu Linux; protocol 2.0)
25/tcp   filtered smtp
80/tcp   open     http        Apache httpd 2.4.7 ((Ubuntu))
111/tcp  filtered rpcbind
139/tcp  filtered netbios-ssn
179/tcp  filtered bgp
1900/tcp filtered upnp
9929/tcp open     nping-echo  Nping echo
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

Linha por linha:

- **`Host is up (0.20s latency)`**: o alvo respondeu, e cada ida e volta leva 0,2 s.
- **`Not shown: 991 closed...`**: o nmap esconde as portas fechadas pra não poluir.
  Das 1.000 que ele olhou, 991 estavam fechadas; sobraram 3 abertas e 6 filtradas.
- **`PORT`**: número da porta e protocolo (`tcp` ou `udp`).
- **`STATE`**: o estado da porta (tabela abaixo).
- **`SERVICE`**: o serviço. **Sem `-sV`, é só um chute pelo número da porta**
  (porta 80 = "http"). Com `-sV`, o nmap conversa com o serviço e confirma.
- **`VERSION`**: programa e versão, só aparece com `-sV`. É isso que você pesquisa
  atrás de CVE. Porta `filtered` fica sem versão: o nmap não conseguiu conversar.
- **`Service Info`**: o que o nmap deduziu do sistema pelas respostas dos serviços.

## Estados de porta

| Estado | O que quer dizer |
|---|---|
| `open` | tem um programa aceitando conexão ali. É o que interessa. |
| `closed` | a porta respondeu, mas não tem nada rodando. O host está vivo. |
| `filtered` | nenhuma resposta: um firewall está descartando os pacotes. O nmap não sabe se está aberta. |
| `unfiltered` | responde, mas o nmap não sabe se está aberta ou fechada (só no `-sA`). |
| `open\|filtered` | sem resposta, pode ser aberta ou filtrada. Comum em UDP. |
| `closed\|filtered` | não deu pra decidir entre fechada e filtrada (só no `-sI`). |

Rode com `--reason` pra ver o motivo de cada estado (por exemplo `syn-ack` = aberta,
`conn-refused` = fechada, `no-response` = filtrada).

## E agora?

Achou porta aberta com versão? O próximo passo é pesquisar aquela versão:

```bash
searchsploit apache 2.4.7      # no Kali, busca exploits públicos conhecidos
```

ou procurar a versão no [NVD](https://nvd.nist.gov/vuln/search) e no
[CVE Details](https://www.cvedetails.com/). Versão antiga não é vulnerabilidade
confirmada: muita distro corrige a falha sem mudar o número da versão (o "2ubuntu2.13"
ali em cima é justamente o pacote corrigido do Ubuntu). Confirme antes de reportar.
