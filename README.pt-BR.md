# Servidor Dedicado de Project Zomboid no Ubuntu — Guia Completo

> **Guia passo a passo para instalar, configurar e rodar um servidor dedicado de Project Zomboid no Ubuntu 22.04 / 24.04 LTS com SteamCMD.** Cobre configuração de firewall, RAM, instalação de mods, recuperação e os erros mais comuns. Funciona em qualquer provedor de VPS (Hostinger, DigitalOcean, Hetzner, Vultr, AWS, Linode, etc.).

[![Stars](https://img.shields.io/github/stars/Bobagi/Project-Zomboid-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Project-Zomboid-Ubuntu-Server/stargazers)
[![Forks](https://img.shields.io/github/forks/Bobagi/Project-Zomboid-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Project-Zomboid-Ubuntu-Server/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

---

**[🇺🇸 English version](README.md)**

---

## Índice
1. [Por que este guia?](#por-que-este-guia)
2. [Pré-requisitos](#pré-requisitos)
3. [Instalação](#instalação)
4. [Configuração](#configuração)
5. [Rodando o Servidor](#rodando-o-servidor)
6. [Iniciar Automaticamente no Boot (systemd)](#iniciar-automaticamente-no-boot-systemd)
7. [Instalando Mods](#instalando-mods)
8. [Gerenciamento do Servidor](#gerenciamento-do-servidor)
9. [Solução de Problemas](#solução-de-problemas)
10. [Perguntas Frequentes (FAQ)](#perguntas-frequentes-faq)
11. [Créditos](#créditos)
12. [Licença](#licença)

---

## Por que este guia?

A maioria dos tutoriais para hospedar um servidor de Project Zomboid no Linux pula detalhes importantes como alocação de RAM, regras de firewall e gerenciamento de mods. Este guia foi feito com experiência real hospedando servidores e cobre tudo o que você precisa:

- ✅ Instalação completa do zero em uma VPS Ubuntu nova
- ✅ Configuração de firewall (UFW) para evitar problemas de conexão
- ✅ Setup do SteamCMD com login anônimo
- ✅ Ajuste de RAM via `ProjectZomboid64.json`
- ✅ Importar configurações do servidor criado localmente no Windows
- ✅ Rodar o servidor em background com `screen`
- ✅ Subir o servidor sozinho no boot com um serviço `systemd` testado
- ✅ Instalar mods via SCP ou SFTP (FileZilla)
- ✅ Erros comuns e como corrigir

---

## Pré-requisitos

Antes de começar, certifique-se de ter:

- Uma VPS ou máquina dedicada rodando **Ubuntu 22.04 ou 24.04 LTS (64-bit)**
- Pelo menos **4 GB de RAM** (8 GB recomendado para uso com mods)
- Privilégios `sudo` no servidor
- Conhecimento básico de terminal / comandos Linux
- **Project Zomboid** comprado na Steam (necessário para acessar mods — o servidor em si é gratuito)
- Um cliente SSH (ex: PuTTY no Windows, terminal nativo no macOS/Linux)

---

## Instalação

### 1. Atualizar o sistema e configurar o firewall

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

Ativar o UFW (firewall):
```bash
sudo ufw enable
```

> ⚠️ **Importante:** Se você está conectado via SSH, libere a porta SSH **antes** de ativar o firewall, senão você perderá o acesso:

```bash
sudo ufw allow 22        # SSH (porta padrão — altere se você usa outra porta)
```

Liberar as portas do servidor de Project Zomboid:
```bash
sudo ufw allow 16261/udp  # Porta principal do jogo (UDP)
sudo ufw allow 16262/udp  # Porta de conexão direta (UDP)
sudo ufw reload
```

Verificar se as regras estão ativas:
```bash
sudo ufw status
```

Você deve ver `16261` e `16262` listados como `ALLOW`.

---

### 2. Criar um usuário dedicado para o Steam

É uma boa prática rodar servidores de jogos com um usuário separado (não root):

```bash
sudo adduser steam
sudo usermod -aG sudo steam
sudo chown steam:steam /home/steam/ -R
sudo chmod -R 755 /home/steam/
```

---

### 3. Ativar suporte a 32-bit e instalar o SteamCMD

Ir para o diretório do usuário steam:
```bash
cd /home/steam
```

Ativar o repositório multiverse e suporte a 32-bit (necessário para o SteamCMD):
```bash
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install steamcmd -y
```

---

### 4. Baixar o Servidor Dedicado de Project Zomboid

Trocar para o usuário steam:
```bash
su - steam
cd ~
steamcmd
```

Dentro do SteamCMD, execute:
```
force_install_dir /home/steam/pzsteam
login anonymous
app_update 380870 validate
exit
```

> `380870` é o App ID do **Project Zomboid Dedicated Server** na Steam. É gratuito e pode ser baixado anonimamente, sem precisar ter o jogo.

---

## Configuração

### 1. Definir a quantidade de RAM

Navegar até o diretório do servidor:
```bash
cd /home/steam/pzsteam
```

Editar o arquivo de configuração da JVM:
```bash
nano ProjectZomboid64.json
```

Encontre o parâmetro `-Xmx` e defina a quantidade de RAM desejada:
- `-Xmx4g` → 4 GB de RAM
- `-Xmx8g` → 8 GB de RAM (recomendado para a maioria dos servidores)
- `-Xmx16g` → 16 GB de RAM (para modpacks grandes ou muitos jogadores)

![Exemplo de configuração de RAM](https://github.com/Bobagi/Zomboid-Ubuntu-Server/assets/45888141/e945f3f0-156c-448f-b62f-6e0332ba98f2)

---

### 2. Importar configurações do servidor local (opcional mas recomendado)

A forma mais fácil de configurar as opções do servidor (mapa, loot, dificuldade, sandbox) é:

1. Abra o Project Zomboid no seu **PC Windows local**
2. Crie e configure um servidor pelo menu **"Hospedar"** do jogo
3. Navegue até a pasta de configurações no Windows:
   ```
   C:\Users\<SeuUsuario>\Zomboid\Server\
   ```
4. Copie estes três arquivos:
   - `<nomeservidor>.ini`
   - `<nomeservidor>_SandboxVars.lua`
   - `<nomeservidor>_spawnregions.lua`

5. Faça upload deles para o servidor Linux em:
   ```
   /home/steam/Zomboid/Server/
   ```

   Usando SCP:
   ```bash
   scp C:\Users\<SeuUsuario>\Zomboid\Server\<nomeservidor>* steam@<ip-da-sua-vps>:/home/steam/Zomboid/Server/
   ```

   Ou use o [FileZilla](https://filezilla-project.org/) via SFTP (porta 22).

---

## Rodando o Servidor

### 1. Iniciar uma sessão screen persistente

O `screen` mantém o servidor rodando mesmo depois de você desconectar do SSH:

```bash
screen -S zomboid
```

### 2. Iniciar o servidor

```bash
cd /home/steam/pzsteam
./start-server.sh -servername <nomeservidor>
```

Substitua `<nomeservidor>` pelo nome do seu arquivo `.ini` (sem a extensão).

### 3. Sair do screen (deixar o servidor rodando em background)

Pressione `Ctrl + A`, depois `D`.

### 4. Reconectar para ver o console do servidor

```bash
screen -r zomboid
```

### 5. Parar o servidor de forma segura

Reconecte com `screen -r zomboid` e digite:
```
quit
```

Aguarde o save do mundo completar antes de fechar.

---

## Iniciar Automaticamente no Boot (systemd)

O método com `screen` acima exige que você entre por SSH e suba o servidor na mão. Se a
máquina reiniciar (queda de energia, atualização de kernel, `sudo reboot`), o servidor fica
no chão até alguém subir de novo.

Um serviço do `systemd` resolve isso: o servidor sobe no boot, reinicia se cair, e o
`systemctl stop` desliga **usando o mesmo comando `quit`** documentado acima, então o mundo
é sempre salvo. O console interativo continua funcionando igual, com `screen -r zomboid`.

### 1. Criar o arquivo do serviço

```bash
sudo nano /etc/systemd/system/zomboid.service
```

Cole o conteúdo abaixo, trocando `<nomedoseuservidor>` pelo nome do seu arquivo `.ini`
(sem a extensão):

```ini
[Unit]
Description=Project Zomboid Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=steam
Group=steam
WorkingDirectory=/home/steam/pzsteam
Environment=HOME=/home/steam

ExecStart=/usr/bin/screen -DmS zomboid /home/steam/pzsteam/start-server.sh -servername <nomedoseuservidor>
ExecStop=/bin/bash -c 'screen -S zomboid -p 0 -X stuff "quit\n" || exit 0; while kill -0 $MAINPID 2>/dev/null; do sleep 2; done'

Restart=always
RestartSec=15
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
```

Uma cópia deste arquivo está em [`misc/zomboid.service`](misc/zomboid.service).

Por que ele é escrito assim (cada item abaixo foi verificado em servidor real, não suposto):

- **`screen -DmS`** cria a sessão *sem fazer fork*, então o systemd acompanha o processo de
  verdade. O `screen -dmS` comum faz fork e o systemd perde o rastro.
- **O `ExecStop` digita `quit` no console**, exatamente o que o guia manda fazer na mão. Sem
  isso, o systemd mandaria sinal direto para a JVM.
- **E depois o `ExecStop` espera o servidor sair.** Essa segunda metade importa tanto quanto
  a primeira. Um `ExecStop` de uma linha só, que apenas injeta o `quit`, retorna na hora, o
  systemd conclui que a parada terminou e sinaliza o servidor *no meio do save*.
- **`Restart=always`, e não `on-failure`.** O `start-server.sh` termina com `exit 0` mesmo
  quando o jogo é morto, então o systemd sempre vê uma saída bem-sucedida e o `on-failure`
  nunca dispararia. Um `systemctl stop` manual não é considerado falha, então não reinicia
  o servidor.
- **`TimeoutStopSec=300`** limita a parada inteira, incluindo o save. Um mundo vazio salva em
  uns 10 segundos; um mundo grande com jogadores demora mais.

### 2. Garanta que não há outra cópia rodando

Não rode uma cópia no `screen` e outra no systemd no mesmo mundo. Se você subiu o servidor
na mão, volte para ele e digite `quit` antes:

```bash
screen -r zomboid
```

### 3. Habilitar e iniciar

```bash
sudo systemctl daemon-reload
sudo systemctl enable zomboid
sudo systemctl start zomboid
```

### 4. Conferir se funcionou

```bash
sudo systemctl status zomboid          # deve mostrar "active (running)"
sudo -u steam screen -r zomboid        # o console, igual a antes
```

O servidor leva um ou dois minutos carregando antes de aceitar jogadores. Espere aparecer
`*** SERVER STARTED ***` no console.

### Comandos do dia a dia

| Tarefa | Comando |
|---|---|
| Iniciar | `sudo systemctl start zomboid` |
| Parar (salva o mundo) | `sudo systemctl stop zomboid` |
| Reiniciar | `sudo systemctl restart zomboid` |
| Ver estado | `sudo systemctl status zomboid` |
| Abrir o console | `sudo -u steam screen -r zomboid` |
| Sair do console sem derrubar | `Ctrl + A`, depois `D` |
| Desligar o início automático | `sudo systemctl disable zomboid` |

> ⚠️ **Pare o servidor com `systemctl stop`, e não digitando `quit` no console.**
> Com `Restart=always`, o systemd entende um `quit` manual como saída inesperada e sobe o
> servidor de novo 15 segundos depois.

> **Onde ficam os logs?** O `journalctl -u zomboid` mostra só as mensagens do próprio
> systemd, porque o console do jogo vive dentro do `screen`. A saída real do servidor está
> em `/home/steam/Zomboid/server-console.txt` e em `/home/steam/Zomboid/Logs/`.

### Testando por conta própria

O repositório traz um teste automatizado que sobe o serviço, confere as portas, para o
serviço, verifica que o mundo foi salvo sem kill forçado, sobe de novo, confirma que o save
foi recarregado, e mata o processo para testar a recuperação de crash:

```bash
sudo ./misc/test-zomboid-service.sh
```

Rode **sem jogadores conectados**, porque ele sobe e desce o servidor várias vezes.

---

## Instalando Mods

### Método 1: Upload dos arquivos de mod via SCP / SFTP

1. Baixe os mods da [Steam Workshop](https://steamcommunity.com/app/108600/workshop/) no seu PC local
2. Localize a pasta dos mods no Windows:
   ```
   C:\Users\<SeuUsuario>\Zomboid\mods\
   ```
3. Envie a pasta do mod para a VPS:
   ```bash
   scp -r "C:\Users\<SeuUsuario>\Zomboid\mods\<NomeMod>" steam@<ip-da-sua-vps>:/home/steam/Zomboid/mods/
   ```
   Ou use o [FileZilla](https://filezilla-project.org/) via SFTP.

4. Adicione os IDs dos mods no arquivo `.ini` do servidor:
   ```ini
   Mods=<ModID>;<OutroModID>
   WorkshopItems=<WorkshopID>;<OutroWorkshopID>
   ```

> Os IDs do mod e da Workshop estão na URL da página do mod na Steam e no arquivo `mod.info` do mod.

### Método 2: Baixar mods via SteamCMD

Dentro do SteamCMD (logado como anônimo):
```
workshop_download_item 108600 <WorkshopID>
```

Os mods são baixados em `/home/steam/.steam/steamapps/workshop/content/108600/<WorkshopID>/`.  
Copie ou crie um link simbólico para `/home/steam/Zomboid/mods/`.

---

## Gerenciamento do Servidor

### Verificar se o servidor está rodando

```bash
screen -ls
```

### Atualizar o servidor para a versão mais recente

```bash
steamcmd
login anonymous
app_update 380870 validate
exit
```

Depois reinicie o servidor.

### Ver logs do servidor

```bash
ls -lt /home/steam/Zomboid/Logs/     # encontrar o log mais recente
cat /home/steam/Zomboid/Logs/<arquivo>.txt | tail -100
```

### Fazer backup do mundo do servidor

```bash
cp -r /home/steam/Zomboid/Saves/ /home/steam/Zomboid/Saves_backup_$(date +%Y%m%d)/
```

---

## Solução de Problemas

### ❌ "Falha na conexão" / Não consigo conectar ao servidor

- Verifique se as portas estão abertas: `sudo ufw status` — procure por `16261` e `16262`
- Confirme que o servidor está rodando: `screen -ls`
- Verifique o **firewall do painel do seu provedor de VPS** — muitos provedores têm um firewall separado do UFW que também precisa liberar UDP 16261–16262
- Confirme o IP do servidor: `curl ifconfig.me`

### ❌ O servidor cai na inicialização

- Verifique a RAM disponível: `free -h` — reduza o `-Xmx` em `ProjectZomboid64.json` se necessário
- Leia o log mais recente: `ls -lt /home/steam/Zomboid/Logs/` e faça `cat` no arquivo mais novo
- Valide os arquivos do servidor: rode `app_update 380870 validate` no SteamCMD

### ❌ Aviso "Failed to set thread priority"

É um aviso inofensivo em ambientes VPS Linux. O servidor roda normalmente.

### ❌ Mods não estão carregando

- Confirme que tanto `Mods=` quanto `WorkshopItems=` estão configurados corretamente no `.ini`
- Verifique se a pasta do mod existe em `/home/steam/Zomboid/mods/<ModID>/`
- Reinicie o servidor após qualquer mudança nos mods

### ❌ Erro do SteamCMD: `0x202` ou `0x212`

Timeout de rede da Steam. Aguarde alguns minutos e tente novamente. Se persistir:
```bash
rm -rf /home/steam/.steam/steamcmd/appcache
steamcmd +login anonymous +app_update 380870 +quit
```

### ❌ A porta 16261 está aberta no UFW mas jogadores ainda não conseguem conectar

Seu provedor de VPS provavelmente tem um firewall próprio no painel (Hostinger hPanel, DigitalOcean Firewall, AWS Security Groups). Acesse o painel do seu provedor e adicione as regras UDP para as portas 16261 e 16262 lá também.

---

## Perguntas Frequentes (FAQ)

**P: Preciso ter o Project Zomboid para rodar o servidor?**  
R: Não. O servidor dedicado (App ID 380870) é gratuito e pode ser baixado anonimamente via SteamCMD. Apenas os jogadores que vão se conectar precisam ter o jogo.

**P: Quantos jogadores o servidor suporta?**  
R: Oficialmente até 32 jogadores. Com 8 GB de RAM e uma CPU moderna, 8–16 jogadores simultâneos funciona muito bem.

**P: Qual versão do Ubuntu usar?**  
R: **Ubuntu 22.04 LTS** ou **24.04 LTS**. Evite versões não-LTS para servidores em produção.

**P: Posso rodar em Raspberry Pi ou ARM?**  
R: Não. O servidor dedicado do Project Zomboid é apenas para arquitetura x86-64.

**P: Dá para rodar sem o `screen`, usando systemd?**  
R: Sim. Veja [Iniciar Automaticamente no Boot (systemd)](#iniciar-automaticamente-no-boot-systemd) para um arquivo de serviço pronto. Ele roda o servidor *dentro* do `screen`, então o console continua acessível e o `systemctl stop` ainda salva o mundo com o comando `quit` documentado.

**P: Como definir a senha de administrador do servidor?**  
R: O servidor pede para você definir na primeira inicialização. Para redefinir depois, edite o arquivo `<nomeservidor>.ini` e atualize o campo `AdminPassword=`.

**P: Qual provedor de VPS é recomendado?**  
R: **Hetzner** (Europa/EUA) e **Vultr** oferecem ótimo custo-benefício. **Hostinger** é mais econômico. **DigitalOcean** tem excelente documentação. Escolha o datacenter mais próximo dos seus jogadores para menor ping.

**P: O servidor inicia mas ninguém consegue entrar — o que verificar primeiro?**  
R: Em ordem: (1) Firewall no painel do seu provedor de VPS, (2) regras UFW com `sudo ufw status`, (3) IP correto do servidor, (4) console do servidor para erros via `screen -r zomboid`.

---

## Créditos

- [Project Zomboid Wiki — Dedicated Server](https://pzwiki.net/wiki/Dedicated_Server) — documentação oficial
- [Valve SteamCMD Documentation](https://developer.valvesoftware.com/wiki/SteamCMD) — referência do SteamCMD
- [r/projectzomboid](https://www.reddit.com/r/projectzomboid/) — dicas da comunidade
- Todos que abriram issues e contribuíram com melhorias neste repositório ❤️

---

## 💖 Apoie este projeto

Se este guia te ajudou, considere dar uma ⭐ no repositório — isso ajuda outras pessoas a encontrá-lo!

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)
[![Donate with PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)

---

## Contato e Contribuições

Encontrou um erro no guia ou tem uma dica para adicionar?  
👉 **[Abra uma issue](https://github.com/Bobagi/Project-Zomboid-Ubuntu-Server/issues/new)** — todo feedback é bem-vindo.

Pull requests também são bem-vindos!

---

## Licença

Este projeto é open-source sob a [Licença MIT](LICENSE).
