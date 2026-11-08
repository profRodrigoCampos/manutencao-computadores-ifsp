# Manutenção de Computadores IFSP

Script em PowerShell para instalar, configurar e manter os computadores dos campi do Instituto Federal de São Paulo (IFSP): laboratórios, salas de aula, biblioteca, setores administrativos e a própria CTI.

- **Versão:** 4.1 (revisão 07/11/2026)
- **Autoria:** Prof. Rodrigo Campos (IFSP)
- **Licença:** MIT (código aberto). Use, adapte e sugira melhorias.

Feito para a **Coordenadoria de Tecnologia da Informação (CTI)** de cada campus. Nasceu para o campus Rio Claro (RCL), é testado em Bauru (BRU) e serve para os 57 campi (a lista oficial de siglas está no script).

## Como usar

1. Copie a pasta `ManutencaoIFSP` para um pendrive (estrutura abaixo) e ponha os instaladores em `softwares`.
2. No PC, entre na conta **CTI** (administradora).
3. Clique com o botão direito em `INICIO.bat` e escolha **Executar como administrador**.
4. Escolha no menu inicial:

| Opção | O que faz |
|---|---|
| 1 - Instalar / configurar (verde) | Perguntas (campus, lugar, tipo de PC, nome...), programas e toda a configuração |
| 2 - Manutenção (amarelo) | Situação, diagnóstico, contas, sessões, horários, limpezas, bloqueios, aparência, rede, rotinas... |
| 3 - Veyon (magenta) | Instalar e configurar o Veyon; carregar e conferir a lista de computadores (com o pendrive) |
| 4 - GLPI (azul) | Agente de inventário: instalar, servidor, etiqueta, enviar o inventário. Serve em qualquer PC |

Cada área tem a sua cor, para ficar claro em que menu se está. As telas foram pensadas para a janela padrão do PowerShell (sem maximizar).

O script pode ser rodado mais de uma vez sem problema. No PC, tudo fica em `C:\ProgramData\IFSP` (respostas em `config.json`, scripts, logs).

## Pendrive

```
ManutencaoIFSP\
  INICIO.bat
  manutencao.ps1
  arquivos\
    start2.bin              (opcional) fixados do Menu Iniciar dos labs
    xampp\                  (opcional) cópia de C:\xampp recém-instalado, da MESMA versão do instalador
    wallpapers\             <SIGLA>-claro.png e <SIGLA>-escuro.png (ou IFSP-claro/escuro.png)
    campus\<SIGLA>.txt      criado pelo script: página inicial, Moodle, GLPI, domínio, favoritos
    veyon\<SIGLA>\<SEÇÃO>\  criado pelo script: lista de PCs (computadores.csv) e, nos labs, a chave pública do lab
    veyon\<SIGLA>\CAMPUS\   criado pelo PC central: chave pública do campus
  softwares\
    basicos\                vc_redist.x64.exe (instalado PRIMEIRO), 7-Zip, ONLYOFFICE, Chrome .msi, VLC, GLPI-Agent .msi
    laboratorio\            Packet Tracer, GIMP, VirtualBox, VS Code, XAMPP
    veyon\                  veyon-...-setup.exe
    vscode-extensoes\       (opcional) arquivos .vsix
    parametros.txt          (opcional) "arquivo = parâmetros silenciosos"
```

O pendrive só é usado no começo da instalação: o script copia o que precisa e avisa **"PODE TIRAR O PENDRIVE"**.

Os arquivos criados pelo script (`arquivos\campus`, `arquivos\veyon`) têm dados do campus e **não vão para o GitHub** (veja o `.gitignore`).

## Tipos de PC

| Espaço | Tipo | Conta de uso | Senha |
|---|---|---|---|
| Lab de informática: PC do professor (00) | LAB-PROF | Professor | só a CTI define |
| Lab de informática: PCs de alunos | LAB-ALUNO | Alunos | só a CTI |
| Sala de aula, sala dos professores, lab de ciências | USO-PROF | Professor | só a CTI |
| Biblioteca de alunos, "Outro" de alunos | USO-ALUNO | Alunos | só a CTI |
| Setores administrativos, biblioteca de servidores, auditório | OUTRO | `SIGLA-NN` (ex.: CRA-01), `AUD` | a própria pessoa |
| CTI | CTI | só a conta CTI | sempre com senha |

- **PCs compartilhados** (labs, salas, biblioteca de alunos): navegador sem anônimo, limpeza das pastas da conta ao sair e ao desligar (Pasta Segura opcional), barra fixa, pop-up de regras, Veyon, desligamento às 23:30 com aviso e botão Adiar.
- **Administrativos:** nada é apagado, navegador normal, sem Veyon, não desligam sozinhos.
- **Todos:** Chrome e Edge abrem maximizados, no site do campus.
- **Domínio (UCS ou AD):** opcional; a conta local de uso vira reserva e cada pessoa entra com o próprio login.

## Manutenção (menu 2)

Uma tela só, em duas colunas, por tema:

| Tema | Opções |
|---|---|
| Diagnóstico | 1 Situação · 2 Diagnóstico (por que reiniciou, versões dos programas, disco e saúde, tarefas do script) · 3 Logs |
| Contas, sessões e horários | 4 Contas locais (desbloquear, logon automático) · 5 Senha da conta de uso · 6 Pasta Segura · 7 Sessões abertas (ver e encerrar) · 8 Horários (23:30) |
| Limpezas e bloqueios | 9 Limpezas · 10 Bloqueios |
| Aparência e avisos | 11 Papel de parede e tema · 12 Pop-up de logon · 13 Favoritos |
| Rede e Windows | 14 Rede (IP, MAC, Wake-on-LAN, testes) · 15 Domínio · 16 Rotinas do Windows (disco, DISM/SFC, chkdsk, relógio, gpupdate, Windows Update) |
| Este PC | 17 Trocar o nome · 18 Mudar de lugar ou de tipo · 19 Reaplicar |

O inventário dos PCs (hardware, número de série, programas) fica com o GLPI (menu 4).

Tudo o que a Manutenção faz vai para o log (`C:\ProgramData\IFSP\logs`), com o comando usado.

## Veyon (menu 3)

- **PC central** (um PC da CTI): Veyon Master com a chave do campus; vê todos os PCs de professores e alunos, inclusive os PCs de professor dos labs.
- **PC do professor do lab:** Veyon Master com a chave do lab; vê só os alunos do seu lab.
- **Outros PCs de professores e alunos:** só o serviço; aceitam a chave do campus (e os alunos do lab, também a do lab).
- **Ordem:** o central primeiro; depois cada PC; por fim, o central (e o professor de cada lab) carrega as listas.

**Regra:** o PC que tem o Veyon Master nunca controla a si mesmo. Ao bloquear, reiniciar ou desligar todos, ele fica de fora:

- o próprio PC fica escondido no Veyon Master ("Hide local computer");
- o PC central não entra em nenhuma lista;
- na carga da lista, um nome que aponta para o próprio PC (registro velho no DNS) é pulado, com aviso;
- o IP anotado na instalação não é usado (com DHCP, ele pode passar a ser do próprio PC do professor). Para campi com IP fixo, veja `$VeyonUsarIpAnotado`;
- **Conferir a lista** (menu 3) mostra os PCs que respondem e avisa se algum nome aponta para o próprio PC;
- nos PCs com Veyon Master, o Windows deixa de guardar "nome não existe" (`MaxNegativeCacheTtl = 0`), para um PC religado aparecer logo.

O Wake-on-LAN só funciona pela placa com cabo (no Wi-Fi não).

## GLPI (menu 4)

Funciona em qualquer PC, mesmo sem ter passado pelo script:

- **PC já configurado pelo script** que precisa refazer o agente (servidor, etiqueta, reinstalar);
- **PC em uso** que não vai ser reconfigurado nem formatado: só instalar, configurar e rodar o agente. O script pede só a sigla do campus.

Opções: situação (agente, serviço, servidor, etiqueta, se o servidor responde), informar o servidor e instalar, enviar o inventário, trocar a etiqueta, abrir o GLPI no navegador, desinstalar o agente.

O servidor informado fica no pendrive (`arquivos\campus\<SIGLA>.txt`) e é sugerido nos próximos PCs do campus.

## Para adaptar ao seu campus

Tudo o que muda de um campus para outro fica na seção **CONFIGURAÇÃO**, no começo do `manutencao.ps1`, com comentários. Exemplos:

- `$BlocosCampi`: blocos (prédios) do campus, para nomes como `RCL-B104-05`;
- `$LocaisAdm`: setores administrativos;
- `$SecoesVeyon`: nomes das seções no Veyon Master;
- `$VeyonUsarIpAnotado`: usar o IP anotado quando o nome não é encontrado (só com IP fixo);
- `$RegrasLab`, `$RegrasBiblioteca`, `$AvisoProfessor`: textos do pop-up de logon;
- `$TiposComDesligamento`, `$HorariosPadrao`: desligamento automático;
- `$ServidoresHora`, `$FusoHorario`: relógio;
- `$ProgramasDestaque`: programas mostrados primeiro no diagnóstico.

## Requisitos e cuidados

- Windows 10/11 Pro, PowerShell 5.1 (o do Windows).
- `manutencao.ps1` em UTF-8 **com BOM** e quebras de linha **CRLF** (o `.gitattributes` mantém o CRLF); `INICIO.bat` em ASCII/CRLF.
- Instale o Visual C++ (`vc_redist.x64.exe`) antes do XAMPP: sem ele, o instalador do XAMPP reinicia o PC sozinho. O script já faz isso.
- Teste numa máquina virtual antes de usar nos laboratórios.

## Licença

MIT. Veja o arquivo `LICENSE`.
