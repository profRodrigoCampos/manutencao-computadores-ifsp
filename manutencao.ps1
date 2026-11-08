<#
  manutencao.ps1 - Manutenção de Computadores IFSP
  Versão 4.1  (1 - Instalar  |  2 - Manutenção  |  3 - Veyon  |  4 - GLPI)

  Instituto Federal de São Paulo (IFSP)
  Autoria: Prof. Rodrigo Campos - IFSP Rio Claro
  Código aberto, licença MIT (veja o arquivo LICENSE). Use, adapte e sugira melhorias.

  Serve para todos os campi do IFSP, em PC recém-formatado ou já em uso.
  Tipos de computador (a conta CTI, administradora, existe em todos):
    LAB-ALUNO  laboratório de informática, PC de aluno ............ conta Alunos
    LAB-PROF   laboratório de informática, PC do professor (00) ... conta Professor
    USO-PROF   uso de professores: sala de aula, CIE, sala dos professores
               (regras do Professor do lab; programas: só os básicos ou os do lab, pergunta) . conta Professor
    USO-ALUNO  uso de alunos: ex.: biblioteca para alunos
               (regras da conta Alunos do lab; programas: só os básicos ou os do lab, pergunta) . conta Alunos
    OUTRO      administrativo: setores, biblioteca para servidores, auditório ... conta do local, ex.: CRA-01, AUD
    CTI        PCs do setor CTI: só a conta CTI (com senha); um deles pode ser o PC central do Veyon
  O que cada tipo recebe está explicado no README.md e na seção CONFIGURAÇÃO, abaixo.

  Pendrive (pasta ManutencaoIFSP; a pasta com o nome antigo, InstaladorIFSP, também é reconhecida):
    ManutencaoIFSP\INICIO.bat          (botão direito > Executar como administrador)
    ManutencaoIFSP\manutencao.ps1      (este script)
    ManutencaoIFSP\arquivos\start2.bin (fixados do Menu Iniciar dos labs, opcional)
    ManutencaoIFSP\arquivos\wallpapers\<SIGLA>-claro.png / <SIGLA>-escuro.png
                                       (se não houver do campus, usa IFSP-claro/escuro.png)
    ManutencaoIFSP\softwares\basicos\       (todos os PCs; ponha aqui o vc_redist.x64.exe, o Visual C++: é instalado
                                            antes de tudo, senão o instalador do XAMPP reinicia o PC no meio)
    ManutencaoIFSP\softwares\laboratorio\   (só labs de informática)
    ManutencaoIFSP\softwares\parametros.txt (opcional: "arquivo = parâmetros silenciosos")
    ManutencaoIFSP\softwares\veyon\         (veyon-...-setup.exe)
    ManutencaoIFSP\softwares\vscode-extensoes\ (opcional: .vsix)
    ManutencaoIFSP\arquivos\xampp\     (opcional: cópia da pasta C:\xampp de um XAMPP recém-instalado, da mesma
                                       versão do instalador; dela saem a htdocs e os bancos (mysql\data) padrão)
  Criados pelo script no pendrive:
    ManutencaoIFSP\arquivos\campus\<SIGLA>.txt   (página inicial, Moodle, GLPI e favoritos do campus: sugeridos nos próximos PCs)
    ManutencaoIFSP\arquivos\veyon\<SIGLA>\<SEÇÃO>\ (lista de PCs de cada seção do Veyon; nos labs, também a chave
                                       pública do lab). Seções: um lab cada (B104 ou INF1), SALAS, CBI, CIE, PROF, OUTROS
    ManutencaoIFSP\arquivos\veyon\<SIGLA>\CAMPUS\  (chave pública do PC central do Veyon)

  Como usar: conecte o pendrive e rode o INICIO.bat dele. Na instalação, o script copia a pasta
  para a Área de Trabalho da CTI, faz no começo o que precisa do pendrive e avisa "pode tirar o
  pendrive"; o resto roda da cópia. No fim, os instaladores são apagados da cópia (o pendrive não muda).

  No PC, tudo fica em C:\ProgramData\IFSP (config.json, scripts e logs).
  Pode ser rodado mais de uma vez sem problema.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # sem barras de progresso por cima do texto

# ======================== CONFIGURAÇÃO ========================
$Versao        = '4.1'
$Revisao       = '07/11/2026 22:45'   # muda a cada ajuste; aparece no cabeçalho e no log
$Base          = 'C:\ProgramData\IFSP'
$PastaLogs     = Join-Path $Base 'logs'
$LogArquivo    = Join-Path $PastaLogs 'instalador.log'
$ArqConfig     = Join-Path $Base 'config.json'
$ContaAdmin    = 'CTI'
$ContaAluno    = 'Alunos'
$ContaProf     = 'Professor'
$PastaSegura   = 'Pasta Segura'     # pasta na Área de Trabalho que a limpeza não apaga (opcional)
$PastaPapel    = Join-Path $Base 'Papel de parede'   # a CTI põe aqui a imagem nova; a mais nova vale para todos
# Ícone da Pasta Segura (arquivo,índice). Padrão: o cadeado do próprio Windows.
$IconePastaSegura = '%SystemRoot%\System32\shell32.dll,47'
$SID_Admins    = 'S-1-5-32-544'  # grupo Administradores (independe do idioma)
$SID_Usuarios  = 'S-1-5-32-545'  # grupo Usuários
$Pen           = $PSScriptRoot
$UrlSuap       = 'https://suap.ifsp.edu.br/'
# Moodle nos favoritos (labs e laboratório de ciências): só dos campi com endereço conhecido.
# Para incluir o seu campus, acrescente uma linha:  SIGLA = 'endereço do Moodle'
$MoodleCampi   = @{
    BRU = 'https://moodle.bru.ifsp.edu.br/login/index.php'
    RCL = 'https://moodle.rcl.ifsp.edu.br/login/index.php'
}
# Favoritos do Chrome e do Edge: uma pasta na barra ($PastaFavoritos), que o usuário não apaga nem edita.
# Dentro dela, a subpasta IFSP tem o SUAP e, nos PCs de professores e alunos, o Moodle do campus.
# Os outros favoritos são pedidos na instalação, numa linha só, separados por ;  no formato
#     Pasta/Nome = endereço          (sem "Pasta/", o favorito fica solto na pasta principal)
# A lista escolhida fica no pendrive (arquivos\campus\<SIGLA>.txt) e é sugerida nos próximos PCs do campus:
# uma lista para os PCs de professores e alunos (FavoritosEnsino) e outra para os administrativos (FavoritosAdm).
# Mudar depois, sem reinstalar: Manutenção > Favoritos.
$PastaFavoritos = 'Favoritos'
# Sugestão para os PCs de professores e alunos quando o campus ainda não tem a sua lista no pendrive:
$FavoritosEnsinoPadrao = @(
    'Programação Web/W3Schools = https://www.w3schools.com/'
    'Programação Web/MDN Web Docs = https://developer.mozilla.org/pt-BR/'
    'Programação Web/XAMPP = https://www.apachefriends.org/pt_br/index.html'
    'Programação Web/VS Code = https://code.visualstudio.com/'
    'Acadêmico/Biblioteca Pearson = https://plataforma.bvirtual.com.br/'
    'Acadêmico/Google Acadêmico = https://scholar.google.com.br/'
    'Acadêmico/Portal de Periódicos CAPES = https://www.periodicos.capes.gov.br/'
    'Acadêmico/SciELO = https://www.scielo.org/'
    'Redes/Cisco NetAcad = https://www.netacad.com/'
    'Redes/Sub-redes (VLSM) = https://subnettingpractice.com/vlsm.html'
) -join '; '
# Sugestão para os PCs administrativos (setores, biblioteca de servidores, auditório, CTI): começa vazia;
# o que a CTI digitar no primeiro PC administrativo vira a sugestão dos próximos.
$FavoritosAdmPadrao = ''
# PCs compartilhados: restrições gravadas no registro de cada conta (política de usuário), em todas as contas
# MENOS a CTI. Formato de cada linha: 'caminho no registro da conta|nome|valor' (valor numérico, DWORD).
# A tarefa do sistema reaplica a cada logon e a cada 5 min (a mesma lista está no sistema.ps1, mais abaixo).
$RestricoesUsuario = @(
    'Software\Policies\Google\Chrome|IncognitoModeAvailability|2'      # Chrome sempre anônimo
    'Software\Policies\Google\Chrome|BrowserSignin|0'                  # sem login de conta Google
    'Software\Policies\Google\Chrome|SyncDisabled|1'
    'Software\Policies\Google\Chrome|BrowserGuestModeEnabled|0'
    'Software\Policies\Google\Chrome|BrowserAddPersonEnabled|0'
    'Software\Policies\Google\Chrome|PasswordManagerEnabled|0'
    'Software\Policies\Microsoft\Edge|InPrivateModeAvailability|2'     # Edge sempre InPrivate
    'Software\Policies\Microsoft\Edge|BrowserSignin|0'
    'Software\Policies\Microsoft\Edge|SyncDisabled|1'
    'Software\Policies\Microsoft\Edge|BrowserGuestModeEnabled|0'
    'Software\Policies\Microsoft\Edge|BrowserAddProfileEnabled|0'
    'Software\Policies\Microsoft\Edge|PasswordManagerEnabled|0'
    'Software\Microsoft\Windows\CurrentVersion\Policies\System|DisableChangePassword|1'   # sem "Alterar uma senha" no Ctrl+Alt+Del
)

# Campi do IFSP: SIGLA|Nome|site (fonte: https://www.ifsp.edu.br/unidades)
$ListaCampi = @(
    'ARQ|Araraquara|https://arq.ifsp.edu.br/'
    'AVR|Avaré|https://avr.ifsp.edu.br/'
    'BRT|Barretos|https://brt.ifsp.edu.br/'
    'BRU|Bauru|https://bru.ifsp.edu.br/'
    'BRI|Birigui|https://bri.ifsp.edu.br/'
    'BTV|Boituva|https://btv.ifsp.edu.br/'
    'BRA|Bragança Paulista|https://bra.ifsp.edu.br/'
    'CMP|Campinas|https://portal.cmp.ifsp.edu.br/'
    'CJO|Campos do Jordão|https://www.ifspcjo.edu.br/portal'
    'CPV|Capivari|https://cpv.ifsp.edu.br/'
    'CAR|Caraguatatuba|https://www.ifspcaraguatatuba.edu.br/'
    'CRP|Carapicuíba|https://crp.ifsp.edu.br/'
    'CTD|Catanduva|https://ctd.ifsp.edu.br/'
    'CIT|Cidade Tiradentes|https://cit.ifsp.edu.br/'
    'COT|Cotia|https://cot.ifsp.edu.br/'
    'CBT|Cubatão|https://cbt.ifsp.edu.br/'
    'DID|Diadema|https://did.ifsp.edu.br/'
    'FRO|Franco da Rocha|https://fro.ifsp.edu.br/'
    'GJA|Guarujá|https://gja.ifsp.edu.br/'
    'GRU|Guarulhos|https://gru.ifsp.edu.br/'
    'HTO|Hortolândia|https://hto.ifsp.edu.br/'
    'IST|Ilha Solteira|https://ist.ifsp.edu.br/'
    'ITP|Itapetininga|https://itp.ifsp.edu.br/'
    'ITQ|Itaquaquecetuba|https://itq.ifsp.edu.br/'
    'JCR|Jacareí|https://jcr.ifsp.edu.br/'
    'JCN|Jaçanã|https://jcn.ifsp.edu.br/'
    'JAN|Jardim Ângela|https://jan.ifsp.edu.br/'
    'JND|Jundiaí|https://jnd.ifsp.edu.br/'
    'MTO|Matão|https://mto.ifsp.edu.br/'
    'MAU|Mauá|https://mau.ifsp.edu.br/'
    'MRC|Miracatu|https://mrc.ifsp.edu.br/'
    'OSA|Osasco|https://osa.ifsp.edu.br/'
    'PRC|Piracicaba|https://prc.ifsp.edu.br/'
    'PTB|Pirituba|https://ptb.ifsp.edu.br/'
    'PEP|Presidente Epitácio|https://pep.ifsp.edu.br/'
    'PRU|Presidente Prudente|https://pru.ifsp.edu.br/'
    'RGT|Registro|https://rgt.ifsp.edu.br/'
    'RPR|Ribeirão Preto|https://rpr.ifsp.edu.br/'
    'RCL|Rio Claro|https://rcl.ifsp.edu.br/'
    'SLT|Salto|https://slt.ifsp.edu.br/'
    'SAN|Santos|https://san.ifsp.edu.br/'
    'SBC|São Bernardo do Campo|https://sbc.ifsp.edu.br/'
    'SCL|São Carlos|https://scl.ifsp.edu.br/'
    'SBV|São João da Boa Vista|https://sbv.ifsp.edu.br/'
    'SJP|São José do Rio Preto|https://sjp.ifsp.edu.br/'
    'SJC|São José dos Campos|https://sjc.ifsp.edu.br/'
    'SMP|São Miguel Paulista|https://smp.ifsp.edu.br/'
    'SPO|São Paulo|https://spo.ifsp.edu.br/'
    'SRQ|São Roque|https://srq.ifsp.edu.br/'
    'SVC|São Vicente|https://svc.ifsp.edu.br/'
    'SER|Serrana|https://ser.ifsp.edu.br/'
    'SRT|Sertãozinho|https://srt.ifsp.edu.br/'
    'SOR|Sorocaba|https://sor.ifsp.edu.br/'
    'SMR|Sumaré|https://smr.ifsp.edu.br/'
    'SZN|Suzano|https://szn.ifsp.edu.br/'
    'TUP|Tupã|https://tup.ifsp.edu.br/'
    'VTP|Votuporanga|https://vtp.ifsp.edu.br/'
)

# ---- Locais (menu da instalação) ----
# Blocos (prédios) de cada campus. Campus que está aqui: a instalação pergunta o bloco e monta o código da
# sala com o bloco e o número (B104), e os nomes saem pela sala: RCL-B104-05 (lab), RCL-B103 (sala de aula).
# Campus que não está aqui: labs numerados (INF1 -> RCL-INF1-05) e salas numeradas (SALA12 -> RCL-SALA12),
# ou o código da sala digitado na hora (B104).
$BlocosCampi = @{
    RCL = @('A', 'B', 'C')
}
# Ensino ('código|texto do menu'). O código é o tipo de espaço, que define as regras do PC:
#   LAB   lab de informática (inclui o de hardware): pede o lab e o PC (P = professor). Conta Professor (PC 00)
#         ou Alunos; seção própria no Veyon (Lab B104 / Lab Info 1), com o Veyon Master no PC do professor.
#   SALA  sala de aula: 1 PC por sala, conta Professor (RCL-B103 / RCL-SALA12).
#   PROF  sala dos professores: vários PCs, conta Professor, NÃO desliga sozinho (RCL-PROF-01).
#   CIE   laboratório de ciências / química: 1 PC, conta Professor (RCL-CIE).
#   AUD   auditório: 1 PC, regras de administrativo, sem Veyon, nunca desliga sozinho, conta AUD (RCL-AUD).
#   CBI   biblioteca: pergunta se o PC é de alunos (conta Alunos) ou de servidores (administrativo) (RCL-CBI-01).
#   SALA, PROF, CIE e CBI de alunos perguntam os programas: só os básicos ou os mesmos dos labs.
$LocaisEnsino = @(
    'LAB|Laboratório de informática (inclui o de hardware)'
    'SALA|Sala de aula'
    'PROF|Sala dos professores'
    'CIE|Laboratório de ciências / química'
    'AUD|Auditório'
    'CBI|Biblioteca (alunos ou servidores)'
)
# Administrativo ('SIGLA|nome'): navegador normal, nada é apagado, sem Veyon, não desliga sozinho;
# nome pela sigla: RCL-CRA-01, usuário CRA-01 (a pessoa pode criar a própria senha).
# CTI: só a conta CTI (com senha); um dos PCs pode ser o PC central do Veyon.
# Para acrescentar um setor do seu campus, copie uma linha (sigla de 2 a 6 letras).
$LocaisAdm = @(
    'CAE|Coordenadoria de Apoio ao Ensino'
    'CAP|Coordenadoria de Almoxarifado e Patrimônio'
    'CCF|Coordenadoria de Contabilidade e Finanças'
    'CGP|Coordenadoria de Gestão de Pessoas'
    'CLT|Coordenadoria de Licitações e Contratos'
    'CRA|Coordenadoria de Registros Acadêmicos'
    'CSP|Coordenadoria Sociopedagógica'
    'CTI|Coordenadoria de Tecnologia da Informação (só a conta CTI; pode ser o PC central do Veyon)'
    'DAA|Diretoria Adjunta Administrativa'
    'DAE|Diretoria Adjunta Educacional'
    'DRG|Direção-Geral (e a Coordenadoria de Apoio à Direção, CDI: DRG-02, DRG-03)'
)
# Espaços de professores e alunos que NÃO desligam sozinhos às 23:30 (os administrativos nunca desligam)
$EspacosSemDesligamento = @('PROF')
# Seções (locais) do Veyon Master. Só os PCs de professores e alunos têm Veyon; os de servidores
# (administrativo, biblioteca de servidores, "Outro" de servidores) e os da CTI (menos o PC central) não têm.
#   Labs de informática: uma seção por lab, cada uma com o seu PC de professor (Veyon Master) e a sua chave:
#   pelo código da sala (B104 -> "Lab B104", $SecaoLabSalaVeyon) ou pelo número (INF1 -> "Lab Info 1", $SecaoLabVeyon).
#   Salas de aula: todas juntas na seção SALAS.  Biblioteca de alunos (CBI), CIE e sala dos professores: uma cada.
#   "Outro" (ex.: sala de reuniões) de professores ou de alunos: todos juntos na seção OUTROS.
#   O Veyon não tem seção dentro de seção; ele mostra as seções em ordem alfabética (os "Lab ..." ficam juntos).
# O código (à esquerda) é o nome da pasta no pendrive (arquivos\veyon\<SIGLA>\<código>); o texto (à direita)
# é o nome que aparece no Veyon Master e pode ser mudado à vontade (vale na próxima vez que os PCs forem carregados).
$SecaoLabVeyon     = 'Lab Info {0}'     # labs numerados (INF1)
$SecaoLabSalaVeyon = 'Lab {0}'          # labs pelo código da sala (B104)
$SecoesVeyon = [ordered]@{
    SALAS  = 'Salas de aula'
    CBI    = 'Biblioteca'
    BIBL   = 'Biblioteca'                # nome antigo da pasta (até a v3.10)
    CIE    = 'Laboratório de Ciências'
    PROF   = 'Sala dos professores'
    OUTROS = 'Outros'
}
# Veyon: se o nome de um PC da lista não for encontrado na rede na hora de carregar, usar o IP anotado na
# instalação? $false (padrão) = carrega só pelo nome, e o Veyon procura o PC de novo quando ele ligar.
# Só ponha $true se os PCs do campus tiverem IP fixo ou reserva no DHCP: com DHCP comum, o IP anotado pode
# passar a ser de outro PC, inclusive do próprio PC do professor (ele se veria na lista e, ao bloquear
# todos, se bloquearia). Com $true, um IP que seja deste PC nunca é usado.
$VeyonUsarIpAnotado = $false
# Pop-up de logon: aparece a cada logon em todos os PCs que apagam arquivos (professores e alunos; nunca
# na CTI). Dá para ver, ligar ou desligar na Manutenção > Pop-up de logon. Uma linha por item; cabem até 8
# (contando a linha da Pasta Segura e o último aviso, $AvisoFinalAlunos).
# Alunos: título "Regras de uso dos laboratórios – IFSP Campus <nome>" (labs) ou "Regras de uso dos
# computadores – ..." (outros), botões Aceito / Não aceito (não aceitar = sai da conta).
# Professores: título "Antes de começar – IFSP Campus <nome>", botão Entendi.
# Labs de informática (PC de aluno):
$RegrasLab = @(
    'Não é permitido comer ou beber no laboratório.'
    'Não retire cabos de rede, mouses ou teclados das máquinas.'
    'Se notar falta ou dano em algum periférico, avise imediatamente o professor.'
    'Ao sair, deixe teclado, mouse e cadeira no lugar.'
    'Ao sair, salve seus arquivos (na nuvem ou no pendrive): este computador é limpo a cada uso.'
)
# Biblioteca (PCs de alunos):
$RegrasBiblioteca = @(
    'Não é permitido comer ou beber perto dos computadores.'
    'Mantenha o silêncio: use fones de ouvido para áudio e vídeo.'
    'Quando houver pessoas esperando, respeite o tempo de uso combinado.'
    'Não retire cabos, mouses ou teclados das máquinas.'
    'Se notar falta ou dano em algum equipamento, avise um servidor.'
    'Ao sair, salve seus arquivos (na nuvem ou no pendrive): este computador é limpo a cada uso.'
)
# Outros locais com PCs de alunos ("Outro" de alunos, ex.: QUI):
$RegrasOutrosLocais = @(
    'Não é permitido comer ou beber perto dos computadores.'
    'Não retire cabos, mouses ou teclados das máquinas.'
    'Se notar falta ou dano em algum equipamento, avise o professor ou um servidor.'
    'Ao sair, deixe teclado, mouse e cadeira no lugar.'
    'Ao sair, salve seus arquivos (na nuvem ou no pendrive): este computador é limpo a cada uso.'
)
# PCs de professores (PC do professor no lab, salas de aula, CIE, sala dos professores, "Outro" de professores):
$AvisoProfessor = @(
    'Ao sair ou desligar, a Área de Trabalho, Documentos, Downloads, Imagens, Vídeos e Músicas desta conta são apagados.'
    'Salve seus trabalhos na nuvem ou no pendrive antes de sair.'
)
# Último aviso em todos os pop-ups de alunos (labs, biblioteca, outros locais); '' = sem este aviso:
$AvisoFinalAlunos = 'Ao final da aula, favor desligar os PCs.'
# Linha a mais quando o PC tem a Pasta Segura (Manutenção > Pasta Segura):
$AvisoPastaSeguraProf  = 'O que estiver na Pasta Segura (na Área de Trabalho) não é apagado.'
$AvisoPastaSeguraAluno = 'A Pasta Segura (na Área de Trabalho) não é apagada, mas todas as turmas a veem: não guarde nada pessoal nela.'

# Apps da Microsoft a remover de todas as contas (e de perfis novos) - todos os tipos de PC
$AppsRemover = @(
    'Microsoft.BingWeather'                   # Clima
    'Microsoft.WindowsFeedbackHub'            # Hub de Comentários
    'Microsoft.MicrosoftOfficeHub'            # Microsoft 365 Copilot
    'Microsoft.Copilot'                       # Copilot
    'Clipchamp.Clipchamp'                     # Clipchamp
    'Microsoft.BingNews'                      # Notícias
    'MSTeams'                                 # Teams (novo)
    'MicrosoftTeams'                          # Teams (antigo)
    'Microsoft.Todos'                         # To Do
    'Microsoft.MicrosoftStickyNotes'          # Notas Autoadesivas
    'Microsoft.OutlookForWindows'             # Outlook (novo)
    'microsoft.windowscommunicationsapps'     # Email e Calendário (antigo)
    'Microsoft.PowerAutomateDesktop'          # Power Automate
    'Microsoft.MicrosoftSolitaireCollection'  # Solitaire & Casual Games
    'Microsoft.GamingApp'                     # Xbox
    'Microsoft.XboxApp'                       # Xbox (antigo)
    'Microsoft.XboxGamingOverlay'             # Xbox Game Bar
    'Microsoft.XboxIdentityProvider'          # Xbox Live
    'Microsoft.XboxSpeechToTextOverlay'       # Xbox
    'Microsoft.Xbox.TCUI'                     # Xbox Live
    'MicrosoftCorporationII.QuickAssist'      # Assistência Rápida
    'MicrosoftWindows.Client.WebExperience'   # Widgets (painel de clima/notícias)
    '7EE7776C.LinkedInforWindows'             # LinkedIn
)
# Parâmetros silenciosos dos instaladores .exe conhecidos (o 1º padrão que combinar com o nome vale)
# Os demais .exe Inno Setup/NSIS são detectados sozinhos; outros: softwares\parametros.txt
$ParamsConhecidos = [ordered]@{
    # Os .msi (ex.: VLC, Chrome Enterprise, agente GLPI) não precisam estar aqui: vão com /qn ALLUSERS=1.
    'vc_redist*'       = '/install /quiet /norestart'   # Visual C++ (instalado antes dos outros programas)
    '*chrome*'         = '/silent /install'
    '7z*'              = '/S'
    '*desktopeditors*' = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /ALLUSERS'   # ONLYOFFICE
    '*onlyoffice*'     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /ALLUSERS'
    '*packettracer*'   = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
    'gimp*'            = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /ALLUSERS'
    'vscodesetup*'     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath'
    'virtualbox*'      = '--silent --msiparams REBOOT=ReallySuppress VBOX_START=0'
    'xampp*'           = '--mode unattended --unattendedmodeui none --prefix C:\xampp'   # 8.5.x não aceita --launchapps
}
# Programas do laboratório que abrem portas de rede: o script cria regras de entrada no firewall
# (só para a rede local), para o Windows não pedir a senha de administrador quando o aluno os abrir.
$ProgramasFirewall = @(
    @{ Nome = 'XAMPP Apache';        Caminho = 'C:\xampp\apache\bin\httpd.exe' }
    @{ Nome = 'XAMPP MySQL';         Caminho = 'C:\xampp\mysql\bin\mysqld.exe' }
    @{ Nome = 'XAMPP FileZilla';     Caminho = 'C:\xampp\FileZillaFTP\filezillaserver.exe' }
    @{ Nome = 'XAMPP Mercury';       Caminho = 'C:\xampp\MercuryMail\mercury.exe' }
    @{ Nome = 'Cisco Packet Tracer'; Caminho = 'C:\Program Files\Cisco Packet Tracer*\bin\PacketTracer.exe' }
    @{ Nome = 'VS Code';             Caminho = 'C:\Program Files\Microsoft VS Code\Code.exe' }
    @{ Nome = 'VirtualBox';          Caminho = 'C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe' }
)
# Desligamento automático às 23:30 (valores normais), com aviso e botão "Adiar". Com a CTI logada,
# o PC nunca desliga sozinho. Na Manutenção dá para pausar ou testar.
# (desde a v3.3 não há desligamento nem logoff por falta de uso, em nenhum PC)
# Tipos de PC que desligam (tire ou acrescente tipos: LAB-ALUNO, LAB-PROF, USO-PROF, USO-ALUNO, OUTRO):
$TiposComDesligamento = @('LAB-ALUNO', 'LAB-PROF', 'USO-PROF', 'USO-ALUNO')
$HorariosPadrao = [ordered]@{
    Ativo             = $true      # o script ajusta conforme $TiposComDesligamento
    Desligar          = '23:30'    # desligamento forçado
    FimJanela         = '06:00'    # até este horário, um PC ligado também é desligado (com aviso)
    AvisoMin          = 10         # aviso antes de desligar
    AdiarMin          = 60         # botão "Adiar 1 hora" (qualquer pessoa pode)
    PausadoAte        = ''
    Teste             = $false
    TesteAte          = ''
}

# VS Code (labs): extensões numa pasta comum, só leitura para os alunos (instaladas pela internet).
# Também instala os arquivos .vsix que estiverem em softwares\vscode-extensoes no pendrive.
$ExtensoesVSCode = @('ritwickdey.LiveServer', 'ms-python.python')
# Tema do VS Code nas contas de professores e alunos dos labs: volta a este a cada logon (junto com a limpeza
# do VS Code); dá para trocar durante a aula. A CTI não é mexida. '' = tema padrão do VS Code.
# Exemplos: 'Visual Studio Dark' (aparece como "Dark (Visual Studio)"), 'Default Dark Modern', 'Default Light Modern'.
$TemaVSCode = 'Visual Studio Dark'

# Manutenção > Rotinas do Windows > Acertar o relógio: servidores de hora (fora do domínio; no domínio, a hora
# vem do servidor do domínio). Separados por espaço. Padrão: NTP.br.
$ServidoresHora = 'a.ntp.br b.ntp.br c.ntp.br'
# Fuso horário esperado nos PCs (o "Acertar o relógio" oferece corrigir). '' = não conferir.
$FusoHorario    = 'E. South America Standard Time'     # Brasília
# Manutenção > Diagnóstico > Versões: programas mostrados primeiro (parte do nome, como aparece no Windows)
$ProgramasDestaque = @('Visual C++', 'Google Chrome', 'ONLYOFFICE', '7-Zip', 'VLC', 'GLPI', 'Veyon',
                       'Packet Tracer', 'GIMP', 'VirtualBox', 'Visual Studio Code', 'XAMPP')
# ==============================================================

$UsuarioAtual     = [Environment]::UserName
$PrecisaReiniciar = $false
$pcaMexido        = $false
$auMexido         = $false                 # Windows Update sem reinício automático durante a instalação
$SwInstalar       = $null                  # de onde instalar (pendrive ou cópia); $null = $Pen\softwares
$Prog             = @{ Instalar = $true; Pular = @(); Copiar = $true }   # escolha dos programas (antes da cópia)
$XamppNovo        = $false                 # o XAMPP acabou de ser instalado do zero
$XamppVoltarPadrao = $false                # o XAMPP já existia (mesma versão): htdocs e bancos voltam ao padrão
$GlpiMudou        = $false                 # agente GLPI instalado ou com servidor trocado nesta execução
$script:Reaplicar = $false
$script:NumEtapa  = 0
$TotalEtapas      = 12

# ---------------------------------------------------------------
#  Funções de tela e de log
# ---------------------------------------------------------------
function Log {
    param([string]$Msg, [string]$Cor = 'Gray')
    Write-Host "   $Msg" -ForegroundColor $Cor
    if (Test-Path $PastaLogs) {
        $linha = '{0:yyyy-MM-dd HH:mm:ss} [{1}] {2}' -f (Get-Date), $UsuarioAtual, $Msg
        Add-Content -Path $LogArquivo -Value $linha -Encoding UTF8
    }
}

# Cor de cada área (título das telas e faixa do menu): instalação verde, manutenção amarelo, Veyon magenta, GLPI azul
$CoresArea = @{ Instalacao = 'Green'; Manutencao = 'Yellow'; Veyon = 'Magenta'; Glpi = 'Blue' }
$script:CorArea = 'Cyan'

# Faixa com moldura (título de uma área)
function Faixa([string]$Texto, [string]$Cor) {
    $l = [string]([char]0x2550) * ($Texto.Length + 6)
    Write-Host ('  ' + [char]0x2554 + $l + [char]0x2557) -ForegroundColor $Cor
    Write-Host ('  ' + [char]0x2551 + '   ' + $Texto + '   ' + [char]0x2551) -ForegroundColor $Cor
    Write-Host ('  ' + [char]0x255A + $l + [char]0x255D) -ForegroundColor $Cor
}

# Cabeçalho. Sem -Area: o completo (menu inicial e instalação). Com -Area: uma linha + a faixa da área,
# para sobrar espaço na janela padrão do PowerShell.
function Mostrar-Cabecalho([string]$Area = '', [string]$Cor = 'Green') {
    Clear-Host
    if ($Area) {
        $script:CorArea = $Cor
        Write-Host ("  Manutenção de Computadores IFSP v{0} | revisão {1} | usuário {2} | PC {3}" -f $Versao, $Revisao, $UsuarioAtual, $env:COMPUTERNAME) -ForegroundColor DarkGray
        Faixa $Area $Cor
        return
    }
    $script:CorArea = 'Cyan'
    Write-Host ''
    Faixa "Manutenção de Computadores IFSP v$Versao" 'Green'
    Write-Host ("  Revisão: {0}" -f $Revisao) -ForegroundColor DarkGray
    Write-Host '  Autoria: IFSP - Prof. Rodrigo Campos | Licença MIT (código aberto)' -ForegroundColor DarkGray
    Write-Host ("  Usuário atual: {0}    Computador atual: {1}" -f $UsuarioAtual, $env:COMPUTERNAME) -ForegroundColor DarkGray
    Write-Host ''
}

function Titulo([string]$Texto) {
    Write-Host ''
    Write-Host "  $Texto" -ForegroundColor $script:CorArea
    Write-Host ('  ' + ([string]([char]0x2500) * 62)) -ForegroundColor DarkGray
}

# Grava só no arquivo de log (o que é comprido demais para a tela, como a linha de comando de um instalador)
function Log-SoArquivo([string]$Msg) {
    if (Test-Path $PastaLogs) {
        $linha = '{0:yyyy-MM-dd HH:mm:ss} [{1}] {2}' -f (Get-Date), $UsuarioAtual, $Msg
        Add-Content -Path $LogArquivo -Value $linha -Encoding UTF8
    }
}

# Corta um texto para caber numa coluna
function Cortar([string]$Texto, [int]$Max) {
    if ($Texto.Length -le $Max) { return $Texto }
    return $Texto.Substring(0, $Max - 1) + '.'
}
# "1 PC" / "3 PCs"
function Qtd([int]$N, [string]$Um, [string]$Varios) { if ($N -eq 1) { "1 $Um" } else { "$N $Varios" } }

function Etapa([string]$Texto) {
    $script:NumEtapa++
    Write-Host ''
    Write-Host (' [{0,2}/{1}] {2}' -f $script:NumEtapa, $TotalEtapas, $Texto) -ForegroundColor Cyan
    Write-Host ('  ' + ([string]([char]0x2500) * 62)) -ForegroundColor DarkGray
    if (Test-Path $PastaLogs) {
        Add-Content -Path $LogArquivo -Encoding UTF8 -Value ('{0:yyyy-MM-dd HH:mm:ss} [{1}] === {2}' -f (Get-Date), $UsuarioAtual, $Texto)
    }
}

# Pergunta com respiro: uma linha em branco antes e "> " antes do texto (a resposta fica bem visível)
function Perguntar([string]$Texto) {
    Write-Host ''
    return (Read-Host "  > $Texto")
}

# Confirmação em que o normal é seguir: ENTER confirma, N volta para alterar
function Confirmar-Enter([string]$Pergunta) {
    do { $r = (Perguntar "$Pergunta  (ENTER = confirmar, N = alterar)").Trim().ToUpper() } until ($r -in '', 'S', 'N')
    return ($r -ne 'N')
}

# S/N digitado: usado no que apaga, reinicia ou muda algo importante
function Perguntar-SN([string]$Pergunta) {
    do { $r = (Perguntar "$Pergunta (S/N)").Trim().ToUpper() } until ($r -eq 'S' -or $r -eq 'N')
    return ($r -eq 'S')
}

# S/N com resposta sugerida: ENTER aceita a sugestão
function Perguntar-SN-Padrao([string]$Pergunta, [bool]$Padrao) {
    $p = if ($Padrao) { 'S' } else { 'N' }
    do { $r = (Perguntar "$Pergunta (S/N, ENTER = $p)").Trim().ToUpper() } until ($r -in '', 'S', 'N')
    if ($r -eq '') { return $Padrao }
    return ($r -eq 'S')
}

# Número com "0 = voltar": devolve $null se a pessoa digitar 0
function Ler-NumeroOuVoltar([string]$Pergunta, [int]$Min, [int]$Max) {
    $n = Ler-Numero "$Pergunta (0 = voltar)" 0 $Max
    while ($n -ne 0 -and $n -lt $Min) {
        Write-Host "  Digite um número de $Min a $Max (0 = voltar)." -ForegroundColor Yellow
        $n = Ler-Numero "$Pergunta (0 = voltar)" 0 $Max
    }
    if ($n -eq 0) { return $null }
    return $n
}

function Ler-Numero([string]$Pergunta, [int]$Min, [int]$Max) {
    while ($true) {
        $r = (Perguntar "$Pergunta").Trim()
        if (($r -match '^\d{1,3}$') -and ([int]$r -ge $Min) -and ([int]$r -le $Max)) { return [int]$r }
        Write-Host "  Digite um número de $Min a $Max." -ForegroundColor Yellow
    }
}

function Nome-PC-Valido([string]$n) {
    return ($n -match '^[A-Za-z0-9][A-Za-z0-9-]{0,13}[A-Za-z0-9]$') -and ($n -notmatch '^\d+$')
}

function Nome-Usuario-Valido([string]$n, [string]$NomePC) {
    if ($n -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,19}$') { return $false }
    if ($n -eq $NomePC -or $n -eq $ContaAdmin) { return $false }
    if ($n -match '^(Administrador|Administrator|Convidado|Guest|DefaultAccount|WDAGUtilityAccount)$') { return $false }
    return $true
}

function Ler-SenhaNova([string]$Conta) {
    while ($true) {
        Write-Host ''
        $s1 = Read-Host "  > Digite a senha da conta $Conta" -AsSecureString
        $s2 = Read-Host '  > Digite a mesma senha de novo' -AsSecureString
        $b1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1)
        $b2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2)
        try {
            $p1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b1)
            $p2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b2)
        } finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b1)
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b2)
        }
        if ($p1.Length -eq 0)  { Write-Host '  A senha não pode ficar em branco.' -ForegroundColor Yellow; continue }
        if ($p1 -cne $p2)      { Write-Host '  As senhas não conferem. Tente de novo.' -ForegroundColor Yellow; continue }
        return $s1
    }
}

# ---------------------------------------------------------------
#  Funções de contas, registro e perfis
# ---------------------------------------------------------------
# A conta vai como objeto (SID), não pelo nome: se o PC tiver o mesmo nome da conta (ex.: PC "CTI"),
# o Windows confundia "CTI" com o próprio PC ("O membro CTI\CTI não foi encontrado").
function Membro-Local([string]$Conta) {
    $u = Get-LocalUser -Name $Conta -ErrorAction SilentlyContinue
    if ($u) { return $u }
    return $Conta
}
function Adicionar-AoGrupo([string]$SID, [string]$Conta) {
    try { Add-LocalGroupMember -SID $SID -Member (Membro-Local $Conta) -ErrorAction Stop }
    catch { if ($_.FullyQualifiedErrorId -notlike 'MemberExists*') { throw } }
}

function Remover-DoGrupo([string]$SID, [string]$Conta) {
    try { Remove-LocalGroupMember -SID $SID -Member (Membro-Local $Conta) -ErrorAction Stop }
    catch { if ($_.FullyQualifiedErrorId -notlike 'MemberNotFound*') { throw } }
}

function Perfil-DaConta($Usuario) {
    if (-not $Usuario) { return $null }
    return Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $Usuario.SID.Value }
}

# Grava um valor no registro; se o Windows recusar, só registra AVISO e segue.
function Definir-Reg([string]$Chave, [string]$Nome, $Valor, [string]$Tipo = 'DWord') {
    try {
        if (-not (Test-Path $Chave)) { New-Item -Path $Chave -Force | Out-Null }
        New-ItemProperty -Path $Chave -Name $Nome -Value $Valor -PropertyType $Tipo -Force | Out-Null
    } catch {
        Log "AVISO: o Windows não deixou gravar $Nome em $Chave ($($_.Exception.Message))" 'Yellow'
    }
}

function Apagar-Reg([string]$Chave, [string[]]$Nomes) {
    if (Test-Path $Chave) { Remove-ItemProperty -Path $Chave -Name $Nomes -ErrorAction SilentlyContinue }
}

# Executa $Acao no registro (HKCU) do perfil padrão (Default) e da conta de uso do PC
# (Alunos, Professor ou a do setor), mesmo que não estejam logados. $Acao recebe o caminho do hive.
function Para-CadaPerfil([scriptblock]$Acao) {
    $alvos = @(@{ Nome = 'Default'; Dat = 'C:\Users\Default\NTUSER.DAT'; SID = $null })
    $u = $null
    if ($Cfg.Usuario -and $Cfg.Usuario -ne $ContaAdmin) { $u = Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue }   # PC do setor CTI: não há conta de uso
    $perf = Perfil-DaConta $u
    if ($perf) { $alvos += @{ Nome = $Cfg.Usuario; Dat = (Join-Path $perf.LocalPath 'NTUSER.DAT'); SID = $u.SID.Value } }
    foreach ($a in $alvos) {
        if ($a.SID -and (Test-Path "Registry::HKEY_USERS\$($a.SID)")) {   # perfil já está carregado
            & $Acao "Registry::HKEY_USERS\$($a.SID)"
            continue
        }
        if (-not (Test-Path $a.Dat)) { continue }
        & reg.exe load 'HKU\IFSPTmp' $a.Dat | Out-Null
        if ($LASTEXITCODE -ne 0) { Log "AVISO: não consegui abrir o registro do perfil $($a.Nome)." 'Yellow'; continue }
        try     { & $Acao 'Registry::HKEY_USERS\IFSPTmp' }
        finally {
            [gc]::Collect(); [gc]::WaitForPendingFinalizers(); Start-Sleep -Seconds 1
            & reg.exe unload 'HKU\IFSPTmp' | Out-Null
        }
    }
}

function Salvar-Config {
    $Cfg | ConvertTo-Json | Set-Content -Path $ArqConfig -Encoding UTF8
}

# ---------------------------------------------------------------
#  Perguntas
# ---------------------------------------------------------------
# Lê um endereço web: ENTER = $Sugestao; '0' = vazio (se $PermiteVazio); completa o https:// se faltar
# Endereço nas perguntas da instalação: ENTER = sugestão; N = nenhum (se $PermiteVazio); 0 = voltar ($null)
function Ler-EnderecoPergunta([string]$Texto, [string]$Sugestao, [bool]$PermiteVazio) {
    while ($true) {
        $r = (Perguntar $Texto).Trim()
        if ($r -eq '0') { return $null }
        if ($r -eq '') { return $Sugestao }
        if ($PermiteVazio -and $r -in 'N', 'n') { return '' }
        if ($r -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') { $r = "https://$r" }
        if ($r -match '^https?://[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(:\d+)?(/\S*)?$') { return $r }
        Write-Host '  Endereço inválido. Ex.: www.exemplo.com.br ou https://www.exemplo.com.br/pagina' -ForegroundColor Yellow
    }
}

function Ler-Endereco([string]$Texto, [string]$Sugestao, [bool]$PermiteVazio) {
    while ($true) {
        $r = (Perguntar $Texto).Trim()
        if ($r -eq '') { return $Sugestao }
        if ($PermiteVazio -and $r -eq '0') { return '' }
        if ($r -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') { $r = "https://$r" }
        if ($r -match '^https?://[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(:\d+)?(/\S*)?$') { return $r }
        Write-Host '  Endereço inválido. Ex.: www.exemplo.com.br ou https://www.exemplo.com.br/pagina' -ForegroundColor Yellow
    }
}

# Dados do campus (página inicial, Moodle, GLPI e favoritos): ficam no pendrive, em arquivos\campus\<SIGLA>.txt,
# e são sugeridos nas próximas instalações do mesmo campus. Dá para editar o arquivo à mão.
function Ler-DadosCampus([string]$Sigla) {
    $d = @{}
    $raizes = @()
    $pd = Pasta-Pendrive
    if ($pd) { $raizes += $pd }
    if ($Pen -ne $pd) { $raizes += $Pen }
    foreach ($r in $raizes) {
        $arq = Join-Path $r "arquivos\campus\$Sigla.txt"
        if (-not (Test-Path $arq)) { continue }
        foreach ($l in (Get-Content $arq -Encoding UTF8)) {
            if ($l -match '^\s*([A-Za-z]+)\s*=\s*(.*)$') { $d[$Matches[1]] = $Matches[2].Trim() }
        }
        break
    }
    return $d
}
function Gravar-DadosCampus {
    # favoritos: a lista deste PC vai para o seu perfil; a do outro perfil continua a que estava no arquivo
    $dcAnt = Ler-DadosCampus $Cfg.Sigla
    $favE = if ($dcAnt.ContainsKey('FavoritosEnsino')) { [string]$dcAnt['FavoritosEnsino'] } else { $FavoritosEnsinoPadrao }
    $favA = if ($dcAnt.ContainsKey('FavoritosAdm'))    { [string]$dcAnt['FavoritosAdm'] }    else { $FavoritosAdmPadrao }
    if ($Cfg.PSObject.Properties.Name -contains 'Favoritos') {
        if ((Perfil-Favoritos $Cfg) -eq 'Ensino') { $favE = [string]$Cfg.Favoritos } else { $favA = [string]$Cfg.Favoritos }
    }
    $domTxt = if ($Cfg.PSObject.Properties.Name -contains 'Dominio') { [string]$Cfg.Dominio } else { [string]$dcAnt['Dominio'] }
    $domDns = if ($Cfg.PSObject.Properties.Name -contains 'DominioDns') { [string]$Cfg.DominioDns } else { [string]$dcAnt['DominioDns'] }
    $linhas = @(
        "# Dados do campus $($Cfg.Sigla) - $($Cfg.Campus), gravados pelo manutencao.ps1 em $(Get-Date -Format 'dd/MM/yyyy HH:mm')."
        '# Sugeridos nas próximas instalações deste campus. Pode editar à mão (deixe vazio o que não houver).'
        '# Favoritos: Pasta/Nome = endereço; Pasta/Nome = endereço  (Ensino = PCs de professores e alunos; Adm = administrativos)'
        "PaginaInicial = $($Cfg.PaginaInicial)"
        "Moodle = $($Cfg.Moodle)"
        "Glpi = $($Cfg.Glpi)"
        "Dominio = $domTxt"
        "DominioDns = $domDns"
        "FavoritosEnsino = $favE"
        "FavoritosAdm = $favA"
    )
    $onde = @()
    $pd = Pasta-Pendrive
    foreach ($r in @($pd, $Pen) | Where-Object { $_ } | Select-Object -Unique) {
        try {
            $pasta = Join-Path $r 'arquivos\campus'
            New-Item -ItemType Directory -Path $pasta -Force | Out-Null
            [IO.File]::WriteAllLines((Join-Path $pasta "$($Cfg.Sigla).txt"), [string[]]$linhas, (New-Object System.Text.UTF8Encoding($true)))
            $onde += $pasta
        } catch { }
    }
    if ($onde.Count -gt 0) { Log "Dados do campus (página inicial, Moodle, GLPI, favoritos) guardados em: $($onde -join '; ')." }
}

# ---------------------------------------------------------------
#  Pendrive: usado só no começo da instalação
# ---------------------------------------------------------------
# Tela do começo: explica para que serve o pendrive e espera ele ser conectado (ou segue sem ele)
function Tela-Pendrive {
    Mostrar-Cabecalho
    Titulo 'Pendrive'
    Write-Host '  O pendrive (pasta ManutencaoIFSP) guarda o que vai de um PC para outro:'
    Write-Host '   - dados do campus (página inicial, Moodle, GLPI), sugeridos nos próximos PCs ... arquivos\campus\<SIGLA>.txt'
    Write-Host '   - Veyon: chaves e lista de PCs de cada local ...................................... arquivos\veyon\'
    Write-Host '  Ele só é usado no começo: depois das perguntas, o script copia a pasta para a Área de Trabalho'
    Write-Host '  da CTI, faz o que precisa do pendrive e avisa "PODE TIRAR O PENDRIVE".' -ForegroundColor DarkGray
    while ($true) {
        $pd = Pasta-Pendrive
        if ($pd) {
            Write-Host ''
            Write-Host "  Pendrive encontrado: $pd" -ForegroundColor Green
            $r = (Perguntar 'Aperte ENTER para continuar (0 = voltar ao menu inicial)').Trim()
            if ($r -eq '0') { return 'VOLTAR' }
            return $pd
        }
        Write-Host ''
        Write-Host '  Pendrive com a pasta ManutencaoIFSP não encontrado.' -ForegroundColor Yellow
        $r = (Perguntar 'Conecte o pendrive e aperte ENTER (N = seguir sem ele, 0 = voltar ao menu inicial)').Trim().ToUpper()
        if ($r -eq '0') { return 'VOLTAR' }
        if ($r -eq 'N') {
            Write-Host '  Sem o pendrive, os dados do campus e o Veyon ficam só neste PC.' -ForegroundColor Yellow
            Write-Host '  Depois, para o Veyon, rode o menu 3 (Veyon) com o pendrive.' -ForegroundColor Yellow
            return $null
        }
    }
}

# Copia a pasta do pendrive para a Área de Trabalho da CTI (só a CTI e os administradores abrem a pasta).
# Só quando o script roda do pendrive e a conta é a CTI. Depois disso, o resto da instalação roda da cópia.
# Fora da cópia: arquivos\veyon\ (chaves) e fichas\ (de versões antigas). A pasta softwares (quase todo o tamanho) é copiada com a
# janela de cópia do Windows (tempo restante, velocidade); o resto, que é pequeno, em silêncio.
# Os instaladores seguem a escolha feita antes da cópia ($Prog): com "Copiar", vão só os programas escolhidos
# (e o agente do GLPI, se o campus tiver), mais o Veyon (PCs com Veyon) e, nos labs, vscode-extensoes.
# Sem "Copiar", a instalação lê os instaladores direto do pendrive ($SwInstalar). Os arquivos soltos de
# softwares (ex.: parametros.txt) vão sempre. arquivos\xampp (pasta grande) não vai: dela só saem a htdocs e
# os bancos padrão (Copiar-XamppDoPendrive).
function Copiar-ParaAreaDeTrabalho {
    $pd = Pasta-Pendrive
    if (-not $pd -or $Pen -ne $pd -or $UsuarioAtual -ne $ContaAdmin) { return }
    $destino = Join-Path ([Environment]::GetFolderPath('Desktop')) 'ManutencaoIFSP'
    Write-Host "   Copiando a pasta do pendrive para $destino ..."
    & robocopy.exe $Pen $destino /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP /XD (Join-Path $Pen 'fichas') (Join-Path $Pen 'arquivos\veyon') (Join-Path $Pen 'arquivos\xampp') (Join-Path $Pen 'softwares') | Out-Null
    if ($LASTEXITCODE -ge 8) { Log "AVISO: a cópia para $destino falhou (robocopy $LASTEXITCODE); a instalação continua do pendrive." 'Yellow'; return }
    $swOrigem  = Join-Path $Pen 'softwares'
    $swDestino = Join-Path $destino 'softwares'
    $comInst   = [bool]($Prog.Instalar -and $Prog.Copiar)
    if (-not $Prog.Instalar) { Write-Host '   Instaladores não copiados: os programas não serão instalados.' -ForegroundColor DarkGray }
    elseif (-not $Prog.Copiar) { Write-Host '   Instaladores não copiados: os programas serão instalados direto do pendrive.' -ForegroundColor DarkGray }
    if (Test-Path $swOrigem) {
        $subs = @()
        if (Usa-Veyon) { $subs += 'veyon' }
        if ($comInst -and $Cfg.LabInfo) { $subs += 'vscode-extensoes' }
        $arqs = @()
        if ($comInst) {
            $arqs = @(Lista-Instaladores | Where-Object { $Prog.Pular -notcontains $_.Name })
            if ($Cfg.Glpi) { $arqs += @(Get-ChildItem (Join-Path $swOrigem 'basicos') -File -Filter '*glpi*agent*' -ErrorAction SilentlyContinue) }
            $mbI = [math]::Round((($arqs | Measure-Object Length -Sum).Sum) / 1MB)
            Write-Host "   Copiando $($arqs.Count) instalador(es) escolhido(s) ($mbI MB)."
            Write-Host '   Acompanhe na janela de cópia do Windows; pode levar alguns minutos.'
        } elseif ($Cfg.Glpi) {
            $arqs = @(Get-ChildItem (Join-Path $swOrigem 'basicos') -File -Filter '*glpi*agent*' -ErrorAction SilentlyContinue)
        }
        # Sem arquivos antigos no destino: a janela não pergunta "substituir?"
        if (Test-Path $swDestino) { Remove-Item -LiteralPath $swDestino -Recurse -Force -ErrorAction SilentlyContinue }
        try {
            Add-Type -AssemblyName Microsoft.VisualBasic
            New-Item -ItemType Directory -Path $swDestino -Force | Out-Null
            Get-ChildItem -LiteralPath $swOrigem -File | Copy-Item -Destination $swDestino -Force       # parametros.txt etc.
            foreach ($s in $subs) {
                $o = Join-Path $swOrigem $s
                if (-not (Test-Path $o)) { continue }
                [Microsoft.VisualBasic.FileIO.FileSystem]::CopyDirectory($o, (Join-Path $swDestino $s),
                    [Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
                    [Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException)
            }
            foreach ($a in $arqs) {
                $pastaA = Join-Path $swDestino $a.Directory.Name
                New-Item -ItemType Directory -Path $pastaA -Force | Out-Null
                [Microsoft.VisualBasic.FileIO.FileSystem]::CopyFile($a.FullName, (Join-Path $pastaA $a.Name),
                    [Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
                    [Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException)
            }
            # Veyon guardado em softwares\laboratorio (pendrives antigos): leva só o instalador dele
            if ((Usa-Veyon) -and -not $Cfg.LabInfo) {
                $vl = @(Get-ChildItem (Join-Path $swOrigem 'laboratorio') -Filter 'veyon*setup*.exe' -ErrorAction SilentlyContinue)
                if ($vl.Count -gt 0) {
                    New-Item -ItemType Directory -Path (Join-Path $swDestino 'veyon') -Force | Out-Null
                    $vl | Copy-Item -Destination (Join-Path $swDestino 'veyon') -Force
                }
            }
        } catch [System.OperationCanceledException] {
            Log 'AVISO: cópia cancelada na janela do Windows. A instalação continua do pendrive: NÃO tire o pendrive até o fim.' 'Yellow'
            return
        } catch {
            Log "AVISO: a cópia dos instaladores falhou ($($_.Exception.Message)); a instalação continua do pendrive." 'Yellow'
            return
        }
    }
    $mb = [math]::Round(((Get-ChildItem $destino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum) / 1MB)
    $script:Pen = $destino
    if ($Prog.Instalar -and -not $Prog.Copiar) { $script:SwInstalar = $swOrigem }   # instala do pendrive
    Log "Pasta copiada para a Área de Trabalho da CTI ($mb MB): $destino" 'Green'
}

# Tudo o que precisa do pendrive, logo no começo: cópia, dados do campus e Veyon. Depois: "pode tirar".
function Fase-Pendrive {
    Titulo 'Pendrive (só no começo)'
    $pd = Pasta-Pendrive
    Copiar-XamppDoPendrive                      # htdocs e bancos de um XAMPP recém-instalado (labs)
    Copiar-ParaAreaDeTrabalho
    Gravar-DadosCampus
    $script:VeyonFeito = $false
    $script:PcAnotado  = $false
    if (Usa-Veyon) {
        if ($Cfg.Tipo -eq 'LAB-PROF' -or (Eh-CentralVeyon)) {
            Configurar-Veyon                    # instala o Veyon Master e grava a chave no pendrive
            $script:VeyonFeito = $true
        } elseif ($pd) {
            Guardar-ChavesNoPC                  # chaves do lab e do campus: importadas depois, sem o pendrive
            $pp = Pasta-VeyonPen
            if ($pp) { Registrar-PcNoVeyon $pp; $script:PcAnotado = $true }
        }
    }
    Write-Host ''
    if ($pd -and $Pen -eq $pd) {
        Write-Host '  ATENÇÃO: a instalação vai rodar do próprio pendrive. Deixe-o conectado até o fim.' -ForegroundColor Yellow
    } elseif ($pd -and $SwInstalar -and $SwInstalar.StartsWith($pd, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Host '  ATENÇÃO: os programas vão ser instalados direto do pendrive. Deixe-o conectado até o fim.' -ForegroundColor Yellow
    } elseif ($pd) {
        Write-Host '  ══════════════════════════════════════════════════════════════' -ForegroundColor Green
        Write-Host '   PRONTO: PODE TIRAR O PENDRIVE. A instalação continua sozinha.' -ForegroundColor Green
        Write-Host '  ══════════════════════════════════════════════════════════════' -ForegroundColor Green
    } else {
        Write-Host '  Instalação sem pendrive: os dados do campus ficaram só na pasta do script.' -ForegroundColor Yellow
    }
}

# No fim: apaga os instaladores (.exe e .msi) da CÓPIA no PC, para a pasta ficar menor. O pendrive não muda.
function Apagar-InstaladoresDaCopia {
    if ($Pen -eq (Pasta-Pendrive)) { return }                                  # rodando do pendrive: não apaga nada
    if (-not $Pen.StartsWith($env:SystemDrive, [StringComparison]::OrdinalIgnoreCase)) { return }   # só cópia no disco do Windows
    $sw = Join-Path $Pen 'softwares'
    $arqs = @(Get-ChildItem $sw -Recurse -File -Include '*.exe', '*.msi' -ErrorAction SilentlyContinue)
    if ($arqs.Count -eq 0) { return }
    $mb = [math]::Round((($arqs | Measure-Object Length -Sum).Sum) / 1MB)
    $arqs | Remove-Item -Force -ErrorAction SilentlyContinue
    Log "Instaladores apagados da cópia em $Pen ($($arqs.Count) arquivo(s), $mb MB). Para reinstalar programas, use o pendrive." 'Green'
}
# ---- Favoritos ----
# "Pasta/Nome = endereço; ..." -> itens @{ Pasta; Nome; Url } (sem nome: o próprio site; sem https://: acrescenta)
function Ler-ListaFavoritos([string]$Texto) {
    $itens = @()
    foreach ($parte in ([string]$Texto -split ';')) {
        $s = $parte.Trim()
        if (-not $s) { continue }
        $nome = ''; $url = $s
        $i = $s.IndexOf('=')
        $q = $s.IndexOf('?')
        if ($i -gt 0 -and -not $s.Substring(0, $i).Contains('://') -and ($q -lt 0 -or $q -gt $i)) {
            $nome = $s.Substring(0, $i).Trim(); $url = $s.Substring($i + 1).Trim()
        }
        if (-not $url) { continue }
        if ($url -notmatch '^[A-Za-z][A-Za-z0-9+.-]*://') { $url = 'https://' + $url }
        $pasta = ''
        $j = $nome.IndexOf('/')
        if ($j -ge 0) { $pasta = $nome.Substring(0, $j).Trim(); $nome = $nome.Substring($j + 1).Trim() }
        if (-not $nome) { $nome = (($url -replace '^[A-Za-z][A-Za-z0-9+.-]*://', '') -replace '/.*$', '') }
        $itens += [pscustomobject]@{ Pasta = $pasta; Nome = $nome; Url = $url }
    }
    return $itens
}
# itens -> "Pasta/Nome = endereço; ..."
function Texto-ListaFavoritos($Itens) {
    return ((@($Itens) | Where-Object { $_ } | ForEach-Object {
        $n = if ($_.Pasta) { $_.Pasta + '/' + $_.Nome } else { $_.Nome }
        '{0} = {1}' -f $n, $_.Url }) -join '; ')
}
# Lista de favoritos de cada perfil: Ensino (professores e alunos) ou Adm (administrativos e CTI)
function Perfil-Favoritos($c) { if ([string]$c.Tipo -in 'OUTRO', 'CTI') { return 'Adm' } return 'Ensino' }
# Mostra a pasta de favoritos como ficará no navegador
function Mostrar-Favoritos($Itens, [bool]$ComMoodle) {
    $ifsp = if ($ComMoodle) { 'SUAP, Moodle' } else { 'SUAP' }
    Write-Host ('   {0}' -f $PastaFavoritos) -ForegroundColor Green
    Write-Host ('    > IFSP: {0}' -f $ifsp)
    $pastas = [ordered]@{}
    foreach ($f in @($Itens)) {
        if (-not $f) { continue }
        $k = if ($f.Pasta) { [string]$f.Pasta } else { ' ' }
        if (-not $pastas.Contains($k)) { $pastas[$k] = @() }
        $pastas[$k] += $f.Nome
    }
    foreach ($k in @($pastas.Keys)) {
        if ($k -eq ' ') { foreach ($n in $pastas[$k]) { Write-Host ('    - {0}' -f $n) } }
        else            { Write-Host ('    > {0}: {1}' -f $k, ($pastas[$k] -join ', ')) }
    }
}
# JSON da política ManagedBookmarks (Chrome) / ManagedFavorites (Edge): pasta principal, IFSP e as subpastas
function Montar-JsonFavoritos {
    $ifsp = New-Object System.Collections.ArrayList
    [void]$ifsp.Add([ordered]@{ name = 'SUAP'; url = $UrlSuap })
    if ($Cfg.Compartilhado -and $Cfg.Moodle) { [void]$ifsp.Add([ordered]@{ name = 'Moodle'; url = [string]$Cfg.Moodle }) }
    $pastas = [ordered]@{}
    $soltos = New-Object System.Collections.ArrayList
    foreach ($f in @(Ler-ListaFavoritos ([string]$Cfg.Favoritos))) {
        if (-not $f) { continue }
        $item = [ordered]@{ name = $f.Nome; url = $f.Url }
        if ($f.Pasta -eq 'IFSP') { [void]$ifsp.Add($item) }
        elseif ($f.Pasta) {
            if (-not $pastas.Contains($f.Pasta)) { $pastas[$f.Pasta] = New-Object System.Collections.ArrayList }
            [void]$pastas[$f.Pasta].Add($item)
        } else { [void]$soltos.Add($item) }
    }
    $raiz = New-Object System.Collections.ArrayList
    [void]$raiz.Add([ordered]@{ toplevel_name = $PastaFavoritos })
    [void]$raiz.Add([ordered]@{ name = 'IFSP'; children = $ifsp })
    foreach ($k in @($pastas.Keys)) { [void]$raiz.Add([ordered]@{ name = $k; children = $pastas[$k] }) }
    foreach ($s in $soltos) { [void]$raiz.Add($s) }
    return (ConvertTo-Json -InputObject $raiz -Depth 8 -Compress)
}
# Grava os favoritos no Chrome e no Edge (política da máquina; vale ao abrir o navegador de novo)
function Aplicar-Favoritos {
    $json = Montar-JsonFavoritos
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Google\Chrome'   'ManagedBookmarks' $json 'String'
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'ManagedFavorites' $json 'String'
}
function Mostrar-FormatoFavoritos {
    Write-Host '  Numa linha só, separados por ;  no formato   Pasta/Nome = endereço' -ForegroundColor DarkGray
    Write-Host ('  Sem "Pasta/", o favorito fica solto na pasta {0}. Não precisa de https://. Exemplo:' -f $PastaFavoritos) -ForegroundColor DarkGray
    Write-Host '    Programação Web/W3Schools = w3schools.com; Acadêmico/SciELO = scielo.org; Portal do IFSP = ifsp.edu.br' -ForegroundColor DarkGray
}

# Lab ou sala de aula: com blocos (ex.: RCL), pede o número da sala no bloco e monta o código (B104);
# sem blocos, aceita o número (lab 1-9 -> INF1; sala 1-99 -> SALA12) ou o código da sala (B104).
# Devolve $null se a pessoa digitar 0 (voltar).
function Ler-CodigoEspaco([string]$Esp, [string]$Bloco) {
    $oque = if ($Esp -eq 'LAB') { 'do laboratório' } else { 'da sala de aula' }
    while ($true) {
        if ($Bloco) {
            $r = (Perguntar ('Número {0} no bloco {1} (ex.: 104)' -f $oque, $Bloco)).Trim().ToUpper()
            if ($r -eq '0') { return $null }
            if ($r -match '^\d{1,4}$') { return ($Bloco + $r) }
            if ($r -match '^[A-Z]{1,2}\d{1,4}$') { return $r }
            Write-Host '  Digite só o número da sala (ex.: 104).' -ForegroundColor Yellow
        } else {
            $ex = if ($Esp -eq 'LAB') { 'número do lab (1-9)' } else { 'número da sala (1-99)' }
            $r = (Perguntar ('Identificação {0}: {1}, ou o código da sala (ex.: B104)' -f $oque, $ex)).Trim().ToUpper()
            if ($r -eq '0') { return $null }
            if ($Esp -eq 'LAB' -and $r -match '^[1-9]$') { return ('INF' + $r) }
            if ($Esp -ne 'LAB' -and $r -match '^\d{1,2}$' -and [int]$r -ge 1) { return ('SALA' + [int]$r) }
            if ($r -match '^[A-Z]{1,2}\d{1,4}$') { return $r }
            Write-Host '  Não entendi. Exemplos: 3 ou B104.' -ForegroundColor Yellow
        }
    }
}
# Pacote de programas dos PCs de professores e alunos fora dos labs.
# Devolve $true = programas do lab, $false = básicos, $null = voltar.
function Perguntar-Programas([string]$Onde) {
    Titulo "Programas deste PC ($Onde)"
    Write-Host '   1 - Básicos: Chrome, ONLYOFFICE, 7-Zip e VLC'
    Write-Host '        mais leve; para pesquisa, textos e planilhas' -ForegroundColor DarkGray
    Write-Host '   2 - Lab de informática: também os programas dos labs'
    Write-Host '        VS Code, Packet Tracer, XAMPP, VirtualBox, GIMP; a mesma experiência dos labs' -ForegroundColor DarkGray
    Write-Host '   0 - Voltar'
    $e = Ler-Numero 'Escolha (0 a 2)' 0 2
    if ($e -eq 0) { return $null }
    return ($e -eq 2)
}

function Fazer-Perguntas {
    # Perguntas em passos. Em todas, 0 = voltar à pergunta anterior (na primeira, volta ao menu inicial).
    # O histórico guarda só os passos que fizeram pergunta, então "voltar" pula os que não se aplicam.
    $passo = 'CAMPUS'
    $hist  = New-Object System.Collections.ArrayList
    $resp  = [ordered]@{}                     # respostas já dadas, mostradas no alto da tela
    $sigla = ''; $campus = ''; $site = ''; $dc = @{}; $bloco = ''; $grupo = 0
    $espaco = ''; $local = ''; $tipo = ''; $usuario = $null; $usuarioFixo = $false; $num = $null; $progLab = $false
    $nome = ''; $pastaSegura = $false; $pagina = $null; $moodle = $null; $favoritos = $null; $favPerfil = ''
    $tema = 'claro'; $glpi = $null; $central = $false; $cfgNovo = $null; $dominio = $null; $dominioDns = ''
    while ($true) {
        Mostrar-Cabecalho
        if ($passo -ne 'RESUMO') {
            if ($resp.Count -gt 0) { Write-Host ('  Respostas: ' + (@($resp.Values) -join '  >  ')) -ForegroundColor DarkGray }
            $txtVoltar = if ($hist.Count -eq 0) { '0 = voltar ao menu inicial' } else { 'em todas as perguntas, 0 = voltar à anterior' }
            Write-Host "  ($txtVoltar)" -ForegroundColor DarkGray
        }
        $voltar = $false; $proximo = ''; $semPergunta = $false
        $compart = ($tipo -notin 'OUTRO', 'CTI', '')
        switch ($passo) {

            'CAMPUS' {
                Titulo 'Campus'
                while ($true) {
                    $r = (Perguntar 'Sigla do campus (ex.: RCL, BRU)').Trim().ToUpper()
                    if ($r -eq '0') { $voltar = $true; break }
                    $linha = $ListaCampi | Where-Object { $_.Split('|')[0] -eq $r } | Select-Object -First 1
                    if ($linha) { break }
                    Write-Host '  Sigla não encontrada na lista de campi do IFSP. Tente de novo.' -ForegroundColor Yellow
                }
                if (-not $voltar) {
                    if ($r -ne $sigla) { $pagina = $null; $moodle = $null; $favoritos = $null; $glpi = $null; $dominio = $null; $dominioDns = '' }   # campus novo: sugestões dele
                    $sigla = $r; $p = $linha.Split('|'); $campus = $p[1]; $site = $p[2]; $bloco = ''
                    $dc = Ler-DadosCampus $sigla
                    $resp['CAMPUS'] = "$sigla - $campus" + $(if ($dc.Count -gt 0) { ' (dados do campus no pendrive)' } else { '' })
                    $proximo = if ($BlocosCampi.ContainsKey($sigla)) { 'BLOCO' } else { 'GRUPO' }
                }
            }

            'BLOCO' {
                Titulo 'Bloco (prédio)'
                $blocos = @($BlocosCampi[$sigla])
                while ($true) {
                    $r = (Perguntar ('Bloco onde fica o computador ({0})' -f ($blocos -join ', '))).Trim().ToUpper()
                    if ($r -eq '0') { $voltar = $true; break }
                    if ($r -in $blocos) { break }
                    Write-Host ('  Digite um destes: {0}' -f ($blocos -join ', ')) -ForegroundColor Yellow
                }
                if (-not $voltar) { $bloco = $r; $resp['BLOCO'] = "bloco $bloco"; $proximo = 'GRUPO' }
            }

            'GRUPO' {
                Titulo 'Onde fica este computador?'
                Write-Host '   1 - Ensino (labs de informática, salas de aula, sala dos professores, ciências, auditório, biblioteca)'
                Write-Host '   2 - Administrativo (setores)'
                Write-Host '   3 - Outro local (digitar a sigla; ex.: REUN para a sala de reuniões)'
                Write-Host '   0 - Voltar'
                $g = Ler-Numero 'Escolha (0 a 3)' 0 3
                if ($g -eq 0) { $voltar = $true }
                else { $grupo = $g; $resp['GRUPO'] = @('Ensino', 'Administrativo', 'Outro local')[$g - 1]; $proximo = 'ITEM' }
            }

            'ITEM' {
                if ($grupo -eq 1) {
                    Titulo 'Ensino'
                    for ($i = 0; $i -lt $LocaisEnsino.Count; $i++) { Write-Host ('  {0,2} - {1}' -f ($i + 1), $LocaisEnsino[$i].Split('|')[1]) }
                    Write-Host '   0 - Voltar'
                    $e = Ler-Numero "Escolha (0 a $($LocaisEnsino.Count))" 0 $LocaisEnsino.Count
                    if ($e -eq 0) { $voltar = $true }
                    else {
                        $p = $LocaisEnsino[$e - 1].Split('|')
                        $espaco = $p[0]; $local = $p[0]; $resp['ITEM'] = $p[1]; $proximo = 'DETALHE'
                    }
                } elseif ($grupo -eq 2) {
                    Titulo 'Administrativo'
                    for ($i = 0; $i -lt $LocaisAdm.Count; $i++) {
                        $p = $LocaisAdm[$i].Split('|')
                        Write-Host ('  {0,2} - {1,-5} {2}' -f ($i + 1), $p[0], $p[1])
                    }
                    Write-Host '   0 - Voltar'
                    $e = Ler-Numero "Escolha (0 a $($LocaisAdm.Count))" 0 $LocaisAdm.Count
                    if ($e -eq 0) { $voltar = $true }
                    else {
                        $local = $LocaisAdm[$e - 1].Split('|')[0]
                        $espaco = if ($local -eq 'CTI') { 'CTI' } else { 'ADM' }
                        $resp['ITEM'] = $local; $proximo = 'DETALHE'
                    }
                } else {
                    Titulo 'Outro local'
                    while ($true) {
                        $r = (Perguntar 'Sigla do local (2 a 6 letras ou números)').Trim().ToUpper()
                        if ($r -eq '0') { $voltar = $true; break }
                        if ($r -match '^[A-Z0-9]{2,6}$' -and $r -notmatch '^\d+$') { break }
                        Write-Host '  De 2 a 6 letras ou números (não só números). Ex.: REUN' -ForegroundColor Yellow
                    }
                    if (-not $voltar) { $local = $r; $espaco = 'OUTRO'; $resp['ITEM'] = "outro: $local"; $proximo = 'DETALHE' }
                }
            }

            'DETALHE' {
                # O que depende do local: código da sala, quem usa, programas, número do PC.
                # 0 em qualquer uma destas perguntas volta para a escolha do local.
                $num = $null; $progLab = $false; $usuario = $null; $usuarioFixo = $false; $tipo = ''
                $desc = ''
                switch ($espaco) {
                    'LAB' {
                        $cod = Ler-CodigoEspaco 'LAB' $bloco
                        if ($null -eq $cod) { $voltar = $true } else { $local = $cod }
                        if (-not $voltar) {
                            while ($true) {
                                $r = (Perguntar 'Número do PC (1-99, ou P para o PC do professor)').Trim().ToUpper()
                                if ($r -eq '0') { $voltar = $true; break }
                                if ($r -eq 'P') { $num = 0; break }
                                if (($r -match '^\d{1,2}$') -and ([int]$r -ge 1)) { $num = [int]$r; break }
                                Write-Host '  Digite um número de 1 a 99, ou P (0 = voltar).' -ForegroundColor Yellow
                            }
                        }
                        if (-not $voltar) {
                            if ($num -eq 0) { $tipo = 'LAB-PROF'; $usuario = $ContaProf; $desc = "$local, PC do professor" }
                            else { $tipo = 'LAB-ALUNO'; $usuario = $ContaAluno; $desc = "$local, PC $num" }
                            $progLab = $true
                        }
                    }
                    'SALA' {
                        $cod = Ler-CodigoEspaco 'SALA' $bloco
                        if ($null -eq $cod) { $voltar = $true } else { $local = $cod }
                        if (-not $voltar) {
                            $pl = Perguntar-Programas 'sala de aula'
                            if ($null -eq $pl) { $voltar = $true } else { $progLab = $pl }
                        }
                        $tipo = 'USO-PROF'; $usuario = $ContaProf; $desc = $local
                    }
                    'PROF' {
                        $pl = Perguntar-Programas 'sala dos professores'
                        if ($null -eq $pl) { $voltar = $true } else { $progLab = $pl }
                        if (-not $voltar) {
                            $n = Ler-NumeroOuVoltar 'Número do PC na sala dos professores (1-99)' 1 99
                            if ($null -eq $n) { $voltar = $true } else { $num = $n }
                        }
                        $tipo = 'USO-PROF'; $usuario = $ContaProf; $desc = "PC $num"
                    }
                    'CIE' {
                        $pl = Perguntar-Programas 'laboratório de ciências'
                        if ($null -eq $pl) { $voltar = $true } else { $progLab = $pl }
                        $tipo = 'USO-PROF'; $usuario = $ContaProf
                    }
                    'AUD' {
                        $tipo = 'OUTRO'; $usuario = 'AUD'; $usuarioFixo = $true
                        $semPergunta = $true                  # nada a perguntar aqui
                    }
                    'CBI' {
                        Titulo 'Quem usará o computador da biblioteca?'
                        Write-Host '   1 - Alunos: regras da conta Alunos (navegador anônimo, limpeza, pop-up de regras, sem impressão)'
                        Write-Host '   2 - Servidores: regras do administrativo (navegador normal, nada é apagado)'
                        Write-Host '   0 - Voltar'
                        $q = Ler-Numero 'Escolha (0 a 2)' 0 2
                        if ($q -eq 0) { $voltar = $true }
                        elseif ($q -eq 1) {
                            $tipo = 'USO-ALUNO'; $usuario = $ContaAluno; $desc = 'alunos'
                            $pl = Perguntar-Programas 'biblioteca, alunos'
                            if ($null -eq $pl) { $voltar = $true } else { $progLab = $pl }
                        } else { $tipo = 'OUTRO'; $desc = 'servidores' }
                        if (-not $voltar) {
                            $n = Ler-NumeroOuVoltar 'Número do PC na biblioteca (1-99; não repita entre alunos e servidores)' 1 99
                            if ($null -eq $n) { $voltar = $true } else { $num = $n; $desc += ", PC $num" }
                        }
                    }
                    { $_ -in 'ADM', 'CTI' } {
                        if ($espaco -eq 'CTI') { $tipo = 'CTI'; $usuario = $ContaAdmin; $usuarioFixo = $true } else { $tipo = 'OUTRO' }
                        $n = Ler-NumeroOuVoltar 'Número do PC neste setor (1-99)' 1 99
                        if ($null -eq $n) { $voltar = $true } else { $num = $n; $desc = "PC $num" }
                    }
                    'OUTRO' {
                        Titulo 'Quem usará o computador?'
                        Write-Host '   1 - Professores: conta Professor (navegador anônimo, limpeza a cada logon, Pasta Segura opcional)'
                        Write-Host '   2 - Alunos: conta Alunos (navegador anônimo, limpeza, pop-up de regras, sem impressão)'
                        Write-Host '   3 - Servidores: regras do administrativo (navegador normal, nada é apagado)'
                        Write-Host '   0 - Voltar'
                        $q = Ler-Numero 'Escolha (0 a 3)' 0 3
                        if ($q -eq 0) { $voltar = $true }
                        elseif ($q -eq 3) { $tipo = 'OUTRO'; $desc = 'servidores' }
                        else {
                            if ($q -eq 1) { $tipo = 'USO-PROF'; $usuario = $ContaProf; $desc = 'professores' }
                            else          { $tipo = 'USO-ALUNO'; $usuario = $ContaAluno; $desc = 'alunos' }
                            $pl = Perguntar-Programas $desc
                            if ($null -eq $pl) { $voltar = $true } else { $progLab = $pl }
                        }
                        if (-not $voltar) {
                            $n = Ler-NumeroOuVoltar 'Número do PC neste local (1-99)' 1 99
                            if ($null -eq $n) { $voltar = $true } else { $num = $n; $desc += ", PC $num" }
                        }
                    }
                }
                if (-not $voltar) {
                    if ($tipo -in 'USO-PROF', 'USO-ALUNO') { $desc = (@($desc, $(if ($progLab) { 'programas do lab' } else { 'programas básicos' })) | Where-Object { $_ }) -join ', ' }
                    if ($desc) { $resp['DETALHE'] = $desc }
                    $proximo = 'NOME'
                }
            }

            'NOME' {
                Titulo 'Nome do computador'
                $sug = if ($null -eq $num) { '{0}-{1}' -f $sigla, $local } else { '{0}-{1}-{2:D2}' -f $sigla, $local, $num }
                while ($true) {
                    $r = (Perguntar "Nome: $sug   (ENTER confirma, ou digite outro nome)").Trim().ToUpper()
                    if ($r -eq '0') { $voltar = $true; break }
                    if ($r -eq '') { $nome = $sug; break }
                    if (Nome-PC-Valido $r) { $nome = $r; break }
                    Write-Host '  Nome inválido: até 15 caracteres, só letras, números e hífen;' -ForegroundColor Yellow
                    Write-Host '  não pode começar nem terminar com hífen, nem ter só números.' -ForegroundColor Yellow
                }
                if (-not $voltar) {
                    $resp['NOME'] = $nome
                    $proximo = if ($tipo -eq 'OUTRO' -and -not $usuarioFixo) { 'USUARIO' } elseif ($compart) { 'PASTA' } else { 'PAGINA' }
                }
            }

            'USUARIO' {
                # administrativo: nome do PC sem a sigla do campus (ex.: CRA-01); a pessoa pode criar a própria senha
                Titulo 'Usuário deste computador'
                $sug = $nome
                if ($sug.StartsWith("$sigla-")) { $sug = $sug.Substring($sigla.Length + 1) }
                if (-not (Nome-Usuario-Valido $sug $nome)) { $sug = '' }
                while ($true) {
                    $txt = if ($sug) { "Usuário: $sug   (ENTER confirma, ou digite outro nome)" } else { 'Nome do usuário deste PC' }
                    $r = (Perguntar $txt).Trim().ToUpper()
                    if ($r -eq '0') { $voltar = $true; break }
                    if ($r -eq '' -and $sug) { $usuario = $sug; break }
                    if ($r -and (Nome-Usuario-Valido $r $nome)) { $usuario = $r; break }
                    Write-Host '  Nome inválido: até 20 caracteres, letras, números, ponto, hífen; diferente do nome do PC e de CTI.' -ForegroundColor Yellow
                }
                if (-not $voltar) { $resp['USUARIO'] = "usuário $usuario"; $proximo = 'PAGINA' }
            }

            'PASTA' {
                Titulo 'Pasta Segura'
                Write-Host "  Neste PC, a cada logon, logoff e desligamento, a conta $usuario tem a Área de Trabalho,"
                Write-Host '  Documentos, Downloads, Imagens, Vídeos e Músicas apagados.'
                Write-Host '  A Pasta Segura é uma pasta na Área de Trabalho cujo conteúdo NÃO é apagado.'
                Write-Host '  Na conta Alunos ela é compartilhada: o que um aluno deixar lá, a próxima turma vê.' -ForegroundColor DarkGray
                Write-Host '  Dá para criar ou tirar depois, na Manutenção > Pasta Segura.' -ForegroundColor DarkGray
                $pad = ($tipo -in 'LAB-PROF', 'USO-PROF')
                $p = if ($pad) { 'S' } else { 'N' }
                do { $r = (Perguntar "Criar a Pasta Segura? (S/N, ENTER = $p)").Trim().ToUpper() } until ($r -in '', 'S', 'N', '0')
                if ($r -eq '0') { $voltar = $true }
                else {
                    $pastaSegura = if ($r -eq '') { $pad } else { ($r -eq 'S') }
                    $resp['PASTA'] = 'Pasta Segura: ' + $(if ($pastaSegura) { 'sim' } else { 'não' })
                    $proximo = 'PAGINA'
                }
            }

            'PAGINA' {
                Titulo 'Página inicial do Chrome e do Edge'
                if (-not $pagina) { $pagina = if ($dc.PaginaInicial) { $dc.PaginaInicial } else { $site } }
                Write-Host "  Sugestão: $pagina" -ForegroundColor Green
                Write-Host '  Para usar outra, digite o endereço. Não precisa de https://  (ex.: www.google.com.br)' -ForegroundColor DarkGray
                $r = Ler-EnderecoPergunta 'ENTER confirma a sugestão, ou digite outro endereço' $pagina $false
                if ($null -eq $r) { $voltar = $true }
                else { $pagina = $r; $resp['PAGINA'] = $pagina; $proximo = if ($compart) { 'MOODLE' } else { 'FAVORITOS' } }
            }

            'MOODLE' {
                Titulo 'Moodle do campus (favorito no Chrome e no Edge, na pasta IFSP, junto com o SUAP)'
                if ($null -eq $moodle) { $moodle = if ($dc.Moodle) { $dc.Moodle } elseif ($MoodleCampi.ContainsKey($sigla)) { $MoodleCampi[$sigla] } else { '' } }
                if ($moodle) {
                    Write-Host "  Sugestão: $moodle" -ForegroundColor Green
                    $r = Ler-EnderecoPergunta 'ENTER confirma, digite outro endereço, ou N para não ter Moodle' $moodle $true
                } else {
                    Write-Host '  Digite o endereço do Moodle do campus. Não precisa de https://' -ForegroundColor DarkGray
                    $r = Ler-EnderecoPergunta 'Endereço do Moodle (ENTER = sem Moodle; fica só o SUAP)' '' $true
                }
                if ($null -eq $r) { $voltar = $true }
                else { $moodle = $r; $resp['MOODLE'] = 'Moodle: ' + $(if ($moodle) { 'sim' } else { 'não' }); $proximo = 'FAVORITOS' }
            }

            'FAVORITOS' {
                $perfilFav = if ($tipo -in 'OUTRO', 'CTI') { 'Adm' } else { 'Ensino' }
                if ($null -eq $favoritos -or $favPerfil -ne $perfilFav) {
                    $favoritos = if ($dc.ContainsKey("Favoritos$perfilFav")) { [string]$dc["Favoritos$perfilFav"] }
                                 elseif ($perfilFav -eq 'Ensino') { $FavoritosEnsinoPadrao } else { $FavoritosAdmPadrao }
                    $favPerfil = $perfilFav
                }
                $comMoodleFav = ($perfilFav -eq 'Ensino') -and [bool]$moodle
                Titulo ('Favoritos (pasta "{0}" na barra do Chrome e do Edge)' -f $PastaFavoritos)
                Write-Host '  A subpasta IFSP entra sozinha (SUAP e, nos PCs de professores e alunos, o Moodle).' -ForegroundColor DarkGray
                Write-Host '  Outros favoritos:' -ForegroundColor DarkGray
                Mostrar-FormatoFavoritos
                while ($true) {
                    if ($favoritos) {
                        Write-Host ''
                        Write-Host '  Lista sugerida:' -ForegroundColor Green
                        Mostrar-Favoritos @(Ler-ListaFavoritos $favoritos) $comMoodleFav
                        $r = (Perguntar 'ENTER confirma, N = sem outros favoritos, ou digite outra lista').Trim()
                    } else {
                        $r = (Perguntar 'Digite a lista (ENTER = sem outros favoritos)').Trim()
                    }
                    if ($r -eq '0') { $voltar = $true; break }
                    if ($r -eq '') { break }
                    if ($r -in 'N', 'n') { $favoritos = ''; break }
                    $favoritos = Texto-ListaFavoritos @(Ler-ListaFavoritos $r)
                }
                if (-not $voltar) {
                    if ($favoritos) { $favoritos = Texto-ListaFavoritos @(Ler-ListaFavoritos $favoritos) }
                    $nf = @(Ler-ListaFavoritos $favoritos).Count
                    $resp['FAVORITOS'] = "favoritos: $nf"
                    $proximo = 'TEMA'
                }
            }

            'TEMA' {
                Titulo 'Aparência (vale para todos os usuários do PC)'
                Write-Host '   1 - Modo claro  (papel de parede claro)'
                Write-Host '   2 - Modo escuro (papel de parede escuro)'
                Write-Host '   0 - Voltar'
                $e = Ler-Numero 'Escolha (0 a 2)' 0 2
                if ($e -eq 0) { $voltar = $true }
                else { $tema = if ($e -eq 1) { 'claro' } else { 'escuro' }; $resp['TEMA'] = "tema $tema"; $proximo = 'GLPI' }
            }

            'GLPI' {
                Titulo 'GLPI'
                if ($null -eq $glpi) { $glpi = if ($dc.Glpi) { $dc.Glpi } else { '' } }
                if ($glpi) { Write-Host "  Sugestão: $glpi" -ForegroundColor Green }
                while ($true) {
                    $txtG = if ($glpi) { 'ENTER confirma, digite outro IP, ou N para campus sem GLPI' } else { 'IP do servidor GLPI do campus (ENTER = campus sem GLPI)' }
                    $r = (Perguntar $txtG).Trim()
                    if ($r -eq '0') { $voltar = $true; break }
                    if ($r -eq '') { break }
                    if ($r -in 'N', 'n') { $glpi = ''; break }
                    if ($r -match '^https?://') { $glpi = $r; break }
                    if ($r -match '^[A-Za-z0-9.-]+(:\d+)?$') { $glpi = "http://$r/front/inventory.php"; break }
                    Write-Host '  Endereço inválido. Ex.: 192.168.1.189' -ForegroundColor Yellow
                }
                if (-not $voltar) {
                    $resp['GLPI'] = 'GLPI: ' + $(if ($glpi) { 'sim' } else { 'não' })
                    $proximo = 'DOMINIO'
                }
            }

            'DOMINIO' {
                Titulo 'Domínio (UCS ou Active Directory)'
                Write-Host '  Só se o campus tiver servidor de domínio. Sem domínio, o PC funciona como hoje (contas locais).' -ForegroundColor DarkGray
                Write-Host '  O PC entra no domínio no fim da instalação (ou depois, na Manutenção > Domínio), com um usuário do domínio.' -ForegroundColor DarkGray
                if ($null -eq $dominio) {
                    $dominio    = if ($dc.Dominio)    { [string]$dc.Dominio }    else { '' }
                    $dominioDns = if ($dc.DominioDns) { [string]$dc.DominioDns } else { '' }
                }
                if ($dominio) { Write-Host "  Sugestão: $dominio (servidor $dominioDns)" -ForegroundColor Green }
                while ($true) {
                    $txtD = if ($dominio) { 'ENTER confirma, digite outro domínio, ou N para sem domínio' } else { 'Nome do domínio (ex.: escola.ifsp.local; ENTER = sem domínio)' }
                    $r = (Perguntar $txtD).Trim()
                    if ($r -eq '0') { $voltar = $true; break }
                    if ($r -eq '') { break }
                    if ($r -in 'N', 'n') { $dominio = ''; $dominioDns = ''; break }
                    if ($r -match '^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$') { $dominio = $r.ToLower(); break }
                    Write-Host '  Nome inválido. Ex.: escola.ifsp.local' -ForegroundColor Yellow
                }
                if (-not $voltar -and $dominio) {
                    while ($true) {
                        $txtI = if ($dominioDns) { "IP do servidor do domínio: $dominioDns   (ENTER confirma, ou digite outro)" } else { 'IP do servidor do domínio (vira o DNS do PC)' }
                        $r = (Perguntar $txtI).Trim()
                        if ($r -eq '0') { $voltar = $true; break }
                        if ($r -eq '' -and $dominioDns) { break }
                        if (Ip-Valido $r) { $dominioDns = $r; break }
                        Write-Host '  IP inválido. Ex.: 192.168.1.10' -ForegroundColor Yellow
                    }
                }
                if (-not $voltar) {
                    $resp['DOMINIO'] = 'domínio: ' + $(if ($dominio) { $dominio } else { 'não' })
                    $proximo = if ($tipo -eq 'CTI') { 'CENTRAL' } else { 'RESUMO' }
                }
            }

            'CENTRAL' {
                Titulo 'Veyon'
                Write-Host '  O PC central do Veyon vê as telas de todos os PCs de professores e alunos do campus' -ForegroundColor DarkGray
                Write-Host '  (labs, salas, CIE, sala dos professores, biblioteca de alunos), separados por seção.' -ForegroundColor DarkGray
                Write-Host '  Configure o central ANTES dos outros PCs: ele grava no pendrive a chave do campus.' -ForegroundColor DarkGray
                do { $r = (Perguntar 'Este PC será o PC central do Veyon? (S/N, ENTER = N)').Trim().ToUpper() } until ($r -in '', 'S', 'N', '0')
                if ($r -eq '0') { $voltar = $true }
                else { $central = ($r -eq 'S'); $resp['CENTRAL'] = 'central do Veyon: ' + $(if ($central) { 'sim' } else { 'não' }); $proximo = 'RESUMO' }
            }

            'RESUMO' {
                if (-not $compart) {          # administrativo: o Moodle não é perguntado, mas fica a sugestão (vai para o pendrive)
                    if ($null -eq $moodle) { $moodle = if ($dc.Moodle) { $dc.Moodle } elseif ($MoodleCampi.ContainsKey($sigla)) { $MoodleCampi[$sigla] } else { '' } }
                    $pastaSegura = $false
                }
                if ($tipo -ne 'CTI') { $central = $false }
                $cfgNovo = [pscustomobject][ordered]@{
                    Versao   = $Versao
                    Sigla    = $sigla
                    Campus   = $campus
                    Site     = $site
                    PaginaInicial = $pagina
                    Tipo     = $tipo
                    Local    = $local
                    NomePC   = $nome
                    Usuario  = $usuario
                    PastaSegura = $pastaSegura
                    Moodle   = $moodle
                    Tema     = $tema
                    Glpi     = $glpi
                    Dominio  = [string]$dominio
                    DominioDns = $(if ($dominio) { [string]$dominioDns } else { '' })
                    VeyonCentral = $central
                    ProgramasLab = [bool]$progLab
                    Espaco   = $espaco
                    Bloco    = $bloco
                    Favoritos = [string]$favoritos
                    Etapa    = 'respondido'
                    Data     = (Get-Date -Format 'yyyy-MM-dd HH:mm')
                }
                Mostrar-Resumo $cfgNovo
                do { $r = (Perguntar 'As respostas estão corretas?  (ENTER = confirmar, 0 = voltar à pergunta anterior, N = responder tudo de novo)').Trim().ToUpper() } until ($r -in '', 'S', 'N', '0')
                if ($r -eq '0') { $voltar = $true }
                elseif ($r -eq 'N') { $hist.Clear(); $resp.Clear(); $semPergunta = $true; $proximo = 'CAMPUS' }
                else { $proximo = 'FIM' }
            }
        }

        if ($voltar) {
            if ($hist.Count -eq 0) { return $null }                 # voltar na primeira pergunta = menu inicial
            $passo = [string]$hist[$hist.Count - 1]
            $hist.RemoveAt($hist.Count - 1)
            foreach ($k in @($resp.Keys)) { if (-not $hist.Contains($k)) { $resp.Remove($k) } }
        } elseif ($proximo -eq 'FIM') {
            return $cfgNovo
        } else {
            if (-not $semPergunta) { [void]$hist.Add($passo) }
            $passo = $proximo
        }
    }
}

function Mostrar-Resumo($c) {
    $descTipo = switch ($c.Tipo) {
        'LAB-ALUNO' { 'Laboratório de informática - PC de aluno' }
        'LAB-PROF'  { 'Laboratório de informática - PC do professor' }
        'USO-PROF'  { 'Uso de professores (regras do Professor do lab)' }
        'OUTRO'     { 'Administrativo (regras de administrativo)' }
        'USO-ALUNO' { 'Uso de alunos (regras da conta Alunos do lab)' }
        'CTI'       { 'Setor CTI (só a conta CTI)' }
        default     { 'Administrativo (servidores)' }
    }
    $compart = ($c.Tipo -notin 'OUTRO', 'CTI')
    Titulo 'Resumo'
    Write-Host ('   Campus ........ {0} - {1}' -f $c.Sigla, $c.Campus)
    $descEsp = switch (Espaco-DoCfg $c) {
        'LAB'   { "Laboratório de informática $($c.Local)" }
        'SALA'  { "Sala de aula $($c.Local)" }
        'PROF'  { 'Sala dos professores' }
        'CIE'   { 'Laboratório de ciências' }
        'AUD'   { 'Auditório (regras de administrativo, sem Veyon)' }
        'CBI'   { 'Biblioteca' }
        'CTI'   { 'Coordenadoria de TI' }
        'ADM'   { "Setor $($c.Local)" }
        default { "Outro local ($($c.Local))" }
    }
    if ($c.Bloco) { $descEsp += " - bloco $($c.Bloco)" }
    Write-Host ('   Local ......... {0}' -f $descEsp)
    Write-Host ('   Tipo .......... {0}' -f $descTipo)
    if ($c.Tipo -in 'USO-ALUNO', 'USO-PROF') {
        Write-Host ('   Programas ..... {0}' -f $(if ($c.ProgramasLab) { 'os mesmos dos labs de informática' } else { 'só os básicos' }))
    }
    Write-Host ('   Nome do PC .... {0}' -f $c.NomePC) -ForegroundColor Green
    if ($c.Tipo -eq 'CTI') {
        Write-Host '   Usuário ....... CTI (só esta conta; pede a senha ao ligar)' -ForegroundColor Green
        Write-Host ('   Veyon ......... {0}' -f $(if ($c.VeyonCentral) { 'PC central do campus' } else { 'não' }))
    } else {
        Write-Host ('   Usuário ....... {0} (entra sozinho ao ligar, enquanto não tiver senha)' -f $c.Usuario) -ForegroundColor Green
        $quemSenha = if ($compart) { 'só a CTI define (Manutenção > Senha)' } else { 'a própria pessoa pode criar' }
        Write-Host ('   Senha ......... {0}' -f $quemSenha)
    }
    if ($compart) {
        Write-Host ('   Pasta Segura .. {0}' -f $(if ($c.PastaSegura) { 'sim' } else { 'não' }))
        Write-Host ('   Desliga às 23:30 {0}' -f $(if (Tem-Horario $c) { 'sim (com aviso e Adiar)' } else { 'não (nunca desliga sozinho)' }))
        Write-Host ('   Moodle ........ {0}' -f $(if ($c.Moodle) { $c.Moodle } else { '(sem Moodle)' }))
        Write-Host ('   Veyon ......... seção "{0}" (pasta do pendrive: arquivos\veyon\{1})' -f (Nome-SecaoVeyon (Grupo-Veyon $c)), (Pasta-LocalVeyon $c))
    }
    Write-Host ('   Tema .......... {0}' -f $c.Tema)
    Write-Host ('   Página inicial  {0}' -f $c.PaginaInicial)
    $g = if ($c.Glpi) { $c.Glpi } else { '(sem GLPI)' }
    Write-Host ('   GLPI .......... {0}' -f $g)
    $d = if ($c.Dominio) { '{0} (servidor {1})' -f $c.Dominio, $c.DominioDns } else { '(sem domínio)' }
    Write-Host ('   Domínio ....... {0}' -f $d)
    Write-Host ''
}

# ---------------------------------------------------------------
#  Instalação dos programas do pendrive
# ---------------------------------------------------------------
function Ler-Parametros {
    $tab = @{}
    $arq = Join-Path (Pasta-Sw) 'parametros.txt'
    if (Test-Path $arq) {
        foreach ($l in (Get-Content $arq -Encoding UTF8)) {
            if ($l -match '^\s*#' -or $l -notmatch '=') { continue }
            $i = $l.IndexOf('=')
            $tab[$l.Substring(0, $i).Trim().ToLower()] = $l.Substring($i + 1).Trim()
        }
    }
    return $tab
}

# Descobre o tipo do instalador .exe lendo o começo do arquivo
function Tipo-Instalador([string]$Arquivo) {
    $fs = [IO.File]::OpenRead($Arquivo)
    try {
        $tam = [Math]::Min($fs.Length, 8MB)
        $buf = New-Object byte[] $tam
        [void]$fs.Read($buf, 0, $tam)
    } finally { $fs.Close() }
    $txt = [Text.Encoding]::ASCII.GetString($buf)
    $uni = [Text.Encoding]::Unicode.GetString($buf)      # textos do recurso de versão ficam em UTF-16
    if ($txt.Contains('Inno Setup') -or $txt.Contains('JR.Inno.Setup') -or $uni.Contains('Inno Setup')) { return 'INNO' }
    if ($txt.Contains('Nullsoft') -or $uni.Contains('Nullsoft'))   { return 'NSIS' }
    return 'DESCONHECIDO'
}

# Pasta de onde os programas são instalados: a cópia no PC ou, sem cópia dos instaladores, o pendrive
function Pasta-Sw {
    if ($script:SwInstalar) { return $script:SwInstalar }
    return (Join-Path $Pen 'softwares')
}

# Instaladores deste tipo de PC, na ordem em que são instalados: basicos (todos) e, nos labs, laboratorio.
# O Visual C++ (vc_redist) vai primeiro. Fora da lista: Veyon e agente do GLPI (têm etapa própria).
function Lista-Instaladores {
    $pastas = @('basicos')
    if ($Cfg.LabInfo) { $pastas += 'laboratorio' }
    $lista = @()
    foreach ($p in $pastas) {
        $c = Join-Path (Pasta-Sw) $p
        if (-not (Test-Path $c)) { continue }
        $lista += @(Get-ChildItem -Path $c -File |
                    Where-Object { $_.Extension -in '.msi', '.exe' -and $_.Name -notlike 'veyon*' -and $_.Name -notlike '*glpi*agent*' } |
                    Sort-Object @{ Expression = { if ($_.Name -like 'vc_redist*') { 0 } else { 1 } } }, Name)
    }
    return $lista
}

# ---- XAMPP: versões
function Versao-DoNome([string]$Nome) {
    if ($Nome -match '([0-9]+\.[0-9]+\.[0-9]+)') { return $Matches[1] }
    return ''
}
function Versao-XamppEm([string]$Pasta) {      # lê o readme do XAMPP ("ApacheFriends XAMPP Version 8.5.12")
    foreach ($a in 'readme_en.txt', 'readme_de.txt') {
        $arq = Join-Path $Pasta $a
        if (-not (Test-Path $arq)) { continue }
        $m = Select-String -Path $arq -Pattern 'XAMPP[^0-9\r\n]*([0-9]+\.[0-9]+\.[0-9]+)' | Select-Object -First 1
        if ($m) { return $m.Matches[0].Groups[1].Value }
    }
    return '?'
}
function Versao-XamppPC {                       # $null = sem XAMPP; '?' = existe, versão desconhecida
    if (-not (Test-Path 'C:\xampp')) { return $null }
    return (Versao-XamppEm 'C:\xampp')
}
function Nota-Xampp([string]$Nome) {
    $vp = Versao-XamppPC
    if ($null -eq $vp) { return '' }
    $vn = Versao-DoNome $Nome
    if ($vp -eq $vn) { return "<- o PC já tem o XAMPP $vp`: não reinstala; htdocs e bancos voltam ao padrão" }
    $txt = if ($vp -eq '?') { 'de versão desconhecida' } else { $vp }
    return "<- o PC tem o XAMPP $txt`: APAGA o antigo e instala este"
}

# Programas: pergunta ANTES da cópia (instalar?, quais não, copiar os instaladores?). 0 volta um passo;
# na primeira pergunta, volta ao menu inicial ('VOLTAR'). Devolve @{ Instalar; Pular (nomes); Copiar }.
function Escolher-Programas {
    $sem    = @{ Instalar = $false; Pular = @(); Copiar = $false }
    $lista  = @(Lista-Instaladores)
    $pd     = Pasta-Pendrive
    $podeCopiar = [bool]($pd -and $Pen -eq $pd)
    $passo  = 'INSTALAR'
    $pular  = @()
    while ($true) {
        if ($passo -eq 'INSTALAR') {
            Titulo 'Programas'
            if ($lista.Count -eq 0) {
                Write-Host '  Não há instaladores para este tipo de PC (softwares\basicos e softwares\laboratorio).' -ForegroundColor Yellow
                $r = (Perguntar 'Aperte ENTER para seguir sem instalar programas (0 = voltar ao menu inicial)').Trim()
                if ($r -eq '0') { return 'VOLTAR' }
                return $sem
            }
            Write-Host '  Com N, os programas que já estão no PC ficam como estão e nenhum instalador é copiado.' -ForegroundColor DarkGray
            do { $r = (Perguntar 'Instalar os programas do pendrive?  (S/N, 0 = voltar ao menu inicial)').Trim().ToUpper() } until ($r -in 'S', 'N', '0')
            if ($r -eq '0') { return 'VOLTAR' }
            if ($r -eq 'N') { return $sem }
            $passo = 'LISTA'
        }
        elseif ($passo -eq 'LISTA') {
            Titulo 'Programas para este PC'
            $pastaAnt = ''
            for ($i = 0; $i -lt $lista.Count; $i++) {
                $f = $lista[$i]
                if ($f.Directory.Name -ne $pastaAnt) {
                    $pastaAnt = $f.Directory.Name
                    $rot = if ($pastaAnt -eq 'basicos') { 'Básicos (todos os PCs)' } else { 'Laboratório de informática' }
                    Write-Host "   $rot" -ForegroundColor Cyan
                }
                Write-Host ('   {0,3} - {1}' -f ($i + 1), $f.Name) -NoNewline
                $nota = if ($f.Name -like 'xampp*') { Nota-Xampp $f.Name } else { '' }
                if ($nota) { Write-Host "   $nota" -ForegroundColor Yellow } else { Write-Host '' }
            }
            Write-Host '   (o Veyon e o agente do GLPI têm etapa própria e não entram nesta lista)' -ForegroundColor DarkGray
            $t = (Perguntar 'Quais NÃO instalar? Números separados por ; (ex.: 2;5). ENTER = instalar todos, 0 = voltar').Trim()
            if ($t -eq '0') { $passo = 'INSTALAR'; continue }
            $nums = @()
            $ok = $true
            foreach ($pedaco in @($t -split '[;, ]+' | Where-Object { $_ })) {
                $n = 0
                if (-not [int]::TryParse($pedaco, [ref]$n) -or $n -lt 1 -or $n -gt $lista.Count) { $ok = $false; break }
                $nums += $n
            }
            if (-not $ok) { Write-Host "  Use números de 1 a $($lista.Count), separados por ; (ex.: 2;5)." -ForegroundColor Yellow; continue }
            $pular = @($nums | Select-Object -Unique | ForEach-Object { $lista[$_ - 1].Name })
            $vao   = @($lista | Where-Object { $pular -notcontains $_.Name })
            Write-Host ''
            if ($vao.Count -eq 0) {
                Write-Host '  Nenhum programa ficou para instalar.' -ForegroundColor Yellow
                if (Confirmar-Enter 'Seguir sem instalar programas?') { return $sem }
                continue
            }
            if ($pular.Count -gt 0) { Write-Host "  NÃO serão instalados: $($pular -join ', ')" -ForegroundColor Yellow }
            else { Write-Host '  Todos serão instalados.' -ForegroundColor Green }
            if (@($vao | Where-Object { $_.Name -like 'xampp*' }).Count -gt 0 -and @($vao | Where-Object { $_.Name -like 'vc_redist*' }).Count -eq 0) {
                Write-Host '  ATENÇÃO: sem o vc_redist.x64.exe (Visual C++), o instalador do XAMPP pode REINICIAR o PC no meio.' -ForegroundColor Red
                Write-Host '  Ponha o vc_redist.x64.exe em softwares\basicos (https://aka.ms/vs/17/release/vc_redist.x64.exe).' -ForegroundColor Red
            }
            if (-not $podeCopiar) { return @{ Instalar = $true; Pular = $pular; Copiar = $false } }
            $passo = 'COPIAR'
        }
        elseif ($passo -eq 'COPIAR') {
            Titulo 'Cópia dos instaladores'
            Write-Host '  S = copia os instaladores escolhidos para o PC (janela de cópia do Windows); o pendrive sai logo no começo.'
            Write-Host '  N = instala direto do pendrive (deixe-o conectado até o fim). O resto da pasta é copiado sempre.'
            do { $r = (Perguntar 'Copiar os instaladores para o PC antes de instalar?  (S/N, 0 = voltar)').Trim().ToUpper() } until ($r -in 'S', 'N', '0')
            if ($r -eq '0') { $passo = 'LISTA'; continue }
            return @{ Instalar = $true; Pular = $pular; Copiar = ($r -eq 'S') }
        }
    }
}

# ---- XAMPP: padrão de recém-instalado (htdocs e bancos do MySQL)
# Do pendrive (arquivos\xampp = cópia de C:\xampp recém-instalado) vêm só a htdocs, os bancos e o readme (versão).
function Copiar-XamppDoPendrive {
    if (-not $Cfg.LabInfo) { return }
    $orig = Join-Path $Pen 'arquivos\xampp'
    if (-not (Test-Path (Join-Path $orig 'htdocs'))) { return }
    $dest = Join-Path $Base 'xampp-pendrive'
    if (Test-Path $dest) { Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    & robocopy.exe (Join-Path $orig 'htdocs') (Join-Path $dest 'htdocs') /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    $bd = Join-Path $orig 'mysql\data'
    if (-not (Test-Path $bd)) { $bd = Join-Path $orig 'mysql-data' }
    if (Test-Path $bd) { & robocopy.exe $bd (Join-Path $dest 'mysql-data') /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null }
    foreach ($r in 'readme_en.txt', 'readme_de.txt') {
        if (Test-Path (Join-Path $orig $r)) { Copy-Item -LiteralPath (Join-Path $orig $r) -Destination $dest -Force }
    }
    $v = Versao-XamppEm $dest
    $semBd = if (Test-Path (Join-Path $dest 'mysql-data')) { '' } else { ' (sem os bancos: falta mysql\data)' }
    Log "XAMPP: htdocs e bancos de um XAMPP $v recém-instalado copiados do pendrive$semBd."
}

# Apaga o XAMPP antigo (versão diferente da do pendrive): para serviços e processos, roda o desinstalador e apaga C:\xampp
function Remover-XamppAntigo([string]$Ver) {
    $txt = if ($Ver -and $Ver -ne '?') { $Ver } else { 'de versão desconhecida' }
    Log "  XAMPP antigo ($txt) encontrado: vou apagá-lo para instalar o do pendrive." 'Yellow'
    foreach ($sv in @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { $_.PathName -like '*\xampp\*' })) {
        Stop-Service -Name $sv.Name -Force -ErrorAction SilentlyContinue
        & sc.exe delete $sv.Name | Out-Null
        Log "  Serviço $($sv.Name) do XAMPP antigo removido."
    }
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like 'C:\xampp\*' } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $un = 'C:\xampp\uninstall.exe'
    if (Test-Path $un) {
        try {
            $p = Start-Process -FilePath $un -ArgumentList '--mode unattended --unattendedmodeui none' -PassThru -WindowStyle Hidden
            if (-not $p.WaitForExit(600000)) { try { $p.Kill() } catch { } }
        } catch { }
        Start-Sleep -Seconds 3
    }
    Remove-Item -LiteralPath 'C:\xampp' -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path 'C:\xampp') {
        Log '  FALHA: não consegui apagar C:\xampp (algum arquivo em uso). Reinicie o PC e rode de novo.' 'Red'
        return $false
    }
    foreach ($pp in 'htdocs-padrao', 'mysql-data-padrao') {     # padrões do XAMPP antigo não servem mais
        $c = Join-Path $Base $pp
        if (Test-Path $c) { Remove-Item -LiteralPath $c -Recurse -Force -ErrorAction SilentlyContinue }
    }
    Log '  XAMPP antigo apagado.' 'Green'
    return $true
}

function Guardar-Pasta([string]$Origem, [string]$Destino) {
    if (-not (Test-Path $Origem)) { return }
    if (Test-Path $Destino) { Remove-Item -LiteralPath $Destino -Recurse -Force -ErrorAction SilentlyContinue }
    Copy-Item -LiteralPath $Origem -Destination $Destino -Recurse -Force
}

# htdocs e bancos do MySQL voltam ao padrão guardado no PC (o MySQL é fechado antes)
function Restaurar-Xampp {
    $htdocs = 'C:\xampp\htdocs';    $htPadrao = Join-Path $Base 'htdocs-padrao'
    $dados  = 'C:\xampp\mysql\data'; $bdPadrao = Join-Path $Base 'mysql-data-padrao'
    if ((Test-Path $htPadrao) -and (Test-Path $htdocs)) {
        Get-ChildItem -LiteralPath $htdocs -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -Path (Join-Path $htPadrao '*') -Destination $htdocs -Recurse -Force
    }
    if ((Test-Path $bdPadrao) -and (Test-Path $dados)) {
        Get-Process -Name mysqld -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Get-ChildItem -LiteralPath $dados -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -Path (Join-Path $bdPadrao '*') -Destination $dados -Recurse -Force
    }
}

# Define o padrão do XAMPP deste PC (PCs da conta Alunos com os programas do lab):
#  - instalado agora: o próprio XAMPP novo é o padrão;
#  - já existia (mesma versão) ou ainda sem padrão: o padrão de recém-instalado do pendrive, se for da mesma
#    versão; se não houver, a htdocs e os bancos atuais (com aviso).
function Padrao-Xampp {
    $htPadrao = Join-Path $Base 'htdocs-padrao'
    $bdPadrao = Join-Path $Base 'mysql-data-padrao'
    $penX     = Join-Path $Base 'xampp-pendrive'
    $verPC    = Versao-XamppPC
    $verPen   = if (Test-Path (Join-Path $penX 'htdocs')) { Versao-XamppEm $penX } else { $null }
    $penServe = [bool]($verPen -and $verPen -ne '?' -and $verPen -eq $verPC)
    Get-Process -Name mysqld -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    if ($XamppNovo) {
        Guardar-Pasta 'C:\xampp\htdocs' $htPadrao
        Guardar-Pasta 'C:\xampp\mysql\data' $bdPadrao
        Log "XAMPP $verPC recém-instalado: htdocs e bancos guardados como padrão; voltam a ele a cada logoff e desligamento dos alunos." 'Green'
    } elseif ($XamppVoltarPadrao -or -not (Test-Path $htPadrao) -or -not (Test-Path $bdPadrao)) {
        if ($penServe) {
            Guardar-Pasta (Join-Path $penX 'htdocs') $htPadrao
            if (Test-Path (Join-Path $penX 'mysql-data')) { Guardar-Pasta (Join-Path $penX 'mysql-data') $bdPadrao }
            Restaurar-Xampp
            Log "XAMPP $verPC`: htdocs e bancos voltaram ao padrão de recém-instalado (do pendrive); voltam a ele a cada logoff e desligamento dos alunos." 'Green'
        } else {
            $faltava = (-not (Test-Path $htPadrao)) -or (-not (Test-Path $bdPadrao))
            if (-not (Test-Path $htPadrao)) { Guardar-Pasta 'C:\xampp\htdocs' $htPadrao }
            if (-not (Test-Path $bdPadrao)) { Guardar-Pasta 'C:\xampp\mysql\data' $bdPadrao }
            if ($faltava) {
                $motivo = if (-not $verPen) { 'o pendrive não tem arquivos\xampp' } else { "o arquivos\xampp do pendrive é da versão $verPen" }
                Log "AVISO: XAMPP $verPC deste PC: $motivo. O que faltava do padrão (htdocs e/ou bancos) foi tirado do estado ATUAL deste PC." 'Yellow'
            } else {
                Restaurar-Xampp
                Log 'XAMPP: htdocs e bancos voltaram ao padrão já guardado neste PC.' 'Green'
            }
        }
    } else {
        Log 'XAMPP: padrão da htdocs e dos bancos já existe (mantido).'
    }
    if (Test-Path $penX) { Remove-Item -LiteralPath $penX -Recurse -Force -ErrorAction SilentlyContinue }
}

# ---- GLPI: agente de inventário
# Menu inicial 4 (GLPI): funciona em qualquer PC, configurado por este script ou não (aí pede só o campus).
#  Cenário 1: PC que já passou pelo script e precisa refazer o agente (servidor, etiqueta, reinstalar).
#  Cenário 2: PC em uso que não vai ser reconfigurado nem formatado: só instalar, configurar e rodar o agente.
# O agente guarda o servidor e a etiqueta no registro ($GlpiReg); o script também guarda o servidor no
# config.json (PCs configurados) e no pendrive (arquivos\campus\<SIGLA>.txt), para sugerir nos próximos PCs.
$GlpiBat = 'C:\Program Files\GLPI-Agent\glpi-agent.bat'
$GlpiReg = 'HKLM:\SOFTWARE\GLPI-Agent'

function Glpi-Servidor { return [string](Get-ItemProperty -Path $GlpiReg -ErrorAction SilentlyContinue).server }
function Glpi-Etiqueta { return [string](Get-ItemProperty -Path $GlpiReg -ErrorAction SilentlyContinue).tag }
# Servidor que vale para este PC: o do agente; se não houver, o das respostas do script
function Glpi-ServidorAtual {
    $s = Glpi-Servidor
    if (-not $s -and $Cfg) { $s = [string]$Cfg.Glpi }
    return $s
}
# Entrada do agente em "Programas instalados" (versão e desinstalação)
function Glpi-Desinstalador {
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        $e = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Where-Object { [string]$_.DisplayName -like 'GLPI Agent*' } | Select-Object -First 1
        if ($e) { return $e }
    }
    return $null
}
# Conecta numa porta TCP (até $Ms milissegundos). $true = respondeu.
function Testar-Porta([string]$Endereco, [int]$Porta, [int]$Ms = 1000) {
    $tc = New-Object Net.Sockets.TcpClient
    try {
        $ar = $tc.BeginConnect($Endereco, $Porta, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne($Ms)) { return $false }
        $tc.EndConnect($ar)
        return $true
    } catch { return $false }
    finally { $tc.Close() }
}
# O servidor GLPI responde? (conexão na porta do endereço: 80 no http, 443 no https). Mostra o resultado.
function Testar-ServidorGlpi([string]$Url = '') {
    if (-not $Url) { $Url = Glpi-ServidorAtual }
    if (-not $Url) { Write-Host '   GLPI: nenhum servidor informado neste PC.' -ForegroundColor Yellow; return $false }
    try { $u = [uri]$Url } catch { Write-Host "   GLPI: endereço inválido ($Url)." -ForegroundColor Red; return $false }
    $ok = Testar-Porta $u.Host $u.Port 3000
    if ($ok) { Write-Host ("   Servidor GLPI {0} (porta {1}): RESPONDE" -f $u.Host, $u.Port) -ForegroundColor Green }
    else     { Write-Host ("   Servidor GLPI {0} (porta {1}): NÃO RESPONDE (sem rede, servidor desligado ou outra VLAN sem acesso)" -f $u.Host, $u.Port) -ForegroundColor Red }
    return $ok
}

# Envia o inventário agora, se o servidor responder (espera até 2 min, sem janela). Usado no fim da instalação.
function Enviar-InventarioGlpi {
    if (-not (Test-Path $GlpiBat)) { return }
    $url = Glpi-ServidorAtual
    if (-not $url) { return }
    $srv = ''; $porta = 80
    try { $u = [uri]$url; $srv = $u.Host; $porta = $u.Port } catch { }
    if (-not $srv -or -not (Testar-Porta $srv $porta 3000)) {
        Log "GLPI: o servidor $srv não respondeu (sem rede?); o agente envia o inventário sozinho depois." 'Yellow'
        return
    }
    Write-Host '   Enviando o inventário ao GLPI (até 2 minutos)...'
    $p = Start-Process -FilePath $GlpiBat -ArgumentList '--force' -WindowStyle Hidden -PassThru
    if ($p.WaitForExit(120000) -and $p.ExitCode -eq 0) { Log "GLPI: inventário enviado ($srv; glpi-agent --force)." 'Green' }
    else { Log 'GLPI: o envio não terminou em 2 minutos ou deu erro; o agente tenta de novo sozinho (ou menu inicial 4 - GLPI > 3).' 'Yellow' }
}
# Envia o inventário mostrando o que o agente escreve (menu do GLPI)
function Enviar-InventarioAgora {
    if (-not (Test-Path $GlpiBat)) { Write-Host '   O agente GLPI não está instalado neste PC (use a opção 2).' -ForegroundColor Yellow; return }
    if (-not (Testar-ServidorGlpi)) {
        if (-not (Perguntar-SN 'O servidor não respondeu. Tentar enviar mesmo assim?')) { return }
    }
    Write-Host '   Enviando o inventário (o agente mostra o andamento abaixo)...' -ForegroundColor Cyan
    $p = Start-Process -FilePath $GlpiBat -ArgumentList '--force' -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0) { Registrar-Manutencao "Inventário enviado ao GLPI ($(Glpi-ServidorAtual); glpi-agent --force)" }
    else { Log "GLPI: o agente terminou com o código $($p.ExitCode) (glpi-agent --force). Veja as mensagens acima." 'Yellow' }
}

function Achar-MsiGlpi {
    $locais = @()
    $pd = Pasta-Pendrive
    if ($pd) { $locais += (Join-Path $pd 'softwares\basicos') }
    $locais += (Join-Path (Pasta-Sw) 'basicos')
    $locais += (Join-Path $Pen 'softwares\basicos')
    foreach ($l in @($locais | Select-Object -Unique)) {
        if (-not (Test-Path $l)) { continue }
        $m = Get-ChildItem -Path $l -File -Filter '*glpi*agent*.msi' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
        if ($m) { return $m.FullName }
    }
    return $null
}

# Etiqueta (TAG) do agente. PC configurado: a escolhida no menu do GLPI ou <SIGLA>-<local> (ex.: BRU-SALA1).
# PC não configurado: a que o agente já tem, ou a sigla do campus.
function Etiqueta-GlpiPadrao([string]$Sigla = '') {
    if ($Cfg) {
        if ([string]$Cfg.GlpiEtiqueta) { return [string]$Cfg.GlpiEtiqueta }
        return ('{0}-{1}' -f $Cfg.Sigla, $Cfg.Local)
    }
    $t = Glpi-Etiqueta
    if ($t) { return $t }
    return $Sigla
}

# Instala o agente com o servidor e a etiqueta. Se já estiver instalado, só troca o servidor e a etiqueta.
# Sem parâmetros: usa as respostas do script ($Cfg.Glpi e a etiqueta padrão).
function Instalar-AgenteGlpi([string]$Servidor = '', [string]$Tag = '') {
    if (-not $Servidor -and $Cfg) { $Servidor = [string]$Cfg.Glpi }
    if (-not $Servidor) { return $false }
    if (-not $Tag) { $Tag = Etiqueta-GlpiPadrao }
    if (Test-Path $GlpiBat) {
        if ((Glpi-Servidor) -eq $Servidor -and (Glpi-Etiqueta) -eq $Tag) {
            Log "  Agente GLPI já instalado, com o servidor $Servidor (etiqueta $Tag)." 'Green'; return $true
        }
        if (-not (Test-Path $GlpiReg)) { New-Item -Path $GlpiReg -Force | Out-Null }
        Set-ItemProperty -Path $GlpiReg -Name 'server' -Value $Servidor
        Set-ItemProperty -Path $GlpiReg -Name 'tag' -Value $Tag
        Restart-Service -Name 'glpi-agent' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $script:GlpiMudou = $true
        Log "  Agente GLPI já instalado: servidor $Servidor, etiqueta $Tag (registro $GlpiReg; serviço glpi-agent reiniciado)." 'Green'
        return $true
    }
    $msi = Achar-MsiGlpi
    if (-not $msi) {
        Log '  AVISO: instalador do agente GLPI (*glpi*agent*.msi) não encontrado em softwares\basicos. Conecte o pendrive e use o menu inicial 4 (GLPI).' 'Yellow'
        return $false
    }
    $arg = "/i `"$msi`" /quiet /norestart RUNNOW=1 EXECMODE=1 ADD_FIREWALL_EXCEPTION=1 SERVER=`"$Servidor`" TAG=`"$Tag`""
    Write-Host "   Instalando o agente GLPI ($([IO.Path]::GetFileName($msi))) ..."
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arg -PassThru -Wait
    Log-SoArquivo "GLPI: msiexec $arg"
    if ($p.ExitCode -in 0, 3010, 1641) {
        Log "  OK: agente GLPI instalado (servidor $Servidor, etiqueta $Tag)." 'Green'
        $script:GlpiMudou = $true
        return $true
    }
    Log "  FALHA: agente GLPI (código $($p.ExitCode); a linha de comando ficou no log)." 'Red'
    return $false
}

# Endereço do servidor GLPI: IP ou nome vira http://<ip>/front/inventory.php; ENTER = sugestão; 0 = voltar ($null)
function Ler-ServidorGlpi([string]$Sugestao) {
    if ($Sugestao) { Write-Host "  Sugestão: $Sugestao" -ForegroundColor Green }
    while ($true) {
        $txt = if ($Sugestao) { 'ENTER confirma, ou digite outro IP (0 = voltar)' } else { 'IP do servidor GLPI do campus (0 = voltar)' }
        $r = (Perguntar $txt).Trim()
        if ($r -eq '0') { return $null }
        if ($r -eq '') { if ($Sugestao) { return $Sugestao } else { continue } }
        if ($r -match '^https?://') { return $r }
        if ($r -match '^[A-Za-z0-9.-]+(:\d+)?$') { return "http://$r/front/inventory.php" }
        Write-Host '  Endereço inválido. Ex.: 192.168.1.189' -ForegroundColor Yellow
    }
}

# Sigla do campus (PC não configurado pelo script): ENTER = sugestão; 0 = voltar ($null)
function Ler-SiglaCampus([string]$Sugestao) {
    while ($true) {
        $txt = if ($Sugestao) { "Sigla do campus: $Sugestao   (ENTER confirma, ou digite outra; 0 = voltar)" } else { 'Sigla do campus (ex.: BRU, RCL; 0 = voltar)' }
        $r = (Perguntar $txt).Trim().ToUpper()
        if ($r -eq '0') { return $null }
        if ($r -eq '' -and $Sugestao) { return $Sugestao }
        if ($ListaCampi | Where-Object { $_.Split('|')[0] -eq $r }) { return $r }
        Write-Host '  Sigla não encontrada na lista de campi do IFSP. Tente de novo.' -ForegroundColor Yellow
    }
}
# Sigla para o GLPI: a das respostas do script; senão pergunta (sugestão: a do começo da etiqueta atual)
function Sigla-ParaGlpi {
    if ($Cfg -and $Cfg.Sigla) { return [string]$Cfg.Sigla }
    $sug = [string]$script:SiglaGlpi
    if (-not $sug -and (Glpi-Etiqueta) -match '^([A-Za-z]{3})') {
        $s = $Matches[1].ToUpper()
        if ($ListaCampi | Where-Object { $_.Split('|')[0] -eq $s }) { $sug = $s }
    }
    $r = Ler-SiglaCampus $sug
    if ($r) { $script:SiglaGlpi = $r }
    return $r
}
# Etiqueta digitada: ENTER = sugestão; 0 = voltar ($null)
function Ler-EtiquetaGlpi([string]$Sugestao) {
    while ($true) {
        $r = (Perguntar "Etiqueta do agente (TAG): $Sugestao   (ENTER confirma, ou digite outra; 0 = voltar)").Trim()
        if ($r -eq '0') { return $null }
        if ($r -eq '') { $r = $Sugestao }
        if ($r -match '^[A-Za-z0-9._-]{1,40}$') { return $r }
        Write-Host '  Etiqueta inválida: até 40 caracteres, só letras, números, ponto, hífen e sublinhado (ex.: BRU-CAP).' -ForegroundColor Yellow
    }
}
# PC não configurado pelo script: guarda só o servidor GLPI no arquivo do campus (pendrive e pasta do script)
function Gravar-GlpiNoCampus([string]$Sigla, [string]$Servidor) {
    $pd = Pasta-Pendrive
    foreach ($r in @($pd, $Pen) | Where-Object { $_ } | Select-Object -Unique) {
        try {
            $pasta = Join-Path $r 'arquivos\campus'
            $arq   = Join-Path $pasta "$Sigla.txt"
            New-Item -ItemType Directory -Path $pasta -Force | Out-Null
            $linhas = @()
            if (Test-Path $arq) { $linhas = @([IO.File]::ReadAllLines($arq) | Where-Object { $_ -notmatch '^\s*Glpi\s*=' }) }
            else { $linhas = @("# Dados do campus $Sigla, gravados pelo manutencao.ps1 (menu do GLPI) em $(Get-Date -Format 'dd/MM/yyyy HH:mm').") }
            $linhas += "Glpi = $Servidor"
            [IO.File]::WriteAllLines($arq, [string[]]$linhas, (New-Object System.Text.UTF8Encoding($true)))
        } catch { }
    }
}
# Pasta de logs num PC que não foi configurado pelo script (para o menu do GLPI registrar o que fez)
function Garantir-PastaLogs {
    if (Test-Path $PastaLogs) { return }
    try {
        if (-not (Test-Path $Base)) {
            New-Item -ItemType Directory -Path $Base -Force | Out-Null
            & icacls.exe $Base /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
        }
        New-Item -ItemType Directory -Path $PastaLogs -Force | Out-Null
    } catch { }
}

function Mostrar-SituacaoGlpi([bool]$Completa) {
    $inst = Test-Path $GlpiBat
    $des  = Glpi-Desinstalador
    $txtAg = if ($inst) { 'instalado' + $(if ($des.DisplayVersion) { " (versão $($des.DisplayVersion))" } else { '' }) } else { 'NÃO instalado' }
    Write-Host ('   Agente GLPI ............ {0}' -f $txtAg) -ForegroundColor $(if ($inst) { 'Green' } else { 'Yellow' })
    if ($inst) {
        $s = Get-Service -Name 'glpi-agent' -ErrorAction SilentlyContinue
        $txtS = if (-not $s) { 'não encontrado' } elseif ($s.Status -eq 'Running') { 'rodando' } else { "parado ($($s.Status))" }
        Write-Host ('   Serviço glpi-agent ..... {0}' -f $txtS) -ForegroundColor $(if ($s -and $s.Status -eq 'Running') { 'Green' } else { 'Yellow' })
        Write-Host ('   Servidor do agente ..... {0}' -f $(if (Glpi-Servidor) { Glpi-Servidor } else { '(nenhum)' }))
        Write-Host ('   Etiqueta (TAG) ......... {0}' -f $(if (Glpi-Etiqueta) { Glpi-Etiqueta } else { '(nenhuma)' }))
    }
    if ($Cfg) {
        Write-Host ('   Respostas do script .... {0} ({1}); GLPI: {2}' -f $Cfg.NomePC, $Cfg.Tipo, $(if ($Cfg.Glpi) { $Cfg.Glpi } else { '(sem GLPI)' })) -ForegroundColor DarkGray
    } else {
        Write-Host '   Este PC não foi configurado por este script: o menu do GLPI pede só o campus.' -ForegroundColor DarkGray
    }
    if ($Completa) {
        Write-Host ''
        [void](Testar-ServidorGlpi)
        $u = Glpi-ServidorAtual
        if ($u -and (Glpi-Servidor) -and $Cfg -and $Cfg.Glpi -and $Cfg.Glpi -ne (Glpi-Servidor)) {
            Write-Host "   ATENÇÃO: o agente usa $(Glpi-Servidor), mas as respostas do script dizem $($Cfg.Glpi). Use a opção 2 para acertar." -ForegroundColor Yellow
        }
    }
}

# Menu inicial 4: GLPI
function Menu-GlpiInicial {
    $script:Cfg = $null
    if (Test-Path $ArqConfig) {
        try { $script:Cfg = Get-Content $ArqConfig -Raw -Encoding UTF8 | ConvertFrom-Json; Completar-Cfg } catch { $script:Cfg = $null }
    }
    Garantir-PastaLogs
    $corG = $CoresArea.Glpi
    $faixaG = 'GLPI - AGENTE DE INVENTÁRIO'
    while ($true) {
        Mostrar-Cabecalho $faixaG $corG
        Mostrar-SituacaoGlpi $false
        Write-Host ''
        Write-Host '   1 - Situação do agente (versão, serviço, servidor, etiqueta; testa se o servidor responde)'
        Write-Host '   2 - Informar o servidor e instalar o agente (ou trocar o servidor)'
        Write-Host '   3 - Enviar o inventário agora'
        Write-Host '   4 - Trocar a etiqueta (TAG)'
        Write-Host '   5 - Abrir o GLPI no navegador'
        Write-Host '   6 - Desinstalar o agente'
        $script:SemPausa = $false
        $op = Ler-Opcao 6
        if ($op -eq 0) { $script:CorArea = 'Cyan'; return }
        Mostrar-Cabecalho $faixaG $corG            # cada opção começa numa tela limpa
        try {
            switch ($op) {
                1 { Titulo 'Situação do agente GLPI'; Mostrar-SituacaoGlpi $true }
                2 {
                    Titulo 'Informar o servidor e instalar o agente'
                    $sig = Sigla-ParaGlpi
                    if (-not $sig) { $script:SemPausa = $true; break }
                    $dc  = Ler-DadosCampus $sig
                    $sug = ''
                    if ($Cfg -and $Cfg.Glpi) { $sug = [string]$Cfg.Glpi } elseif (Glpi-Servidor) { $sug = Glpi-Servidor } elseif ($dc.Glpi) { $sug = [string]$dc.Glpi }
                    $srv = Ler-ServidorGlpi $sug
                    if (-not $srv) { $script:SemPausa = $true; break }
                    $tag = Ler-EtiquetaGlpi (Etiqueta-GlpiPadrao $sig)
                    if (-not $tag) { $script:SemPausa = $true; break }
                    if ($Cfg) {
                        Definir-CampoCfg 'Glpi' $srv
                        if ($tag -ne ('{0}-{1}' -f $Cfg.Sigla, $Cfg.Local)) { Definir-CampoCfg 'GlpiEtiqueta' $tag } else { Definir-CampoCfg 'GlpiEtiqueta' '' }
                        Salvar-Config
                        Gravar-DadosCampus                      # pendrive: sugerido nos outros PCs do campus
                    } else {
                        Gravar-GlpiNoCampus $sig $srv
                    }
                    if (Pasta-Pendrive) { Write-Host "   Servidor gravado no pendrive (arquivos\campus\$sig.txt): será sugerido nos outros PCs do campus." -ForegroundColor Green }
                    else { Write-Host '   Pendrive não conectado: o servidor ficou só neste PC (e na pasta do script).' -ForegroundColor Yellow }
                    if (Instalar-AgenteGlpi $srv $tag) {
                        Registrar-Manutencao "GLPI: servidor $srv, etiqueta $tag; agente instalado ou ajustado"
                        if (Perguntar-SN 'Enviar o inventário agora? (precisa de rede)') { Enviar-InventarioAgora }
                    }
                }
                3 { Titulo 'Enviar o inventário agora'; Enviar-InventarioAgora }
                4 {
                    Titulo 'Trocar a etiqueta (TAG)'
                    if (-not (Test-Path $GlpiBat)) { Write-Host '   O agente GLPI não está instalado neste PC (use a opção 2).' -ForegroundColor Yellow; break }
                    $sug = Glpi-Etiqueta
                    if (-not $sug) { $sig = Sigla-ParaGlpi; if (-not $sig) { $script:SemPausa = $true; break }; $sug = Etiqueta-GlpiPadrao $sig }
                    $tag = Ler-EtiquetaGlpi $sug
                    if (-not $tag) { $script:SemPausa = $true; break }
                    if (-not (Test-Path $GlpiReg)) { New-Item -Path $GlpiReg -Force | Out-Null }
                    Set-ItemProperty -Path $GlpiReg -Name 'tag' -Value $tag
                    Restart-Service -Name 'glpi-agent' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if ($Cfg) {
                        if ($tag -ne ('{0}-{1}' -f $Cfg.Sigla, $Cfg.Local)) { Definir-CampoCfg 'GlpiEtiqueta' $tag } else { Definir-CampoCfg 'GlpiEtiqueta' '' }
                        Salvar-Config
                    }
                    Registrar-Manutencao "GLPI: etiqueta trocada para $tag (registro $GlpiReg\tag; serviço glpi-agent reiniciado)"
                    if (Perguntar-SN 'Enviar o inventário agora, com a etiqueta nova?') { Enviar-InventarioAgora }
                }
                5 {
                    Titulo 'Abrir o GLPI no navegador'
                    $url = Glpi-ServidorAtual
                    if (-not $url) { Write-Host '   Nenhum servidor GLPI informado neste PC (use a opção 2).' -ForegroundColor Yellow; break }
                    try { $u = [uri]$url; $abrir = '{0}://{1}/' -f $u.Scheme, $u.Authority } catch { $abrir = $url }
                    Write-Host "   Abrindo $abrir ..." -ForegroundColor Cyan
                    # direto no Chrome ou no Edge (sem depender do navegador padrão, que pode nem estar escolhido)
                    $nav = @('C:\Program Files\Google\Chrome\Application\chrome.exe', 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
                             'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe', 'C:\Program Files\Microsoft\Edge\Application\msedge.exe') |
                           Where-Object { Test-Path $_ } | Select-Object -First 1
                    if ($nav) { Start-Process -FilePath $nav -ArgumentList '--start-maximized', $abrir } else { Start-Process $abrir }
                    $script:SemPausa = $true
                }
                6 {
                    Titulo 'Desinstalar o agente'
                    $des = Glpi-Desinstalador
                    if (-not $des -and -not (Test-Path $GlpiBat)) { Write-Host '   O agente GLPI não está instalado neste PC.' -ForegroundColor Yellow; break }
                    $cod = [string]$des.PSChildName
                    if ($cod -notmatch '^\{[0-9A-Fa-f-]+\}$') { Write-Host '   Não achei o código de desinstalação do agente. Desinstale pelo Painel de Controle > Programas.' -ForegroundColor Yellow; break }
                    Write-Host '   O PC deixa de mandar inventário. O computador continua no GLPI (apague lá, se quiser).' -ForegroundColor Yellow
                    if (-not (Perguntar-SN "Desinstalar o agente GLPI ($($des.DisplayName))?")) { break }
                    $arg = "/x $cod /qn /norestart"
                    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arg -PassThru -Wait
                    if ($p.ExitCode -in 0, 3010, 1641) {
                        Registrar-Manutencao "GLPI: agente desinstalado (msiexec $arg)"
                        if ($Cfg -and $Cfg.Glpi) {
                            Write-Host '   As respostas do script ainda têm o GLPI: no Reaplicar, o agente seria instalado de novo.' -ForegroundColor DarkGray
                            if (Perguntar-SN 'Tirar o GLPI das respostas deste PC também?') {
                                Definir-CampoCfg 'Glpi' ''; Definir-CampoCfg 'GlpiEtiqueta' ''; Salvar-Config
                                Registrar-Manutencao 'GLPI tirado das respostas deste PC (config.json)'
                            }
                        }
                    } else { Log "FALHA ao desinstalar o agente GLPI (código $($p.ExitCode); msiexec $arg)." 'Red' }
                }
            }
        } catch {
            Write-Host "   ERRO: $($_.Exception.Message)" -ForegroundColor Red
        }
        if (-not $script:SemPausa) { Pausa }
    }
}

function Instalar-Programas([string]$Pasta, [string]$Rotulo) {
    $caminho = Join-Path (Pasta-Sw) $Pasta
    if (-not (Test-Path $caminho)) { Log "Pasta softwares\$Pasta não encontrada; nada a instalar." 'Yellow'; return }
    $arquivos = @(Get-ChildItem -Path $caminho -File | Where-Object { $_.Extension -in '.msi', '.exe' } |
                  Sort-Object @{ Expression = { if ($_.Name -like 'vc_redist*') { 0 } else { 1 } } }, Name)   # Visual C++ primeiro
    if ($arquivos.Count -eq 0) { Log "Pasta softwares\$Pasta está vazia." 'Yellow'; return }
    $params = Ler-Parametros
    Log "Programas $Rotulo ($($arquivos.Count) arquivo(s)):" 'Cyan'

    foreach ($f in $arquivos) {
        $nome = $f.Name.ToLower()
        if ($nome -like 'veyon*') { continue }      # o Veyon é instalado na etapa própria (cliente ou professor)
        if (@($Prog.Pular) -contains $f.Name) { Log "  $($f.Name): pulado (escolha do operador)." 'DarkGray'; continue }
        $ehGlpi = $nome -like '*glpi*agent*'
        if ($ehGlpi -and -not $Cfg.Glpi) { Log "  $($f.Name): pulado (campus sem GLPI)." 'DarkGray'; continue }
        if ($ehGlpi) { [void](Instalar-AgenteGlpi); continue }

        $exe = $null; $arg = $null
        if ($params.ContainsKey($nome)) {
            if ($f.Extension -eq '.msi') { $exe = 'msiexec.exe'; $arg = "/i `"$($f.FullName)`" $($params[$nome])" }
            else                         { $exe = $f.FullName;  $arg = $params[$nome] }
        } elseif ($ehGlpi -and $f.Extension -eq '.msi') {
            $tag = '{0}-{1}' -f $Cfg.Sigla, $Cfg.Local
            $exe = 'msiexec.exe'
            $arg = "/i `"$($f.FullName)`" /quiet /norestart RUNNOW=1 EXECMODE=1 ADD_FIREWALL_EXCEPTION=1 SERVER=`"$($Cfg.Glpi)`" TAG=`"$tag`""
        } elseif ($f.Extension -eq '.msi') {
            $exe = 'msiexec.exe'; $arg = "/i `"$($f.FullName)`" /qn /norestart ALLUSERS=1"
        } else {
            foreach ($padrao in $ParamsConhecidos.Keys) {
                if ($nome -like $padrao) { $exe = $f.FullName; $arg = $ParamsConhecidos[$padrao]; break }
            }
        }
        if (-not $exe -and $f.Extension -eq '.exe') {
            $tipoExe = Tipo-Instalador $f.FullName
            if ($tipoExe -eq 'INNO')     { $exe = $f.FullName; $arg = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /ALLUSERS' }
            elseif ($tipoExe -eq 'NSIS') { $exe = $f.FullName; $arg = '/S' }
        }
        if (-not $exe) {
            Log "  AVISO: não sei instalar $($f.Name) sem janelas. Coloque os parâmetros em softwares\parametros.txt." 'Yellow'
            continue
        }

        if ($nome -like 'xampp*') {
            # XAMPP que já existe: mesma versão = não reinstala (só volta ao padrão); outra = apaga o antigo
            $vn = Versao-DoNome $f.Name
            $vp = Versao-XamppPC
            if ($vp) {
                if ($vp -eq $vn) {
                    Log "  $($f.Name): o XAMPP $vp já está instalado; não reinstalo (htdocs e bancos voltam ao padrão)." 'Green'
                    $script:XamppVoltarPadrao = $true
                    continue
                }
                if (-not (Remover-XamppAntigo $vp)) { continue }
            }
        }
        Write-Host "   Instalando $($f.Name) ..." -NoNewline
        $codigo = $null
        for ($tentativa = 1; $tentativa -le 2; $tentativa++) {
            try {
                if ($arg) { $p = Start-Process -FilePath $exe -ArgumentList $arg -PassThru -WindowStyle Hidden }
                else      { $p = Start-Process -FilePath $exe -PassThru -WindowStyle Hidden }
                if (-not $p.WaitForExit(1200000)) { $codigo = 'TEMPO'; break }    # até 20 minutos
                $codigo = $p.ExitCode
            } catch { $codigo = $_.Exception.Message; break }
            if ($codigo -eq 1618) { Start-Sleep -Seconds 60; continue }        # outra instalação em andamento
            break
        }
        Write-Host ''
        if ($codigo -in 0, 3010, 1641, 1638) {
            Log "  OK: $($f.Name)" 'Green'
            if ($codigo -in 3010, 1641) { $script:PrecisaReiniciar = $true }
            if ($nome -like 'xampp*' -and (Test-Path 'C:\xampp\htdocs')) { $script:XamppNovo = $true }
        } elseif ($codigo -eq 'TEMPO') {
            Log "  AVISO: $($f.Name) passou de 20 minutos; segui adiante (confira depois)." 'Yellow'
        } elseif ($nome -like '*chrome*' -and $codigo -eq 1603 -and (Test-Path 'C:\Program Files\Google\Chrome\Application\chrome.exe')) {
            # o .msi do Chrome não instala por cima de um Chrome mais novo (ele se atualiza sozinho)
            $vChrome = (Get-Item 'C:\Program Files\Google\Chrome\Application\chrome.exe').VersionInfo.ProductVersion
            Log "  OK: Chrome já instalado (versão $vChrome, mais nova que a do pendrive)." 'Green'
        } else {
            Log "  FALHA: $($f.Name) (código $codigo)" 'Red'
        }
    }
}

function Atalho-MenuIniciar([string]$Padrao) {
    $l = Get-ChildItem 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs' -Recurse -Filter $Padrao -ErrorAction SilentlyContinue |
         Select-Object -First 1
    if ($l) { return $l.FullName }
    return $null
}

# ---------------------------------------------------------------
#  Manutenção (computador já configurado)
# ---------------------------------------------------------------
function Registrar-Manutencao([string]$Msg) {
    try { Write-EventLog -LogName Application -Source 'IFSP' -EventId 1006 -EntryType Information -Message $Msg } catch { }
    Log $Msg
}

function Texto-Horarios($h) {
    if (-not $h -or -not $h.Ativo) { return 'Desligamento automático: não se aplica a este PC.' }
    $t = "Desligar às $($h.Desligar) (aviso $($h.AvisoMin) min, adiar $($h.AdiarMin) min; com a CTI logada não desliga)"
    if ($h.Teste) { $t = "MODO DE TESTE até $($h.TesteAte) | $t" }
    if ([string]$h.PausadoAte -like '9999*') { return "Desligamento automático: DESATIVADO PERMANENTEMENTE (Manutenção > Horários > 2 reativa) | $t" }
    if ($h.PausadoAte -and ((Get-Date) -lt [datetime]$h.PausadoAte)) { $t = "PAUSADO até $($h.PausadoAte) | $t" }
    return $t
}

# Desligamento às 23:30: só nos tipos de PC da lista $TiposComDesligamento
function Tem-Horario($c) {
    return (([string]$c.Tipo -in $TiposComDesligamento) -and ((Espaco-DoCfg $c) -notin $EspacosSemDesligamento))
}
# Tipo de espaço do PC (LAB, SALA, PROF, CIE, AUD, CBI, ADM, CTI, OUTRO). Respostas de até a v3.10 não têm o
# campo: ele sai do tipo e do local.
function Espaco-DoCfg($c) {
    if ($c.PSObject.Properties.Name -contains 'Espaco' -and $c.Espaco) { return [string]$c.Espaco }
    $t = [string]$c.Tipo; $l = [string]$c.Local
    if ($t -like 'LAB-*')        { return 'LAB' }
    if ($l -match '^SALA\d+$')   { return 'SALA' }
    if ($l -in 'BIBL', 'CBI')    { return 'CBI' }
    if ($l -in 'PROF', 'CIE', 'AUD') { return $l }
    if ($t -eq 'CTI')            { return 'CTI' }
    if ($t -eq 'OUTRO')          { return 'ADM' }
    return 'OUTRO'
}

function Horarios-Normais {
    $n = [pscustomobject]$HorariosPadrao
    $n.Ativo = (Tem-Horario $Cfg)
    $Cfg.PSObject.Properties.Remove('Horarios')
    $Cfg | Add-Member -NotePropertyName Horarios -NotePropertyValue $n
}

function Limpar-EstadoHorarios {
    foreach ($a in 'horarios.json', 'adiar.txt') {
        Remove-Item (Join-Path $Base "estado\$a") -Force -ErrorAction SilentlyContinue
    }
}

# Lê as respostas guardadas (config.json) para a Manutenção e o menu do Veyon. Devolve $false se o PC
# ainda não foi configurado por este script.
function Carregar-Cfg {
    if (-not (Test-Path $ArqConfig)) {
        Write-Host '  Este computador ainda não foi configurado por este script. Escolha a opção 1 (Instalar).' -ForegroundColor Yellow
        return $false
    }
    $script:Cfg = Get-Content $ArqConfig -Raw -Encoding UTF8 | ConvertFrom-Json
    Completar-Cfg
    return $true
}

# Submenus: mostra "0 - Voltar" como última opção e lê a escolha (0 = voltar, sem pausa depois)
function Ler-Opcao([int]$Max) {
    Write-Host '   0 - Voltar'
    $op = Ler-Numero "Escolha (0 a $Max)" 0 $Max
    if ($op -eq 0) { $script:SemPausa = $true }
    return $op
}

# Pasta ManutencaoIFSP no PENDRIVE (para o que vai de um PC a outro: dados do campus, chaves do Veyon, lista de PCs).
# Se o script roda do pendrive, é a própria pasta dele. Se roda de uma cópia no PC, procura nos pendrives.
function Pasta-Pendrive {
    $discos = @(Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue)
    $letraPen = try { (Split-Path $Pen -Qualifier).ToUpper() } catch { '' }
    if ($discos | Where-Object { $_.DeviceID -eq $letraPen -and $_.DriveType -eq 2 }) { return $Pen }
    $sistema = $env:SystemDrive.ToUpper()
    foreach ($tipo in 2, 3) {          # 2 = removível (pendrive); 3 = disco (alguns HDs/SSDs USB aparecem assim)
        foreach ($d in ($discos | Where-Object { $_.DriveType -eq $tipo -and $_.DeviceID -ne $sistema } | Sort-Object DeviceID)) {
            foreach ($nomePasta in 'ManutencaoIFSP', 'InstaladorIFSP') {      # InstaladorIFSP = nome antigo
                $p = Join-Path ($d.DeviceID + '\') $nomePasta
                if (Test-Path $p) { return $p }
            }
        }
    }
    return $null
}

# Versões anteriores (v3.1/v3.2) faziam logoff e desligamento por falta de uso. Se os scripts antigos
# ainda estiverem no PC, desliga essas partes neles (os novos só são gravados ao instalar ou reaplicar).
# Precisa rodar ANTES de gravar o config.json novo (que não tem mais esses tempos).
function Atualizar-ScriptsAntigos {
    $trocas = @(
        @('agente-usuario.ps1', 'if (-not $pausado -and -not $ehCTI) {',            'if ($false) {   # v3.3: sem logoff por inatividade'),
        @('sistema.ps1',        'if ($semUso -ge [int]$h.DesligarOciosoMin) {',      'if ($false) {   # v3.3: sem desligamento por falta de uso')
    )
    foreach ($t in $trocas) {
        $arq = Join-Path $Base $t[0]
        if (-not (Test-Path $arq)) { continue }
        $txt = [IO.File]::ReadAllText($arq)
        if ($txt.Contains($t[1])) {
            [IO.File]::WriteAllText($arq, $txt.Replace($t[1], $t[2]), (New-Object System.Text.UTF8Encoding($true)))
            Log "Script antigo ajustado: $($t[0]) (sem logoff/desligamento por falta de uso)."
        }
    }
}

function Definir-CampoCfg([string]$Nome, $Valor) {
    if ($Cfg.PSObject.Properties.Name -contains $Nome) { $Cfg.$Nome = $Valor }
    else { $Cfg | Add-Member -NotePropertyName $Nome -NotePropertyValue $Valor }
}

# Marcadores tirados do tipo do PC (gravados no config.json; os scripts de logon e do sistema usam):
#   LabInfo       programas do lab: labs de informática e PCs de alunos com "Programas: Lab de informática"
#                 (programas do lab, VS Code, firewall, htdocs). As regras do pop-up e a seção do Veyon seguem o LUGAR.
#   Compartilhado PC de uso compartilhado (labs, USO-PROF, USO-ALUNO): navegador anônimo, limpeza das pastas,
#                 Pasta Segura opcional, barra fixa, senha só pela CTI
#   ContaAlunos   conta Alunos (LAB-ALUNO, USO-ALUNO): pop-up de regras, sem impressão, sem Configurações
function Completar-Cfg {
    $t = [string]$Cfg.Tipo
    if (-not ($Cfg.PSObject.Properties.Name -contains 'ProgramasLab')) { Definir-CampoCfg 'ProgramasLab' ($t -like 'LAB-*') }
    if (-not ($Cfg.PSObject.Properties.Name -contains 'Espaco') -or -not $Cfg.Espaco) { Definir-CampoCfg 'Espaco' (Espaco-DoCfg $Cfg) }
    if (-not ($Cfg.PSObject.Properties.Name -contains 'Bloco')) { Definir-CampoCfg 'Bloco' '' }
    # programas do lab: labs de informática e PCs de professores/alunos com "Programas: lab de informática"
    Definir-CampoCfg 'LabInfo'       (($t -like 'LAB-*') -or ($t -in 'USO-ALUNO', 'USO-PROF' -and [bool]$Cfg.ProgramasLab))
    Definir-CampoCfg 'Compartilhado' ($t -in 'LAB-ALUNO', 'LAB-PROF', 'USO-PROF', 'USO-ALUNO')
    Definir-CampoCfg 'ContaAlunos'   ($t -in 'LAB-ALUNO', 'USO-ALUNO')
    if (-not ($Cfg.PSObject.Properties.Name -contains 'PastaSegura')) { Definir-CampoCfg 'PastaSegura' ($t -eq 'LAB-PROF') }   # até a v3.3: só o professor
    if (-not $Cfg.Compartilhado) { $Cfg.PastaSegura = $false }
    # Bloqueios (Manutenção > Bloqueios). Até a v3.8 eram "travas": TravasAtivas/TravasDesligadasAte e PapelTravado.
    $nomesCfg = $Cfg.PSObject.Properties.Name
    if (($nomesCfg -contains 'TravasAtivas') -and -not ($nomesCfg -contains 'BloqueioConfiguracoes')) {
        Definir-CampoCfg 'BloqueioConfiguracoes'    ([bool]$Cfg.TravasAtivas -or -not $Cfg.ContaAlunos)
        Definir-CampoCfg 'BloqueioConfiguracoesAte' ([string]$Cfg.TravasDesligadasAte)
    }
    if (($nomesCfg -contains 'PapelTravado') -and -not ($nomesCfg -contains 'BloqueioPapel')) {
        Definir-CampoCfg 'BloqueioPapel' ($Cfg.PapelTravado -ne $false)
    }
    foreach ($b in $Bloqueios) {
        $n = $b.Split('|')[0]
        if (-not ($Cfg.PSObject.Properties.Name -contains "Bloqueio$n"))      { Definir-CampoCfg "Bloqueio$n" $true }
        if (-not ($Cfg.PSObject.Properties.Name -contains "Bloqueio${n}Ate")) { Definir-CampoCfg "Bloqueio${n}Ate" '' }
    }
    if (-not ($Cfg.PSObject.Properties.Name -contains 'VeyonCentral')) { Definir-CampoCfg 'VeyonCentral' $false }
    if (-not ($Cfg.PSObject.Properties.Name -contains 'Moodle')) {      # respostas de versão anterior
        $m = ''
        if (($t -like 'LAB-*' -or [string]$Cfg.Local -like 'CIE*') -and $MoodleCampi.ContainsKey([string]$Cfg.Sigla)) { $m = $MoodleCampi[[string]$Cfg.Sigla] }
        Definir-CampoCfg 'Moodle' $m
    }
}

# A conta tem senha? $true / $false ($null se não deu para saber). Testa um logon com senha em branco.
function Conta-TemSenha([string]$Nome) {
    if (-not ('IFSPInst.Logon' -as [type])) {
        Add-Type -Namespace IFSPInst -Name Logon -MemberDefinition @'
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool LogonUser(string user, string domain, string pass, int type, int provider, out System.IntPtr token);
[DllImport("kernel32.dll")]
public static extern bool CloseHandle(System.IntPtr h);
'@
    }
    $tok = [IntPtr]::Zero
    $ok  = [IFSPInst.Logon]::LogonUser($Nome, '.', '', 2, 0, [ref]$tok)
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($ok) { [void][IFSPInst.Logon]::CloseHandle($tok); return $false }
    if ($err -eq 1327) { return $false }     # senha em branco (restrição do Windows): está sem senha
    if ($err -eq 1326) { return $true }      # senha incorreta: a conta tem senha
    return $null
}

# Logon automático na conta de uso: ligado só se a conta estiver sem senha (com senha, sempre pede a senha)
function Definir-Autologon([bool]$Ligado) {
    $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    if ($Ligado) {
        New-ItemProperty -Path $wl -Name AutoAdminLogon    -Value '1'          -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $wl -Name DefaultUserName   -Value $Cfg.Usuario -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $wl -Name DefaultDomainName -Value $Cfg.NomePC  -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $wl -Name DefaultPassword   -Value ''           -PropertyType String -Force | Out-Null
        Remove-ItemProperty -Path $wl -Name AutoLogonCount -ErrorAction SilentlyContinue
    } else {
        New-ItemProperty -Path $wl -Name AutoAdminLogon    -Value '0'          -PropertyType String -Force | Out-Null
        Remove-ItemProperty -Path $wl -Name DefaultPassword -ErrorAction SilentlyContinue
    }
}

# Executa $Acao no registro (HKCU) de UMA conta (sem mexer no perfil padrão). Devolve $true se aplicou.
function Para-Conta([string]$Nome, [scriptblock]$Acao) {
    $u = Get-LocalUser -Name $Nome -ErrorAction SilentlyContinue
    $perf = Perfil-DaConta $u
    if (-not $perf) { return $false }
    $sid = $u.SID.Value
    if (Test-Path "Registry::HKEY_USERS\$sid") { & $Acao "Registry::HKEY_USERS\$sid" | Out-Null; return $true }
    $dat = Join-Path $perf.LocalPath 'NTUSER.DAT'
    if (-not (Test-Path $dat)) { return $false }
    & reg.exe load 'HKU\IFSPTmp' $dat | Out-Null
    if ($LASTEXITCODE -ne 0) { return $false }
    try     { & $Acao 'Registry::HKEY_USERS\IFSPTmp' | Out-Null }
    finally {
        [gc]::Collect(); [gc]::WaitForPendingFinalizers(); Start-Sleep -Seconds 1
        & reg.exe unload 'HKU\IFSPTmp' | Out-Null
    }
    return $true
}

# ---------------------------------------------------------------
#  Bloqueios (Manutenção > Bloqueios). A CTI nunca é bloqueada.
#  No config.json, cada bloqueio tem dois campos:
#    Bloqueio<Nome>     true = bloqueado; false = desbloqueado permanentemente (não recomendado)
#    Bloqueio<Nome>Ate  desbloqueado até esta data/hora; depois volta a bloquear sozinho
#  A tarefa do sistema (a cada logon e a cada 5 min) aplica o que estiver valendo.
# ---------------------------------------------------------------
# Domínio (UCS ou Active Directory): DNS secundário das placas quando o PC usa o servidor do domínio como DNS
# (reserva da internet se o servidor cair). Se os logins do domínio falharem às vezes, deixe '' (só o servidor).
$DnsSecundarioDominio = '8.8.8.8'

$Bloqueios = @(
    'Configuracoes|Configurações, Painel de Controle e Editor do Registro (conta Alunos)'
    'Impressao|Impressão nas impressoras do campus; adicionar ou remover impressoras (conta Alunos; PDF liberado)'
    'Navegador|Chrome anônimo e Edge InPrivate, sem login, sincronização nem senhas salvas'
    'Barra|Barra de tarefas fixa (não dá para fixar nem desafixar)'
    'Papel|Papel de parede (só a CTI troca)'
    'Xampp|XAMPP volta ao padrão (htdocs e bancos) ao sair e ao desligar (desbloqueado = os sites e bancos ficam)'
)
# Bloqueios que existem neste tipo de PC
function Bloqueios-DoPC {
    $l = @()
    if ($Cfg.ContaAlunos)     { $l += 'Configuracoes', 'Impressao' }
    if ($Cfg.Compartilhado)   { $l += 'Navegador', 'Barra' }
    if ($Cfg.Tipo -ne 'CTI')  { $l += 'Papel' }
    if ($Cfg.ContaAlunos -and $Cfg.LabInfo -and (Test-Path 'C:\xampp\htdocs')) { $l += 'Xampp' }
    return $l
}
function Desc-Bloqueio([string]$Nome) {
    foreach ($b in $Bloqueios) { $p = $b.Split('|'); if ($p[0] -eq $Nome) { return $p[1] } }
    return $Nome
}
# Bloqueado agora? (campo que não existe = bloqueado)
function Bloqueio-Ativo([string]$Nome) {
    $v = $Cfg."Bloqueio$Nome"
    if ($null -ne $v -and -not [bool]$v) { return $false }
    $ate = [string]$Cfg."Bloqueio${Nome}Ate"
    if ($ate -and ((Get-Date) -lt [datetime]$ate)) { return $false }
    return $true
}
function Texto-Bloqueio([string]$Nome) {
    $v = $Cfg."Bloqueio$Nome"
    if ($null -ne $v -and -not [bool]$v) { return 'DESBLOQUEADO (permanente)' }
    $ate = [string]$Cfg."Bloqueio${Nome}Ate"
    if ($ate -and ((Get-Date) -lt [datetime]$ate)) { return "DESBLOQUEADO até $ate" }
    return 'BLOQUEADO'
}
function Cor-Bloqueio([string]$Nome) { if (Bloqueio-Ativo $Nome) { return 'Red' } return 'Green' }

# Configurações/Painel de Controle e Editor do Registro na conta Alunos
function Aplicar-BloqueioConfiguracoes([bool]$Ativo) {
    $script:bloqAgora = $Ativo
    $ok = Para-Conta $ContaAluno {
        param($hive)
        $kE = "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        $kS = "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        if ($script:bloqAgora) { Definir-Reg $kE 'NoControlPanel' 1; Definir-Reg $kS 'DisableRegistryTools' 1 }
        else { Apagar-Reg $kE @('NoControlPanel'); Apagar-Reg $kS @('DisableRegistryTools') }
    }
    if (-not $ok) { Log 'Bloqueios: a conta Alunos ainda não tem perfil; valem a partir do primeiro logon dela.' }
}

# Adicionar/remover impressoras na conta Alunos (o "não imprimir" nas impressoras é da tarefa do sistema)
function Aplicar-BloqueioImpressao([bool]$Ativo) {
    $script:bloqAgora = $Ativo
    $acao = {
        param($hive)
        $k = "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if ($script:bloqAgora) { Definir-Reg $k 'NoAddPrinter' 1; Definir-Reg $k 'NoDeletePrinter' 1 }
        else { Apagar-Reg $k @('NoAddPrinter', 'NoDeletePrinter') }
    }
    if ($Cfg.Usuario -eq $ContaAluno) { Para-CadaPerfil $acao } else { $null = Para-Conta $ContaAluno $acao }
}

# Barra de tarefas fixa. Duas partes (valem no próximo logon de cada conta):
#  - máquina: a barra padrão do IFSP (barra-tarefas.xml) para contas novas;
#  - cada conta, menos a CTI: "Não permitir fixar programas na barra" (NoPinningToTaskbar): não fixa nem desafixa.
#  Para mudar a barra de uma conta: desbloquear, entrar na conta, arrumar e bloquear de novo (a barra fica como está).
function Aplicar-BloqueioBarra([bool]$Ativo) {
    $polExp = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    $xml = Join-Path $Base 'barra-tarefas.xml'
    if ($Ativo -and (Test-Path $xml)) {
        Definir-Reg $polExp 'StartLayoutFile'   $xml 'ExpandString'
        Definir-Reg $polExp 'LockedStartLayout' 1
    } else {
        Apagar-Reg $polExp @('StartLayoutFile', 'LockedStartLayout')
    }
    $script:bloqAgora = $Ativo
    if ($Cfg.Usuario -and $Cfg.Usuario -ne $ContaAdmin) {
        $null = Para-Conta $Cfg.Usuario {
            param($hive)
            $k = "$hive\Software\Policies\Microsoft\Windows\Explorer"
            if ($script:bloqAgora) { Definir-Reg $k 'NoPinningToTaskbar' 1 } else { Apagar-Reg $k @('NoPinningToTaskbar') }
        }
    }
}

# Aplica agora o que estiver valendo para um bloqueio (Manutenção). As contas logadas recebem pela tarefa do sistema.
function Aplicar-Bloqueio([string]$Nome) {
    $ativo = Bloqueio-Ativo $Nome
    switch ($Nome) {
        'Configuracoes' { Aplicar-BloqueioConfiguracoes $ativo }
        'Impressao'     { Aplicar-BloqueioImpressao $ativo }
        'Navegador'     { $null = Para-Conta $Cfg.Usuario $script:PolNavegadorConta }
        'Barra'         { Aplicar-BloqueioBarra $ativo }
    }
    if ($Nome -eq 'Papel') { Aplicar-PapelAgora $false }
    else { Start-ScheduledTask -TaskPath '\IFSP\' -TaskName 'Coletor de log' -ErrorAction SilentlyContinue }
}

# Política do navegador na conta de uso (instalação e Manutenção). As linhas do Chrome/Edge seguem o bloqueio
# "Navegador"; esconder "Alterar uma senha" vale sempre nos PCs compartilhados. A CTI nunca recebe.
$script:PolNavegadorConta = {
    param($hive)
    $comp = [bool]$Cfg.Compartilhado
    $nav  = $comp -and (Bloqueio-Ativo 'Navegador')
    foreach ($linha in $RestricoesUsuario) {
        $c = $linha.Split('|')
        $k = "$hive\$($c[0])"
        $aplica = if ($c[0] -like 'Software\Policies\*') { $nav } else { $comp }
        if ($aplica) { Definir-Reg $k $c[1] ([int]$c[2]) }
        else         { Apagar-Reg  $k @($c[1]) }
    }
}

# ---------------------------------------------------------------
#  VS Code (labs): extensões numa pasta comum, que os alunos usam mas não mudam.
#  Só a CTI instala ou remove, por aqui (Manutenção > Bloqueios > VS Code). A política AllowedExtensions
#  libera só as extensões que estão na pasta; ela é tirada durante a instalação e refeita depois.
# ---------------------------------------------------------------
$PastaExtVSCode = Join-Path $Base 'vscode-extensoes'
$CodeExe        = 'C:\Program Files\Microsoft VS Code\Code.exe'
$CodeCmd        = 'C:\Program Files\Microsoft VS Code\bin\code.cmd'
$PolVSCode      = 'HKLM:\SOFTWARE\Policies\Microsoft\VSCode'
$AtalhoVSCode   = 'C:\Users\Public\Desktop\Visual Studio Code.lnk'

function Id-ExtensaoDaPasta([string]$NomePasta) { return ($NomePasta -replace '-\d+(\.\d+)*.*$', '').ToLower() }
function Extensoes-Instaladas {
    return @(Get-ChildItem $PastaExtVSCode -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '.*' } |
             ForEach-Object { Id-ExtensaoDaPasta $_.Name } | Sort-Object -Unique)
}
function Rodar-CodeExt([string]$Acao, [string]$Ext) {
    $extra = if ($Acao -eq '--install-extension') { ' --force' } else { '' }
    $p = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden `
         -ArgumentList "/c `"`"$CodeCmd`" --extensions-dir `"$PastaExtVSCode`" $Acao `"$Ext`"$extra`""
    if (-not $p.WaitForExit(300000)) { return -1 }
    return $p.ExitCode
}
function Atualizar-PoliticaVSCode {
    $perm = [ordered]@{}
    foreach ($id in (Extensoes-Instaladas)) { $perm[$id] = $true }
    Definir-Reg $PolVSCode 'AllowedExtensions' (ConvertTo-Json -InputObject $perm -Compress) 'String'
    Definir-Reg $PolVSCode 'UpdateMode' 'none' 'String'
    return @($perm.Keys)
}
# Instala extensões (id do Marketplace ou caminho de .vsix) na pasta comum. Devolve quantas deram certo.
function Instalar-ExtensoesVSCode([string[]]$Itens) {
    New-Item -ItemType Directory -Path $PastaExtVSCode -Force | Out-Null
    Apagar-Reg $PolVSCode @('AllowedExtensions')          # senão o próprio VS Code recusa a extensão nova
    $ok = 0
    foreach ($ext in $Itens) {
        $nomeExt = Split-Path $ext -Leaf
        $cod = Rodar-CodeExt '--install-extension' $ext
        if ($cod -eq 0)      { Log "  OK: extensão do VS Code $nomeExt" 'Green'; $ok++ }
        elseif ($cod -eq -1) { Log "  AVISO: extensão $nomeExt passou de 5 min." 'Yellow' }
        else { Log "  FALHA: extensão do VS Code $nomeExt (nome certo? sem internet? use um .vsix em softwares\vscode-extensoes)" 'Red' }
    }
    $perm = Atualizar-PoliticaVSCode
    Log "VS Code: extensões em $PastaExtVSCode (os alunos usam, mas não instalam nem removem); permitidas: $($perm -join ', ')." 'Green'
    return $ok
}

# ---------------------------------------------------------------
#  Veyon e Wake-on-LAN (labs)
# ---------------------------------------------------------------
$VeyonCli    = 'C:\Program Files\Veyon\veyon-cli.exe'
$VeyonMaster = 'C:\Program Files\Veyon\veyon-master.exe'
$AtalhoVeyon = 'C:\Users\Public\Desktop\Veyon Master.lnk'
$PastaVeyonPC = Join-Path $Base 'veyon'      # cópia das chaves públicas neste PC (vindas do pendrive)
# Quem é quem no Veyon:
#   PC do professor do lab (LAB-PROF): Veyon Master; chave do laboratório (vê só o seu lab)
#   PC central (tipo CTI, escolhido na instalação): Veyon Master; chave do campus (vê todos os PCs de professores e alunos)
#   PCs de alunos e de professores (LAB-ALUNO, USO-PROF, USO-ALUNO): só o serviço; aceitam a chave do campus
#   (e os de aluno do lab, também a chave do lab). O PC do professor do lab também aceita a chave do campus.
function Nome-ChaveVeyon  { return ('{0}_{1}' -f $Cfg.Sigla, $Cfg.Local) }   # ex.: AVR_INF3 (chave do lab; sem - nem .)
function Nome-ChaveCampus { return ('{0}_CAMPUS' -f $Cfg.Sigla) }            # ex.: RCL_CAMPUS (chave do PC central)
# Seção do Veyon (ver $SecoesVeyon na CONFIGURAÇÃO): código = pasta no pendrive; nome = o que o Veyon Master mostra
function Grupo-Veyon($c = $Cfg) {
    switch (Espaco-DoCfg $c) {
        'LAB'  { return [string]$c.Local }      # B104 ou INF1 (uma seção por lab)
        'SALA' { return 'SALAS' }               # todas as salas de aula juntas
        'PROF' { return 'PROF' }
        'CIE'  { return 'CIE' }
        'CBI'  { return 'CBI' }
    }
    return 'OUTROS'                             # "Outro" de professores ou alunos
}
function Nome-SecaoVeyon([string]$Grupo) {
    if ($SecoesVeyon.Contains($Grupo)) { return $SecoesVeyon[$Grupo] }
    if ($Grupo -match '^INF(\d+)$')    { return ($SecaoLabVeyon -f $Matches[1]) }
    return ($SecaoLabSalaVeyon -f $Grupo)       # as outras pastas são de labs pelo código da sala (B104)
}
function Pasta-LocalVeyon($c = $Cfg) { return ('{0}\{1}' -f $c.Sigla, (Grupo-Veyon $c)) }   # ex.: RCL\INF1, RCL\SALAS
function Pasta-CampusVeyon { return ('{0}\CAMPUS' -f $Cfg.Sigla) }                         # pasta da chave do campus
function Eh-CentralVeyon  { return ($Cfg.Tipo -eq 'CTI' -and [bool]$Cfg.VeyonCentral) }
function Usa-Veyon        { return ([bool]$Cfg.Compartilhado -or (Eh-CentralVeyon)) }

# Pasta de uma seção no pendrive (arquivos\veyon\RCL\SALAS). $null se não houver pendrive.
function Pasta-VeyonPen([string]$Rel = '') {
    $pd = Pasta-Pendrive
    if (-not $pd) { return $null }
    if (-not $Rel) { $Rel = Pasta-LocalVeyon }
    return (Join-Path $pd ('arquivos\veyon\' + $Rel))
}

function Rodar-Veyon {
    $ErrorActionPreference = 'Continue'
    $saida = & $VeyonCli @args 2>&1 | Out-String
    return [pscustomobject]@{ Codigo = $LASTEXITCODE; Saida = $saida.Trim() }
}

# Anota este PC na lista da sua seção, no pendrive: seção;nome;host;mac;ip (seção = código, ex.: SALAS)
function Registrar-PcNoVeyon([string]$PastaPen) {
    $nic = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq '802.3' -and $_.Status -eq 'Up' } | Select-Object -First 1
    if (-not $nic) { $nic = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq '802.3' } | Select-Object -First 1 }
    if (-not $nic) { Log 'AVISO: sem placa de rede cabeada; este PC não foi anotado para o Veyon/Wake-on-LAN.' 'Yellow'; return }
    $mac = $nic.MacAddress -replace '-', ':'
    $ip  = (Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress
    New-Item -ItemType Directory -Path $PastaPen -Force | Out-Null
    $csv = Join-Path $PastaPen 'computadores.csv'
    $linhas = @()
    if (Test-Path $csv) {
        $linhas = @(Get-Content $csv -Encoding UTF8 | Where-Object {
            $c = $_.Split(';')
            $_ -and ($c[1] -ne $Cfg.NomePC) -and -not ($c.Count -ge 4 -and $c[3].Trim() -eq $mac) })   # mesmo MAC = este PC com outro nome
    }
    $linhas += ('{0};{1};{2};{3};{4}' -f (Grupo-Veyon), $Cfg.NomePC, $Cfg.NomePC, $mac, $ip)
    [IO.File]::WriteAllLines($csv, [string[]]($linhas | Sort-Object), (New-Object System.Text.UTF8Encoding($false)))
    Log "Veyon: PC anotado no pendrive (seção $(Nome-SecaoVeyon (Grupo-Veyon)), pasta $PastaPen : $($Cfg.NomePC), MAC $mac, IP $ip)." 'Green'
}

# Listas do pendrive que este PC carrega: central = todas as seções do campus; professor do lab = a do seu lab
function Csvs-DoVeyon {
    $pd = Pasta-Pendrive
    if (-not $pd) { return @() }
    if (Eh-CentralVeyon) {
        return @(Get-ChildItem (Join-Path $pd "arquivos\veyon\$($Cfg.Sigla)") -Directory -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -ne 'CAMPUS' } | Sort-Object Name |
                 ForEach-Object { Join-Path $_.FullName 'computadores.csv' } | Where-Object { Test-Path $_ })
    }
    return @(Join-Path (Pasta-VeyonPen) 'computadores.csv' | Where-Object { Test-Path $_ })
}
# "Assinatura" das listas (nomes e conteúdo): muda quando algum PC entra, sai ou troca de nome
function Assinatura-ListaVeyon {
    $partes = @()
    foreach ($c in @(Csvs-DoVeyon)) { $partes += ('{0}={1}' -f (Split-Path (Split-Path $c -Parent) -Leaf), (Get-FileHash -LiteralPath $c -Algorithm SHA256).Hash) }
    return ($partes -join ';')
}
$ArqAssinaturaVeyon = Join-Path $Base 'veyon-lista-carregada.txt'

# PC do professor do lab e PC central: ao abrir a Manutenção ou o menu do Veyon com o pendrive, se a lista
# do pendrive mudou desde a última carga, carrega de novo sozinho (sem perguntar).
function Sincronizar-VeyonAuto {
    if (-not ($Cfg.Tipo -eq 'LAB-PROF' -or (Eh-CentralVeyon))) { return }
    if (-not (Test-Path $VeyonCli) -or -not (Pasta-Pendrive)) { return }
    $nova = Assinatura-ListaVeyon
    if (-not $nova) { return }
    $velha = if (Test-Path $ArqAssinaturaVeyon) { ([string](Get-Content $ArqAssinaturaVeyon -Raw -Encoding UTF8)).Trim() } else { '' }
    if ($nova -eq $velha) { return }
    Mostrar-Cabecalho "VEYON - $($Cfg.NomePC)" $CoresArea.Veyon
    Titulo 'A lista de computadores do pendrive mudou: atualizando este PC'
    Atualizar-ComputadoresVeyon
    Registrar-Manutencao ("Veyon: lista atualizada sozinha (a do pendrive mudou){0}" -f $(if ($script:VeyonCarga -eq 'AVISOS') { ', com avisos' } else { '' }))
    $script:CorArea = 'Cyan'
    Write-Host '   Se o Veyon Master estiver aberto, feche e abra de novo para ver a lista nova.' -ForegroundColor Cyan
    $null = Read-Host '  ENTER para continuar'
}

# Endereços IPv4 e MACs deste PC (para nunca carregar este PC como se fosse outro)
function Ips-DestePC {
    $ips = @('127.0.0.1')
    $ips += @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.IPAddress })
    return @($ips | Select-Object -Unique)
}
function Macs-DestePC {
    return @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.MacAddress } |
             ForEach-Object { ([string]$_.MacAddress -replace '-', ':').ToUpper() } | Select-Object -Unique)
}
# IPv4 de um nome na rede (lista vazia se não achou)
function Ips-DoNome([string]$Nome) {
    try { return @([Net.Dns]::GetHostAddresses($Nome) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | ForEach-Object { $_.IPAddressToString } | Select-Object -Unique) }
    catch { return @() }
}
$ArqListaVeyonPC = Join-Path $Base 'veyon-computadores.csv'   # cópia da última lista carregada (Veyon > Conferir a lista)

# Carrega no Veyon os computadores anotados no pendrive.
#  PC do professor: só o seu laboratório.   PC central: todas as seções do campus (uma seção por pasta).
# O nome da seção no Veyon vem da pasta (via $SecoesVeyon), não do arquivo: mudar o nome na CONFIGURAÇÃO
# e carregar de novo já basta.
# O PC que tem o Veyon Master nunca pode controlar a si mesmo (ao bloquear ou desligar todos, ele ficaria de fora):
#  - PC do professor: a própria linha fica na lista do lab (assim o Veyon Master abre já no lab certo) e é
#    escondida pelo "Hide local computer" (Ajustar-VeyonMaster).
#  - PC central: não entra em nenhuma lista; se aparecer numa (ex.: era de outro lugar), é pulado.
#  - Qualquer outra linha cujo nome aponte para um IP DESTE PC (registro velho no DNS) é pulada, com aviso.
#  - O IP anotado na instalação só é usado com $VeyonUsarIpAnotado = $true (e nunca se for um IP deste PC).
# Linha da tabela do Veyon (cabe na janela padrão do PowerShell)
function Linha-Veyon([string]$Secao, [string]$Nome, [string]$Endereco, [string]$Mac, [string]$Obs, [string]$Cor = 'Gray') {
    Write-Host ('   {0,-16} {1,-15} {2,-15} {3,-17} {4}' -f (Cortar $Secao 16), (Cortar $Nome 15), (Cortar $Endereco 15), $Mac, $Obs) -ForegroundColor $Cor
}
# Resultado da última carga (para quem chamou): OK, AVISOS (PCs pulados), VAZIA (sem outros PCs) ou ERRO
$script:VeyonCarga = ''
function Atualizar-ComputadoresVeyon {
    $script:VeyonCarga = 'ERRO'
    if (-not (Test-Path $VeyonCli)) { Log 'Veyon não está instalado neste PC.' 'Yellow'; return }
    $pd = Pasta-Pendrive
    if (-not $pd) { Log 'Veyon: pendrive com a pasta ManutencaoIFSP não encontrado. Conecte o pendrive e tente de novo.' 'Yellow'; return }
    $csvs = @(Csvs-DoVeyon)
    if ($csvs.Count -eq 0) { Log 'Veyon: ainda não há computadores anotados no pendrive.' 'Yellow'; $script:VeyonCarga = 'VAZIA'; return }
    try { Clear-DnsClientCache -ErrorAction Stop } catch { }      # respostas novas do DNS (ipconfig /flushdns)
    $ipsEste  = Ips-DestePC
    $macsEste = Macs-DestePC
    $central  = Eh-CentralVeyon
    $saida = @(); $outros = 0; $pulados = @()
    Write-Host ''
    Linha-Veyon 'Seção' 'Computador' 'Endereço usado' 'MAC' '' 'Cyan'
    foreach ($csv in $csvs) {
        $secao = Nome-SecaoVeyon (Split-Path (Split-Path $csv -Parent) -Leaf)
        foreach ($l in (Get-Content $csv -Encoding UTF8)) {
            $c = $l.Split(';')
            if ($c.Count -lt 4 -or -not $c[1].Trim()) { continue }
            $nome = $c[1].Trim(); $mac = $c[3].Trim()
            $macN = ($mac -replace '-', ':').ToUpper()
            $ip   = if ($c.Count -ge 5) { $c[4].Trim() } else { '' }
            $ehEste = ($nome -eq [string]$Cfg.NomePC) -or ($nome -eq $env:COMPUTERNAME) -or ($macN -and ($macsEste -contains $macN))
            if ($ehEste) {
                if ($central) { Linha-Veyon $secao $nome '-' $mac 'este PC: fora da lista' 'DarkGray'; continue }
                Linha-Veyon $secao $Cfg.NomePC $Cfg.NomePC $mac 'este PC: escondido' 'DarkGray'
                $saida += ('{0};{1};{2};{3}' -f $secao, $Cfg.NomePC, $Cfg.NomePC, $mac)
                continue
            }
            $ipsNome  = @(Ips-DoNome $nome)
            $paraEste = @($ipsNome | Where-Object { $ipsEste -contains $_ })
            if ($paraEste.Count -gt 0) {
                Linha-Veyon $secao $nome '-' $mac 'PULADO: aponta p/ este PC' 'Red'
                $pulados += "$nome ($($paraEste -join ', '))"
                continue
            }
            $outros++
            $endereco = $nome; $obs = ''; $cor = 'Gray'
            if ($ipsNome.Count -eq 0) {
                if ($VeyonUsarIpAnotado -and $ip -and ($ipsEste -notcontains $ip)) { $endereco = $ip; $obs = 'sem nome: IP anotado'; $cor = 'Yellow' }
                else { $obs = 'nome não achado agora'; $cor = 'Yellow' }
            }
            Linha-Veyon $secao $nome $endereco $mac $obs $cor
            $saida += ('{0};{1};{2};{3}' -f $secao, $nome, $endereco, $mac)
        }
    }
    if ($saida.Count -gt 0) {
        $tmp = Join-Path $env:TEMP 'ifsp-veyon-importar.csv'
        # UTF-8 com BOM: o veyon-cli reconhece o BOM e lê os acentos dos nomes das seções certos
        [IO.File]::WriteAllLines($tmp, [string[]]$saida, (New-Object System.Text.UTF8Encoding($true)))
        $null = Rodar-Veyon networkobjects clear
        $r = Rodar-Veyon networkobjects import $tmp format '%location%;%name%;%host%;%mac%'
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        if ($r.Codigo -ne 0) { Log "FALHA ao carregar os computadores no Veyon: $($r.Saida)" 'Red'; return }
        Log-SoArquivo 'Veyon: veyon-cli networkobjects import (lista do pendrive)'
    } else {
        $null = Rodar-Veyon networkobjects clear
    }
    try { Set-Content -Path $ArqAssinaturaVeyon -Value (Assinatura-ListaVeyon) -Encoding UTF8 } catch { }
    try { [IO.File]::WriteAllLines($ArqListaVeyonPC, [string[]]$saida, (New-Object System.Text.UTF8Encoding($true))) } catch { }
    Write-Host ''
    if ($outros -gt 0) {
        $onde = if ($central) { "do campus ($(Qtd $csvs.Count 'seção' 'seções'))" } else { "da seção $(Nome-SecaoVeyon (Grupo-Veyon))" }
        Log ("Veyon: {0} {1} carregado(s)." -f (Qtd $outros 'computador' 'computadores'), $onde) 'Green'
        $script:VeyonCarga = 'OK'
    } elseif ($central) {
        Log 'Veyon: nenhum computador na lista ainda (configure os PCs de professores e alunos com o pendrive).' 'Yellow'
        $script:VeyonCarga = 'VAZIA'
    } else {
        Log 'Veyon: nenhum PC de aluno na lista do lab ainda (este PC está nela, escondido).' 'Yellow'
        $script:VeyonCarga = 'VAZIA'
    }
    if ($pulados.Count -gt 0) {
        $script:VeyonCarga = 'AVISOS'
        Log "AVISO: $(Qtd $pulados.Count 'PC pulado' 'PCs pulados') (o nome aponta para este PC): $($pulados -join '; ')." 'Red'
        Write-Host '   Causa comum: o DNS do roteador guarda um endereço velho. Confira o DNS do roteador,' -ForegroundColor Yellow
        Write-Host '   rode "ipconfig /flushdns" e carregue de novo com esses PCs ligados.' -ForegroundColor Yellow
    }
}

# Veyon > Conferir a lista: para cada PC carregado, o nome é encontrado? aponta para este PC? o Veyon responde?
function Conferir-ListaVeyon {
    Titulo 'Conferir a lista do Veyon deste PC'
    if (-not (Test-Path $ArqListaVeyonPC)) {
        Write-Host '   Ainda não há lista carregada por esta versão do script. Carregue os computadores (opção 2) com o pendrive.' -ForegroundColor Yellow
        return
    }
    Write-Host '   Para cada PC: o nome é achado na rede? Aponta para ESTE PC? O Veyon dele responde (porta 11100)?' -ForegroundColor DarkGray
    try { Clear-DnsClientCache -ErrorAction Stop } catch { }
    $ipsEste = Ips-DestePC
    $total = 0; $ok = 0; $perigo = @(); $semNome = 0
    Write-Host ''
    $fmt = '   {0,-16} {1,-15} {2,-15} {3}'
    Write-Host ($fmt -f 'Seção', 'Computador', 'IP agora', 'Situação') -ForegroundColor Cyan
    foreach ($l in [IO.File]::ReadAllLines($ArqListaVeyonPC)) {
        $c = $l.Split(';')
        if ($c.Count -lt 3 -or -not $c[1].Trim()) { continue }
        $secao = Cortar $c[0].Trim() 16; $nome = $c[1].Trim(); $endereco = $c[2].Trim()
        if ($nome -eq [string]$Cfg.NomePC) {
            Write-Host ($fmt -f $secao, (Cortar $nome 15), '-', 'este PC (escondido)') -ForegroundColor DarkGray
            continue
        }
        $total++
        $ips = @(Ips-DoNome $endereco)
        if ($ips.Count -eq 0) {
            $semNome++
            Write-Host ($fmt -f $secao, (Cortar $nome 15), '-', 'nome não achado (desligado?)') -ForegroundColor Yellow
            continue
        }
        $paraEste = @($ips | Where-Object { $ipsEste -contains $_ })
        if ($paraEste.Count -gt 0) {
            $perigo += $nome
            Write-Host ($fmt -f $secao, (Cortar $nome 15), $paraEste[0], 'PERIGO: aponta p/ este PC') -ForegroundColor Red
            continue
        }
        if (Testar-Porta $ips[0] 11100 500) {
            $ok++
            Write-Host ($fmt -f $secao, (Cortar $nome 15), $ips[0], 'OK (Veyon responde)') -ForegroundColor Green
        } else {
            Write-Host ($fmt -f $secao, (Cortar $nome 15), $ips[0], 'Veyon não responde') -ForegroundColor Yellow
        }
    }
    Write-Host ''
    Write-Host ("   {0}: {1} OK, {2} sem nome na rede, {3} apontando para este PC." -f (Qtd $total 'computador' 'computadores'), $ok, $semNome, $perigo.Count) -ForegroundColor Cyan
    if ($perigo.Count -gt 0) {
        Write-Host '   PERIGO: o Veyon Master pode mostrar a própria tela e, ao bloquear ou desligar todos,' -ForegroundColor Red
        Write-Host '   atingir este PC. Rode "ipconfig /flushdns", confira o DNS do roteador e carregue de novo' -ForegroundColor Red
        Write-Host '   (opção 2): na carga, os nomes que apontam para este PC são pulados.' -ForegroundColor Red
    }
    Registrar-Manutencao ("Veyon: lista conferida ({0}, {1} OK, {2} apontando para este PC)" -f (Qtd $total 'PC' 'PCs'), $ok, $perigo.Count)
}

# Veyon > Diagnóstico: serviço, porta 11100, firewall, autenticação, chaves e (no Master) os ajustes do script
function Diagnostico-Veyon {
    Titulo 'Veyon neste PC: serviço, porta 11100 e chaves'
    if (-not (Test-Path $VeyonCli)) { Write-Host '   O Veyon não está instalado neste PC.' -ForegroundColor Yellow; return }
    $ver = (Get-Item $VeyonCli).VersionInfo.ProductVersion
    $svc = Get-Service -Name 'VeyonService' -ErrorAction SilentlyContinue
    $escuta = [bool](Get-NetTCPConnection -LocalPort 11100 -State Listen -ErrorAction SilentlyContinue)
    $fw = @(Get-NetFirewallRule -Direction Inbound -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Veyon*' -and [string]$_.Enabled -eq 'True' })
    $metodo = (Rodar-Veyon config get Authentication/Method).Saida
    Write-Host ('   Versão ................. {0}' -f $ver)
    $txtS = if (-not $svc) { 'não encontrado' } elseif ($svc.Status -eq 'Running') { "rodando (início: $($svc.StartType))" } else { "PARADO ($($svc.Status))" }
    Write-Host ('   Serviço VeyonService ... {0}' -f $txtS) -ForegroundColor $(if ($svc -and $svc.Status -eq 'Running') { 'Green' } else { 'Red' })
    Write-Host ('   Porta 11100 ............ {0}' -f $(if ($escuta) { 'aberta (esperando conexões)' } else { 'FECHADA (os Masters não conseguem ver este PC)' })) -ForegroundColor $(if ($escuta) { 'Green' } else { 'Red' })
    Write-Host ('   Firewall (entrada) ..... {0} regra(s) do Veyon ligada(s){1}' -f $fw.Count, $(if ($fw.Count) { ': ' + (($fw | ForEach-Object { $_.DisplayName } | Select-Object -Unique) -join ', ') } else { '' }))
    Write-Host ('   Autenticação ........... {0}' -f $(if ($metodo -match '1') { 'arquivo de chave (padrão do script)' } else { "$metodo (o script usa 1 = arquivo de chave)" }))
    if ($Cfg.Tipo -eq 'LAB-PROF' -or (Eh-CentralVeyon)) {
        $hide = (Rodar-Veyon config get Master/HideLocalComputer).Saida
        $auto = (Rodar-Veyon config get Master/AutoSelectCurrentLocation).Saida
        $neg  = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name MaxNegativeCacheTtl -ErrorAction SilentlyContinue).MaxNegativeCacheTtl
        Write-Host ('   Esconder este PC ....... {0}' -f $(if ($hide -match 'true') { 'sim (Hide local computer)' } else { "NÃO ($hide): use a opção 1 para refazer" })) -ForegroundColor $(if ($hide -match 'true') { 'Green' } else { 'Red' })
        Write-Host ('   Abrir no local atual ... {0}' -f $(if ($auto -match 'true') { 'sim' } else { 'não' }))
        Write-Host ('   DNS sem cache negativo . {0}' -f $(if ($neg -eq 0) { 'sim (MaxNegativeCacheTtl = 0)' } else { 'não (use a opção 1; vale depois de reiniciar)' })) -ForegroundColor $(if ($neg -eq 0) { 'Green' } else { 'Yellow' })
    }
    Titulo 'Chaves'
    (Rodar-Veyon authkeys list).Saida -split "`r?`n" | ForEach-Object { Write-Host "   $_" }
    if ($svc -and (Perguntar-SN-Padrao 'Reiniciar o serviço do Veyon agora?' (-not ($svc.Status -eq 'Running' -and $escuta)))) {
        $null = Rodar-Veyon service restart
        Start-Sleep -Seconds 3
        $escuta = [bool](Get-NetTCPConnection -LocalPort 11100 -State Listen -ErrorAction SilentlyContinue)
        Registrar-Manutencao ("Serviço do Veyon reiniciado (veyon-cli service restart); porta 11100 {0}" -f $(if ($escuta) { 'aberta' } else { 'ainda fechada' }))
    }
}

function Ver-ChavesVeyon {
    if (-not (Test-Path $VeyonCli)) { Write-Host '   O Veyon não está instalado neste PC.' -ForegroundColor Yellow; return }
    Titulo 'Chaves do Veyon neste PC'
    (Rodar-Veyon authkeys list).Saida -split "`r?`n" | ForEach-Object { Write-Host "   $_" }
    if ($Cfg.Tipo -eq 'LAB-PROF' -or (Eh-CentralVeyon)) {
        Titulo 'Computadores cadastrados no Veyon'
        (Rodar-Veyon networkobjects list).Saida -split "`r?`n" | ForEach-Object { Write-Host "   $_" }
    }
}

# O Wake-on-LAN está ligado nesta placa? (pela gerência de energia ou pela propriedade avançada do driver)
function WoL-Ligado([string]$Placa) {
    $pm = Get-NetAdapterPowerManagement -Name $Placa -ErrorAction SilentlyContinue
    if ($pm -and [string]$pm.WakeOnMagicPacket -eq 'Enabled') { return $true }
    $ap = Get-NetAdapterAdvancedProperty -Name $Placa -RegistryKeyword '*WakeOnMagicPacket' -ErrorAction SilentlyContinue
    return [bool]($ap -and [string]$ap.RegistryValue -eq '1')
}
function Preparar-WakeOnLan {
    foreach ($nic in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq '802.3' })) {
        try { Set-NetAdapterPowerManagement -Name $nic.Name -WakeOnMagicPacket Enabled -ErrorAction Stop } catch { }
        try { Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -ErrorAction Stop } catch { }
        if (WoL-Ligado $nic.Name) { Log "Wake-on-LAN ligado na placa $($nic.Name) (confira na BIOS: WoL ligado e ErP desligado)." 'Green' }
        else { Log "AVISO: a placa $($nic.Name) não aceitou ligar o Wake-on-LAN pelo Windows (driver). Veja nas propriedades da placa e na BIOS." 'Yellow' }
    }
    Definir-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0   # sem inicialização rápida
}

# Instala o Veyon se faltar (ou se $Forcar). Professor do lab e PC central: completo, com o Veyon Master;
# os outros: só o serviço.
function Instalar-Veyon([bool]$Forcar) {
    $master = ($Cfg.Tipo -eq 'LAB-PROF') -or (Eh-CentralVeyon)
    if ($master -and (Test-Path $VeyonCli) -and -not (Test-Path $VeyonMaster)) { $Forcar = $true }   # faltava o Veyon Master
    if ((Test-Path $VeyonCli) -and -not $Forcar) { return $true }
    $pastas = @((Join-Path $Pen 'softwares\veyon'), (Join-Path $Pen 'softwares\laboratorio'))
    $pd = Pasta-Pendrive
    if ($pd -and $pd -ne $Pen) { $pastas += (Join-Path $pd 'softwares\veyon') }
    $inst = Get-ChildItem $pastas -Filter 'veyon*setup*.exe' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
    if (-not $inst) {
        if (Test-Path $VeyonCli) { return $true }
        Log 'AVISO: instalador do Veyon não encontrado (softwares\veyon\veyon-...-setup.exe); Veyon não configurado.' 'Yellow'
        return $false
    }
    $argsVeyon = if ($master) { '/S' } else { '/S /NoMaster' }
    Write-Host "   Instalando $($inst.Name) ..."
    $pv = Start-Process -FilePath $inst.FullName -ArgumentList $argsVeyon -PassThru -WindowStyle Hidden
    $null = $pv.WaitForExit(900000)
    if (Test-Path $VeyonCli) {
        $txt = if ($master) { 'completo, com o Veyon Master' } else { 'só o serviço, sem o Veyon Master' }
        Log "Veyon instalado ($txt)." 'Green'
        return $true
    }
    Log "FALHA: o Veyon não foi instalado (código $($pv.ExitCode))." 'Red'
    return $false
}

# Veyon Master (professor do lab e PC central): ícone na Área de Trabalho.
#  Professor: abre já com o seu lab marcado e sem mostrar a própria tela.
#  Central: mostra todos os locais; a CTI marca no painel "Locais e computadores" os que quer ver.
#  Os dois: o próprio PC nunca aparece (não se bloqueia nem se desliga junto com os outros) e o DNS não guarda
#  "nome não existe" (MaxNegativeCacheTtl = 0).
function Ajustar-VeyonMaster {
    if (Eh-CentralVeyon) { $null = Rodar-Veyon config set Master/AutoSelectCurrentLocation false }
    else                 { $null = Rodar-Veyon config set Master/AutoSelectCurrentLocation true }
    $null = Rodar-Veyon config set Master/HideLocalComputer true
    # O Windows guarda por até 15 min a resposta "este nome não existe": um PC que estava desligado ficava
    # "hostname could not be resolved" no Veyon Master depois de ligado. 0 = não guarda (vale depois de reiniciar).
    $dnsPar = 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters'
    $negAtual = (Get-ItemProperty -Path $dnsPar -Name MaxNegativeCacheTtl -ErrorAction SilentlyContinue).MaxNegativeCacheTtl
    if ($negAtual -ne 0) {
        Definir-Reg $dnsPar 'MaxNegativeCacheTtl' 0
        $script:PrecisaReiniciar = $true
        Log 'DNS: o Windows deixa de guardar "nome não existe" (MaxNegativeCacheTtl = 0; vale depois de reiniciar o PC).' 'Green'
    }
    if (Test-Path $VeyonMaster) {
        $sh = New-Object -ComObject WScript.Shell
        $a  = $sh.CreateShortcut($AtalhoVeyon)
        $a.TargetPath       = $VeyonMaster
        $a.WorkingDirectory = Split-Path $VeyonMaster
        $a.Description      = 'Veyon Master'
        $a.Save()
        Log 'Veyon Master: ícone na Área de Trabalho.' 'Green'
    }
}

# Guarda neste PC as chaves públicas do pendrive (do lab e do campus): assim o pendrive pode sair logo no começo
function Guardar-ChavesNoPC {
    $pd = Pasta-Pendrive
    if (-not $pd) { return }
    New-Item -ItemType Directory -Path $PastaVeyonPC -Force | Out-Null
    foreach ($nome in @((Pasta-LocalVeyon), (Pasta-CampusVeyon))) {
        Get-ChildItem (Join-Path $pd "arquivos\veyon\$nome") -Filter '*_public.pem' -ErrorAction SilentlyContinue |
            Copy-Item -Destination $PastaVeyonPC -Force
    }
}

# Importa uma chave pública (procura no pendrive, na cópia e nas chaves guardadas neste PC). Devolve $true se importou.
function Importar-ChavePublica([string]$Chave, [string]$NomePasta) {
    $cands = @()
    $pd = Pasta-Pendrive
    if ($pd) { $cands += (Join-Path $pd "arquivos\veyon\$NomePasta") }
    $cands += (Join-Path $Pen "arquivos\veyon\$NomePasta")
    $cands += $PastaVeyonPC
    $arq = $null
    foreach ($p in $cands) { $f = Join-Path $p "${Chave}_public.pem"; if (Test-Path $f) { $arq = $f; break } }
    if (-not $arq) { return $false }
    if ((Rodar-Veyon authkeys list).Saida -match [regex]::Escape("$Chave/public")) { $null = Rodar-Veyon authkeys delete "$Chave/public" }
    $r = Rodar-Veyon authkeys import "$Chave/public" $arq
    if ($r.Codigo -eq 0) { Log "Veyon: chave $Chave importada." 'Green'; return $true }
    Log "FALHA ao importar a chave $Chave do Veyon: $($r.Saida)" 'Red'
    return $false
}

# Cria (se faltar) uma chave e grava a parte pública neste PC e no pendrive. Usada pelo professor do lab e pelo PC central.
function Criar-ExportarChave([string]$Chave, [string]$NomePasta) {
    if ((Rodar-Veyon authkeys list).Saida -notmatch [regex]::Escape("$Chave/private")) {
        $r = Rodar-Veyon authkeys create $Chave
        if ($r.Codigo -ne 0) { Log "FALHA ao criar a chave $Chave do Veyon: $($r.Saida)" 'Red'; return }
        Log "Veyon: chave $Chave criada." 'Green'
        $pAntiga = Pasta-VeyonPen $NomePasta
        if ($pAntiga -and (Test-Path (Join-Path $pAntiga "${Chave}_public.pem"))) {
            Log "AVISO: havia uma chave $Chave antiga no pendrive; ela foi trocada. Refaça o menu 3 (Veyon) nos PCs que usam essa chave." 'Yellow'
        }
    }
    New-Item -ItemType Directory -Path $PastaVeyonPC -Force | Out-Null
    $pubLocal = Join-Path $PastaVeyonPC "${Chave}_public.pem"
    Remove-Item $pubLocal -Force -ErrorAction SilentlyContinue
    $r = Rodar-Veyon authkeys export "$Chave/public" $pubLocal
    if (-not (Test-Path $pubLocal)) { Log "FALHA ao exportar a chave pública ${Chave}: $($r.Saida)" 'Red'; return }
    $pp = Pasta-VeyonPen $NomePasta
    if ($pp) {
        New-Item -ItemType Directory -Path $pp -Force | Out-Null
        Copy-Item -Path $pubLocal -Destination (Join-Path $pp "${Chave}_public.pem") -Force
        Log "Veyon: chave pública $Chave gravada no pendrive ($pp)." 'Green'
    } else {
        Log "AVISO: pendrive não encontrado. A chave pública $Chave ficou só neste PC ($pubLocal). Conecte o pendrive e use o menu 3 (Veyon) > 1." 'Yellow'
    }
}

# Configuração completa do Veyon deste PC (instalação e menu 3 - Veyon)
function Configurar-Veyon([bool]$Reinstalar = $false) {
    if (-not (Usa-Veyon)) { Log 'Veyon: não se aplica a este tipo de PC.'; return }
    if (-not (Instalar-Veyon $Reinstalar)) { return }
    $null = Rodar-Veyon config set Authentication/Method 1          # 1 = autenticação por arquivo de chave
    $grupoUsuarios = (New-Object Security.Principal.SecurityIdentifier($SID_Usuarios)).Translate([Security.Principal.NTAccount]).Value.Split('\')[-1]
    if (Eh-CentralVeyon) {
        Criar-ExportarChave (Nome-ChaveCampus) (Pasta-CampusVeyon)
        Ajustar-VeyonMaster
        Atualizar-ComputadoresVeyon
    } else {
        if ($Cfg.Tipo -eq 'LAB-PROF') {
            Criar-ExportarChave (Nome-ChaveVeyon) (Pasta-LocalVeyon)
            # a conta Professor (usuário padrão) precisa poder usar a chave privada do lab
            $null = Rodar-Veyon authkeys setaccessgroup "$(Nome-ChaveVeyon)/private" $grupoUsuarios
        }
        if ($Cfg.Tipo -eq 'LAB-ALUNO') {
            if (-not (Importar-ChavePublica (Nome-ChaveVeyon) (Pasta-LocalVeyon))) {
                Log "Veyon: a chave do lab ($(Nome-ChaveVeyon)) não está no pendrive. Configure primeiro o PC do professor deste lab; depois use o menu 3 (Veyon) > 1 aqui, com o pendrive." 'Yellow'
            }
        }
        # todos os PCs de professores e alunos aceitam o PC central do campus
        if (-not (Importar-ChavePublica (Nome-ChaveCampus) (Pasta-CampusVeyon))) {
            Log "Veyon: a chave do campus ($(Nome-ChaveCampus)) ainda não está no pendrive. Depois de configurar o PC central (setor CTI), use o menu 3 (Veyon) > 1 aqui, com o pendrive." 'Yellow'
        }
        $pp = Pasta-VeyonPen
        if ($pp -and -not $script:PcAnotado) { Registrar-PcNoVeyon $pp; $script:PcAnotado = $true }
        elseif (-not $pp -and -not $script:PcAnotado) { Log 'Veyon: sem pendrive; este PC ainda não foi anotado na lista da sua seção (use o menu 3 com o pendrive).' 'Yellow' }
        if ($Cfg.Tipo -eq 'LAB-PROF') { Ajustar-VeyonMaster; Atualizar-ComputadoresVeyon; Restringir-VeyonMaster }
    }
    $null = Rodar-Veyon service restart
}

# Menu 3 (Veyon) do menu inicial: para rodar com o pendrive, PC por PC.
function Menu-VeyonInicial {
    if (-not (Carregar-Cfg)) { Pausa; return }
    Sincronizar-VeyonAuto
    if ($Cfg.Tipo -eq 'OUTRO') { Write-Host '   PCs de servidores (administrativo) não têm Veyon: ele só é usado nos PCs de professores e alunos (e no PC central da CTI).' -ForegroundColor Yellow; Pausa; return }
    $corV = $CoresArea.Veyon
    while ($true) {
        $papel = if (Eh-CentralVeyon) { 'PC central do campus' }
                 elseif ($Cfg.Tipo -eq 'CTI') { 'PC da CTI' }
                 elseif ($Cfg.Tipo -eq 'LAB-PROF') { 'PC do professor do lab' }
                 else { 'PC de aluno ou de professor' }
        $secao = if (Eh-CentralVeyon) { 'todas as seções' } elseif ($Cfg.Tipo -eq 'CTI') { 'sem seção' } else { "seção $(Nome-SecaoVeyon (Grupo-Veyon))" }
        $faixaV = "VEYON - $($Cfg.NomePC)"
        Mostrar-Cabecalho $faixaV $corV
        Write-Host "   $papel - $secao" -ForegroundColor $corV
        $pd = Pasta-Pendrive
        if ($pd) { Write-Host "   Pendrive: $pd" -ForegroundColor Green }
        else     { Write-Host '   Pendrive: NÃO ENCONTRADO (conecte o pendrive com a pasta ManutencaoIFSP)' -ForegroundColor Yellow }
        Write-Host ("   Veyon neste PC: {0}" -f $(if (Test-Path $VeyonCli) { 'instalado' } else { 'não instalado' }))
        Write-Host ''
        $ehMaster = ($Cfg.Tipo -eq 'CTI') -or ($Cfg.Tipo -eq 'LAB-PROF')
        if ($Cfg.Tipo -eq 'CTI') {
            Write-Host '   Ordem: 1) aqui, opção 1   2) cada PC de professor e aluno (na instalação ou menu 3 > 1)   3) aqui, opção 2' -ForegroundColor DarkGray
            Write-Host '   1 - Configurar este PC como o PC central do Veyon (Veyon Master e chave do campus)'
            Write-Host '   2 - Carregar todos os computadores do campus (listas anotadas no pendrive)'
        } elseif ($Cfg.Tipo -eq 'LAB-PROF') {
            Write-Host '   Ordem: 1) aqui, opção 1   2) cada PC de aluno (opção 1 lá)   3) aqui de novo, opção 2' -ForegroundColor DarkGray
            Write-Host '   1 - Instalar e configurar o Veyon deste PC (Veyon Master, chave do lab e chave do campus)'
            Write-Host '   2 - Carregar os computadores dos alunos no Veyon (lista anotada no pendrive)'
        } else {
            Write-Host '   1 - Instalar e configurar o Veyon deste PC (chaves do pendrive e anotar este PC na lista da seção)'
        }
        if ($ehMaster) {
            Write-Host '   3 - Ver as chaves e os computadores cadastrados'
            Write-Host '   4 - Conferir a lista (nomes que apontam para este PC, PCs que respondem)'
            Write-Host '   5 - Diagnóstico deste PC (serviço, porta 11100, chaves, ajustes do Veyon Master)'
            $max = 5
        } else {
            Write-Host '   2 - Ver as chaves cadastradas'
            Write-Host '   3 - Diagnóstico deste PC (serviço, porta 11100, chaves)'
            $max = 3
        }
        # opção escolhida -> ação (os números mudam conforme o tipo do PC)
        $acoes = if ($ehMaster) { @{ 1 = 'CONFIG'; 2 = 'CARREGAR'; 3 = 'CHAVES'; 4 = 'CONFERIR'; 5 = 'DIAG' } }
                 else           { @{ 1 = 'CONFIG'; 2 = 'CHAVES'; 3 = 'DIAG' } }
        $script:SemPausa = $false
        $op = Ler-Opcao $max
        if ($op -eq 0) { $script:CorArea = 'Cyan'; return }
        Mostrar-Cabecalho $faixaV $corV            # cada opção começa numa tela limpa
        try {
            switch ($acoes[$op]) {
                'CONFIG' {
                    Titulo 'Instalar e configurar o Veyon deste PC'
                    $script:PcAnotado = $false
                    if ($Cfg.Tipo -eq 'CTI' -and -not $Cfg.VeyonCentral) { Definir-CampoCfg 'VeyonCentral' $true; Salvar-Config }
                    Configurar-Veyon
                    Registrar-Manutencao "Veyon configurado pelo menu do Veyon ($($Cfg.NomePC))"
                    if ($script:PrecisaReiniciar) { Write-Host '   Reinicie este PC para o ajuste do DNS valer.' -ForegroundColor Yellow }
                }
                'CARREGAR' {
                    Titulo 'Carregar os computadores no Veyon'
                    Atualizar-ComputadoresVeyon
                    switch ($script:VeyonCarga) {
                        'OK'     { Registrar-Manutencao 'Veyon: lista carregada' }
                        'AVISOS' { Registrar-Manutencao 'Veyon: lista carregada com avisos (PCs pulados)' }
                        'VAZIA'  { Registrar-Manutencao 'Veyon: lista carregada sem outros PCs' }
                    }
                    if ($script:VeyonCarga -ne 'ERRO') { Write-Host '   Se o Veyon Master estiver aberto, feche e abra de novo para ver a lista.' -ForegroundColor Cyan }
                }
                'CHAVES'   { Ver-ChavesVeyon }
                'CONFERIR' { Conferir-ListaVeyon }
                'DIAG'     { Diagnostico-Veyon }
            }
        } catch {
            Write-Host "   ERRO: $($_.Exception.Message)" -ForegroundColor Red
        }
        Pausa
    }
}

# ---------------------------------------------------------------
#  Manutenção: telas
# ---------------------------------------------------------------
function Pausa { Write-Host ''; $null = Read-Host '  ENTER para voltar ao menu' }

function Ver-Situacao {
    Mostrar-Resumo $Cfg
    Write-Host ('   ' + (Texto-Horarios $Cfg.Horarios)) -ForegroundColor Yellow
    foreach ($n in (Bloqueios-DoPC)) {
        Write-Host ("   Bloqueio - {0}: {1}" -f (Desc-Bloqueio $n), (Texto-Bloqueio $n)) -ForegroundColor (Cor-Bloqueio $n)
    }
    Write-Host "   Papel de parede: $(Nome-PapelAtual)" -ForegroundColor Yellow
    $senha = Conta-TemSenha $Cfg.Usuario
    $senhaTxt = if ($senha -eq $true) { 'com senha (pede a senha ao ligar)' } elseif ($senha -eq $false) { 'sem senha (entra sozinha ao ligar)' } else { 'não deu para verificar' }
    Write-Host "   Conta $($Cfg.Usuario): $senhaTxt" -ForegroundColor Yellow
    if ($Cfg.Compartilhado) { Write-Host "   Pasta Segura: $(if ($Cfg.PastaSegura) { 'sim' } else { 'não' })" -ForegroundColor Yellow }
    $pd = Pasta-Pendrive
    Write-Host ("   Pendrive: {0}" -f $(if ($pd) { $pd } else { 'não encontrado' })) -ForegroundColor Yellow
    Titulo 'Tarefas agendadas (\IFSP\)'
    Get-ScheduledTask -TaskPath '\IFSP\' -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host ('   {0,-22} {1}' -f $_.TaskName, $(switch ([string]$_.State) { 'Ready' { 'pronta' } 'Running' { 'rodando' } 'Disabled' { 'DESATIVADA' } 'Queued' { 'na fila' } default { [string]$_.State } })) }
    Titulo 'Horários agora (estado\horarios.json)'
    $arq = Join-Path $Base 'estado\horarios.json'
    if (Test-Path $arq) { Get-Content $arq | ForEach-Object { Write-Host "   $_" } } else { Write-Host '   (ainda sem estado)' }
    if (Test-Path $VeyonCli) {
        Titulo 'Veyon - chaves'
        (Rodar-Veyon authkeys list).Saida -split "`r?`n" | ForEach-Object { Write-Host "   $_" }
    }
    Titulo 'Últimas linhas do log do mês'
    $logMes = Join-Path $PastaLogs ('{0:yyyy-MM}.log' -f (Get-Date))
    if (Test-Path $logMes) { Get-Content $logMes -Tail 15 | ForEach-Object { Write-Host "   $_" } }
}

# ---- Logs
function Ler-LinhasLog([int]$Dias) {
    $desde = (Get-Date).Date.AddDays(-$Dias + 1)
    foreach ($a in (Get-ChildItem $PastaLogs -Filter '????-??.log' -ErrorAction SilentlyContinue | Sort-Object Name)) {
        foreach ($l in (Get-Content $a.FullName -Encoding UTF8)) {
            if ($l -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \|') {
                if ([datetime]$Matches[1] -ge $desde) { $l }
            }
        }
    }
}
function Tipo-DaLinha([string]$l) { $p = $l.Split('|'); if ($p.Count -ge 3) { return $p[2].Trim() } return '' }
function Mostrar-Consulta([string]$Nome, $Linhas) {
    $Linhas = @($Linhas)
    Titulo "$Nome ($($Linhas.Count) linha(s))"
    # na tela: data curta, sem o nome do PC e sem espaços sobrando (o arquivo completo abre no Bloco de Notas)
    $Linhas | Select-Object -Last 40 | ForEach-Object {
        $c = ([string]$_).Split('|')
        if ($c.Count -ge 4) {
            $d = try { '{0:dd/MM HH:mm}' -f [datetime]$c[0].Trim() } catch { $c[0].Trim() }
            Write-Host ('   {0}  {1}: {2}' -f $d, $c[2].Trim(), (($c[3..($c.Count - 1)] | ForEach-Object { $_.Trim() }) -join ' | '))
        } else { Write-Host "   $_" }
    }
    if ($Linhas.Count -gt 40) { Write-Host '   (mostrando só as 40 últimas)' -ForegroundColor DarkGray }
    if ($Linhas.Count -gt 0) {
        $arq = Join-Path $PastaLogs 'consulta.txt'
        $Linhas | Set-Content -Path $arq -Encoding UTF8
        if (Perguntar-SN 'Abrir a consulta completa no Bloco de Notas?') { Start-Process notepad.exe $arq }
    }
}
function Menu-Logs {
    Titulo 'Logs'
    Write-Host '   1 - Por usuário (ex.: Alunos)'
    Write-Host '   2 - Pendrives conectados e removidos'
    Write-Host '   3 - Regras de uso (aceites e recusas)'
    Write-Host '   4 - Impressão'
    Write-Host '   5 - Ligar, desligar e adiamentos'
    Write-Host '   6 - Manutenções e configurações'
    Write-Host '   7 - Log das instalações deste script'
    $op = Ler-Opcao 7
    if ($op -eq 0) { return }
    if ($op -eq 7) { Get-Content $LogArquivo -Tail 60 | ForEach-Object { Write-Host "   $_" }; return }
    $dias = Ler-NumeroOuVoltar 'Quantos dias para trás? (1 a 90)' 1 90
    if ($null -eq $dias) { $script:SemPausa = $true; return }
    $linhas = @(Ler-LinhasLog $dias)
    switch ($op) {
        1 {
            $usuarios = @($linhas | Where-Object { (Tipo-DaLinha $_) -eq 'LOGON' } | ForEach-Object { $_.Split('|')[3].Trim() } | Sort-Object -Unique)
            if ($usuarios.Count -gt 0) { Write-Host "   Usuários com logon no período: $($usuarios -join ', ')" }
            $u = (Perguntar 'Usuário (ENTER = todos)').Trim()
            if ($u) { $linhas = @($linhas | Where-Object { $_ -match [regex]::Escape($u) }) }
            Mostrar-Consulta "Log - usuário $(if ($u) { $u } else { 'todos' })" $linhas
        }
        2 { Mostrar-Consulta 'Pendrives' @($linhas | Where-Object { (Tipo-DaLinha $_) -like 'PENDRIVE*' }) }
        3 { Mostrar-Consulta 'Regras de uso' @($linhas | Where-Object { (Tipo-DaLinha $_) -like 'REGRAS*' }) }
        4 { Mostrar-Consulta 'Impressão' @($linhas | Where-Object { (Tipo-DaLinha $_) -eq 'IMPRESSAO' }) }
        5 { Mostrar-Consulta 'Ligar e desligar' @($linhas | Where-Object { (Tipo-DaLinha $_) -in 'PC LIGADO', 'DESLIGAR/REINICIAR', 'DESLIGAMENTO AUTO', 'ADIAMENTO', 'LOGOFF OCIOSO', 'LOGON', 'LOGOFF' }) }
        6 { Mostrar-Consulta 'Manutenções e configurações' @($linhas | Where-Object { (Tipo-DaLinha $_) -in 'MANUTENCAO', 'CONFIG', 'AVISO' }) }
    }
}

# ---- Limpezas
function Limpar-PastasDaConta {
    $u = Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue
    $perf = Perfil-DaConta $u
    if (-not $perf) { Write-Host "   A conta $($Cfg.Usuario) ainda não tem perfil; nada a limpar." -ForegroundColor Yellow; return }
    if ($perf.Loaded) { Write-Host "   A conta $($Cfg.Usuario) está em uso. Faça logoff dela e tente de novo." -ForegroundColor Yellow; return }
    if (-not $Cfg.Compartilhado) {
        Write-Host "   ATENÇÃO: este PC é administrativo (nada é apagado normalmente). Os arquivos de $($Cfg.Usuario) serão APAGADOS." -ForegroundColor Red
    }
    $txtSegura = if ($Cfg.PastaSegura) { ' (menos a Pasta Segura)' } else { '' }
    if (-not (Perguntar-SN "Apagar Área de Trabalho, Documentos, Downloads, Imagens, Vídeos, Músicas, temporários e lixeira de $($Cfg.Usuario)${txtSegura}?")) { return }
    $segura = if ($Cfg.PastaSegura) { Join-Path $perf.LocalPath "Desktop\$PastaSegura" } else { '' }
    foreach ($sub in 'Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos', 'Music', 'AppData\Local\Temp') {
        $pasta = Join-Path $perf.LocalPath $sub
        if (Test-Path -LiteralPath $pasta) {
            Get-ChildItem -LiteralPath $pasta -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne 'desktop.ini' -and $_.FullName -ne $segura -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $lix = 'C:\$Recycle.Bin\' + $u.SID.Value
    if (Test-Path -LiteralPath $lix) { Get-ChildItem -LiteralPath $lix -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    Registrar-Manutencao "Pastas da conta $($Cfg.Usuario) limpas pela manutenção"
}
function Recriar-PerfilDaConta {
    $u = Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue
    $perf = Perfil-DaConta $u
    if (-not $perf) { Write-Host "   A conta $($Cfg.Usuario) ainda não tem perfil." -ForegroundColor Yellow; return }
    if ($perf.Loaded) { Write-Host "   A conta $($Cfg.Usuario) está em uso. Faça logoff dela e tente de novo." -ForegroundColor Yellow; return }
    if (-not (Perguntar-SN "Apagar TODO o perfil de $($Cfg.Usuario) ($($perf.LocalPath))? Ele é recriado no próximo logon")) { return }
    $perf | Remove-CimInstance
    Registrar-Manutencao "Perfil da conta $($Cfg.Usuario) recriado do zero pela manutenção"
}
function Limpar-TemporariosWindows {
    $livreAntes = (Get-PSDrive C).Free
    Get-ChildItem 'C:\Windows\Temp' -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($perf in (Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special })) {
        $tmp = Join-Path $perf.LocalPath 'AppData\Local\Temp'
        if (Test-Path -LiteralPath $tmp) { Get-ChildItem -LiteralPath $tmp -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    }
    foreach ($lix in (Get-ChildItem 'C:\$Recycle.Bin' -Force -Directory -ErrorAction SilentlyContinue)) {
        Get-ChildItem -LiteralPath $lix.FullName -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    $mb = [math]::Round(((Get-PSDrive C).Free - $livreAntes) / 1MB)
    Registrar-Manutencao "Temporários do Windows e lixeiras limpos ($mb MB liberados)"
}
function Restaurar-HtdocsAgora {
    if (-not (Test-Path (Join-Path $Base 'htdocs-padrao'))) { Write-Host '   Não há cópia original da htdocs neste PC.' -ForegroundColor Yellow; return }
    $comBd = Test-Path (Join-Path $Base 'mysql-data-padrao')
    $txt = if ($comBd) { 'Apagar tudo em C:\xampp\htdocs e os bancos do MySQL e voltar ao original?' } else { 'Apagar tudo em C:\xampp\htdocs e voltar ao original? (este PC não tem padrão dos bancos)' }
    if (-not (Perguntar-SN $txt)) { return }
    Restaurar-Xampp
    Write-Host '   XAMPP de volta ao original.' -ForegroundColor Green
    Registrar-Manutencao 'htdocs e bancos do XAMPP restaurados pela manutenção'
}
function Limpar-FilaImpressao {
    Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
    Get-ChildItem 'C:\Windows\System32\spool\PRINTERS' -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Start-Service -Name Spooler -ErrorAction SilentlyContinue
    Registrar-Manutencao 'Fila de impressão limpa (spooler reiniciado)'
}
function Menu-Limpezas {
    Titulo 'Limpezas'
    Write-Host "   1 - Limpar agora as pastas da conta $($Cfg.Usuario) (as mesmas do logon)"
    Write-Host "   2 - Recriar do zero o perfil da conta $($Cfg.Usuario)"
    Write-Host '   3 - Limpar temporários do Windows e esvaziar todas as lixeiras'
    Write-Host '   4 - Voltar o XAMPP ao original (htdocs e bancos do MySQL)'
    Write-Host '   5 - Limpar a fila de impressão parada (documentos que não saem)'
    $semConta = ($Cfg.Tipo -eq 'CTI')
    switch (Ler-Opcao 5) {
        1 { if ($semConta) { Write-Host '   Este PC só tem a conta CTI (não há conta de uso para limpar).' -ForegroundColor Yellow } else { Limpar-PastasDaConta } }
        2 { if ($semConta) { Write-Host '   Este PC só tem a conta CTI (não há conta de uso para recriar).' -ForegroundColor Yellow } else { Recriar-PerfilDaConta } }
        3 { Limpar-TemporariosWindows }
        4 { Restaurar-HtdocsAgora }
        5 { Limpar-FilaImpressao }
    }
}

# ---- Teste de rede (Manutenção > Rede)
function Testar-Rede {
    foreach ($c in (Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Address })) {
        Write-Host ("   {0}: IP {1} | gateway {2} | DNS {3}" -f $c.InterfaceAlias, ($c.IPv4Address.IPAddress -join ', '),
                    ($c.IPv4DefaultGateway.NextHop -join ', '), (($c.DNSServer | Where-Object { $_.AddressFamily -eq 2 } | ForEach-Object { $_.ServerAddresses }) -join ', '))
        foreach ($gw in $c.IPv4DefaultGateway.NextHop) {
            $ok = Test-Connection -ComputerName $gw -Count 2 -Quiet
            Write-Host ("   Gateway {0}: {1}" -f $gw, $(if ($ok) { 'OK' } else { 'sem resposta' })) -ForegroundColor $(if ($ok) { 'Green' } else { 'Yellow' })
        }
    }
    Clear-DnsClientCache
    $dns = [bool](Resolve-DnsName 'www.ifsp.edu.br' -ErrorAction SilentlyContinue)
    Write-Host ("   DNS (www.ifsp.edu.br): {0}" -f $(if ($dns) { 'OK' } else { 'FALHA' })) -ForegroundColor $(if ($dns) { 'Green' } else { 'Red' })
    $net = Test-NetConnection -ComputerName 'www.google.com' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
    Write-Host ("   Internet (www.google.com:443): {0}" -f $(if ($net) { 'OK' } else { 'FALHA' })) -ForegroundColor $(if ($net) { 'Green' } else { 'Red' })
    Write-Host '   Cache de DNS limpo.'
}
# Saída de um programa do Windows: alguns escrevem em UTF-8, outros no código de página antigo do console
# (850): tenta UTF-8 e, se não for, usa o do console. Sem isso, os acentos saíam embaralhados ("pol├¡tica").
function Decodificar-Saida([byte[]]$Bytes) {
    if (-not $Bytes -or $Bytes.Length -eq 0) { return '' }
    try { return (New-Object System.Text.UTF8Encoding($false, $true)).GetString($Bytes) }
    catch { return [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage).GetString($Bytes) }
}
# Roda um programa do Windows (logoff, w32tm, quser, gpupdate...) e devolve a saída e o código.
# $Entrada: o que "digitar" se ele perguntar algo (ex.: 'N' para o gpupdate não fazer logoff).
function Rodar-Programa([string]$Exe, [string[]]$Argumentos, [string]$Entrada = '') {
    $out = [IO.Path]::GetTempFileName(); $err = [IO.Path]::GetTempFileName(); $in = $null
    try {
        $argTxt = (@($Argumentos) | Where-Object { $_ -ne $null } | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
        $p = @{ FilePath = $Exe; NoNewWindow = $true; Wait = $true; PassThru = $true; RedirectStandardOutput = $out; RedirectStandardError = $err }
        if ($argTxt) { $p.ArgumentList = $argTxt }
        if ($Entrada) { $in = [IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($in, "$Entrada`r`n"); $p.RedirectStandardInput = $in }
        $proc = Start-Process @p
        $txt = (Decodificar-Saida ([IO.File]::ReadAllBytes($out))) + (Decodificar-Saida ([IO.File]::ReadAllBytes($err)))
        return [pscustomobject]@{ Codigo = $proc.ExitCode; Saida = $txt.Trim() }
    } catch {
        return [pscustomobject]@{ Codigo = -1; Saida = $_.Exception.Message }
    } finally {
        Remove-Item -LiteralPath $out, $err -Force -ErrorAction SilentlyContinue
        if ($in) { Remove-Item -LiteralPath $in -Force -ErrorAction SilentlyContinue }
    }
}

# ---- Rotinas do Windows
function Acertar-Relogio {
    Titulo 'Acertar o relógio'
    $fuso = Get-TimeZone
    Write-Host ("   Hora agora: {0:dd/MM/yyyy HH:mm:ss}   Fuso: {1}" -f (Get-Date), $fuso.DisplayName)
    if ($FusoHorario -and $fuso.Id -ne $FusoHorario) {
        Write-Host "   O fuso deste PC não é o esperado ($FusoHorario)." -ForegroundColor Yellow
        if (Perguntar-SN 'Corrigir o fuso horário?') {
            Set-TimeZone -Id $FusoHorario
            Registrar-Manutencao "Fuso horário corrigido para $FusoHorario (Set-TimeZone)"
        }
    }
    Set-Service -Name w32time -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name w32time -ErrorAction SilentlyContinue
    if (Esta-NoDominio) {
        $args1 = @('/config', '/syncfromflags:domhier', '/update')
        $fonte = 'servidor do domínio'
    } else {
        $lista = (@($ServidoresHora -split '\s+' | Where-Object { $_ } | ForEach-Object { "$_,0x8" })) -join ' '
        $args1 = @('/config', "/manualpeerlist:$lista", '/syncfromflags:manual', '/reliable:no', '/update')
        $fonte = $ServidoresHora
    }
    $null = Rodar-Programa 'w32tm.exe' $args1
    Restart-Service -Name w32time -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    # Logo depois de religar o serviço, o Windows ainda não tem resposta do servidor ("não havia dados de hora
    # disponíveis") e mesmo assim devolve código 0: tenta até 3 vezes e só diz OK com a resposta certa.
    $sinc = $false; $r2 = $null
    foreach ($t in 1..3) {
        Start-Sleep -Seconds $(if ($t -eq 1) { 3 } else { 6 })
        $r2 = Rodar-Programa 'w32tm.exe' $(if ($t -eq 1) { @('/resync', '/rediscover') } else { @('/resync') })
        $falhou = ($r2.Codigo -ne 0) -or ($r2.Saida -match 'não sincronizou|não havia dados|did not resync|no time data|erro|error')
        if (-not $falhou) { $sinc = $true; break }
        Write-Host "   Tentativa $t de 3: o servidor de hora ainda não respondeu..." -ForegroundColor DarkGray
    }
    $src = (Rodar-Programa 'w32tm.exe' @('/query', '/source')).Saida
    Write-Host ("   Hora depois: {0:dd/MM/yyyy HH:mm:ss}   Fonte: {1}" -f (Get-Date), $src)
    if ($sinc) {
        Write-Host '   Relógio sincronizado.' -ForegroundColor Green
        Registrar-Manutencao "Relógio sincronizado (fonte $fonte; w32tm /resync)"
    } else {
        if ($r2 -and $r2.Saida) { $r2.Saida -split "`r?`n" | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray } }
        Write-Host '   NÃO sincronizou. A rede do campus pode bloquear a porta 123 (UDP): peça a liberação ou use o' -ForegroundColor Yellow
        Write-Host '   servidor de hora do roteador ($ServidoresHora na CONFIGURAÇÃO). O Windows tenta de novo sozinho.' -ForegroundColor Yellow
        Registrar-Manutencao "Relógio: NÃO sincronizou (fonte $fonte; w32tm /resync)"
    }
    Log-SoArquivo ("Relógio: w32tm {0}" -f ($args1 -join ' '))
}
function Atualizar-Politicas {
    Titulo 'Atualizar as políticas (gpupdate /force)'
    Write-Host '   Reaplica as políticas locais (e as do domínio, se houver). Pode levar 1 minuto.' -ForegroundColor DarkGray
    $r = Rodar-Programa 'gpupdate.exe' @('/force') 'N'     # 'N' = não fazer logoff/reiniciar se ele perguntar
    $r.Saida -split "`r?`n" | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "   $_" }
    Registrar-Manutencao "Políticas atualizadas (gpupdate /force; código $($r.Codigo))"
}
function Menu-Rotinas {
    Titulo 'Rotinas do Windows'
    Write-Host '   1 - Otimizar o disco C: (desfragmenta se for HD; TRIM se for SSD)'
    Write-Host '   2 - Verificar e reparar os arquivos do Windows (DISM + SFC; 10 a 30 min)'
    Write-Host '   3 - Verificar o disco C: (chkdsk agora; opção de verificação completa no próximo reinício)'
    Write-Host '   4 - Acertar o relógio (fuso e hora pela internet ou pelo domínio)'
    Write-Host '   5 - Atualizar as políticas agora (gpupdate /force)'
    Write-Host '   6 - Abrir o Windows Update'
    switch (Ler-Opcao 6) {
        1 {
            $disco = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq [string](Get-Partition -DriveLetter C).DiskNumber }
            Write-Host "   Disco do C: é $($disco.MediaType). O Windows escolhe a otimização certa." -ForegroundColor Cyan
            Optimize-Volume -DriveLetter C -Verbose
            Registrar-Manutencao "Disco C: otimizado ($($disco.MediaType); Optimize-Volume -DriveLetter C)"
        }
        2 {
            Start-Process -FilePath 'DISM.exe' -ArgumentList '/Online /Cleanup-Image /RestoreHealth' -NoNewWindow -Wait
            Start-Process -FilePath 'sfc.exe' -ArgumentList '/scannow' -NoNewWindow -Wait
            Registrar-Manutencao 'Arquivos do Windows verificados (DISM /Online /Cleanup-Image /RestoreHealth; sfc /scannow)'
        }
        3 {
            Start-Process -FilePath 'chkdsk.exe' -ArgumentList 'C: /scan' -NoNewWindow -Wait
            if (Perguntar-SN 'Agendar a verificação COMPLETA do C: para o próximo reinício?') {
                & fsutil.exe dirty set C: | Out-Null
                Registrar-Manutencao 'Verificação completa do disco C: agendada para o próximo reinício (fsutil dirty set C:)'
            } else { Registrar-Manutencao 'Disco C: verificado (chkdsk C: /scan)' }
        }
        4 { Acertar-Relogio }
        5 { Atualizar-Politicas }
        6 { Start-Process 'ms-settings:windowsupdate'; $script:SemPausa = $true }
    }
}

# ---- Diagnóstico
# Nome amigável de quem pediu o desligamento (evento 1074)
function Programa-Desligamento([string]$Exe) {
    switch -Regex ($Exe) {
        '^wmiprvse'                              { return 'o script (Restart-Computer)' }
        '^powershell'                            { return 'um script do PowerShell' }
        '^(StartMenuExperienceHost|explorer)'    { return 'o menu Iniciar' }
        '^(TrustedInstaller|msiexec|VCREDI|vc_redist|setup)' { return "um instalador ($Exe)" }
        '^(MoNotificationUx|MusNotification|usoclient|svchost)' { return 'o Windows Update' }
        '^CloudExperienceHostBroker'             { return 'a configuração inicial do Windows' }
        '^shutdown'                              { return 'o comando shutdown' }
        '^veyon'                                 { return 'o Veyon' }
        default                                  { return $Exe }
    }
}
function Ver-Reinicios {
    $so = Get-CimInstance Win32_OperatingSystem
    $ligado = (Get-Date) - $so.LastBootUpTime
    Titulo 'Por que o PC desligou ou reiniciou (últimos eventos)'
    Write-Host ("   Ligado desde {0:dd/MM/yyyy HH:mm} (há {1} dia(s) e {2} h)" -f $so.LastBootUpTime, $ligado.Days, $ligado.Hours) -ForegroundColor Cyan
    $evs = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 41, 1074, 1076, 6005, 6006, 6008 } -MaxEvents 120 -ErrorAction SilentlyContinue |
             Where-Object { ($_.Id -eq 41 -and $_.ProviderName -eq 'Microsoft-Windows-Kernel-Power') -or
                            ($_.Id -in 1074, 1076 -and $_.ProviderName -eq 'User32') -or
                            ($_.Id -in 6005, 6006, 6008 -and $_.ProviderName -eq 'EventLog') } | Select-Object -First 25)
    if ($evs.Count -eq 0) { Write-Host '   Nenhum evento encontrado.' -ForegroundColor Yellow; return }
    foreach ($e in $evs) {
        $cor = 'Gray'
        switch ($e.Id) {
            6005 { $txt = 'Windows iniciou'; $cor = 'DarkGray' }
            6006 { $txt = 'Windows desligou normalmente'; $cor = 'DarkGray' }
            6008 { $txt = 'Desligamento INESPERADO antes deste (energia, travamento ou botão)'; $cor = 'Red' }
            41   { $txt = 'Reiniciou sem desligar direito (energia, travamento ou botão)'; $cor = 'Red' }
            1076 { $txt = 'Motivo informado para o desligamento inesperado'; $cor = 'Yellow' }
            1074 {
                $p = $e.Properties
                $exe = Split-Path ([string]$p[0].Value -replace '\s*\(.*$', '') -Leaf
                $tipo = [string]$p[4].Value
                $tipo = if ($tipo -match '^(rein|restart)') { 'Reiniciar' } elseif ($tipo -match '^(deslig|power|shut)') { 'Desligar' } elseif ($tipo) { $tipo.Substring(0,1).ToUpper() + $tipo.Substring(1) } else { 'Desligar' }
                $usu = [string]$p[6].Value
                $usu = if ($usu -match 'SISTEMA|SYSTEM') { 'Windows' } else { $usu.Split('\')[-1] }
                $quem = Programa-Desligamento $exe
                $txt = "$tipo - $usu, por $quem"
                $motivo = [string]$p[2].Value
                if ($motivo -and $motivo -notmatch 'Não foi encontrado|No title|^Outro|^Other') { $txt += " ($(Cortar $motivo 40))" }
                if ($quem -like 'um instalador*' -or $quem -eq 'o Windows Update') { $cor = 'Yellow' }
            }
        }
        Write-Host ('   {0:dd/MM HH:mm}  {1}' -f $e.TimeCreated, (Cortar $txt 95)) -ForegroundColor $cor
    }
    Write-Host '   O desligamento das 23:30 do script fica no log "Ligar, desligar e adiamentos" (Manutenção > Logs).' -ForegroundColor DarkGray
}
function Programas-Instalados {
    $chaves = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    return @(Get-ItemProperty -Path $chaves -ErrorAction SilentlyContinue |
             Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 -and -not $_.ParentKeyName } |
             Sort-Object DisplayName -Unique)
}
function Ver-Versoes {
    $v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $so = Get-CimInstance Win32_OperatingSystem
    Titulo 'Windows'
    Write-Host ("   {0} {1} (build {2}.{3})" -f $so.Caption, $v.DisplayVersion, $v.CurrentBuild, $v.UBR)
    $progs = Programas-Instalados
    Titulo 'Programas principais'
    foreach ($d in $ProgramasDestaque) {
        $achou = @($progs | Where-Object { $_.DisplayName -like "*$d*" })
        foreach ($p in $achou) { Write-Host ('   {0,-58} {1}' -f $p.DisplayName, $p.DisplayVersion) }
        if ($d -eq 'XAMPP' -and $achou.Count -eq 0) {
            $vx = Versao-XamppPC
            if ($vx) { Write-Host ('   {0,-58} {1}' -f 'XAMPP (C:\xampp)', $vx) }
        }
    }
    Write-Host "   ($($progs.Count) programas instalados no total)" -ForegroundColor DarkGray
    if (Perguntar-SN 'Ver a lista completa (abre no Bloco de Notas)?') {
        $arq = Join-Path $PastaLogs 'programas.txt'
        $progs | ForEach-Object { '{0} | {1} | {2}' -f $_.DisplayName, $_.DisplayVersion, $_.Publisher } | Set-Content -Path $arq -Encoding UTF8
        Start-Process notepad.exe $arq
    }
}
function Ver-DiscoSaude {
    Titulo 'Discos'
    $saude = @{ Healthy = 'BOM'; Warning = 'ATENÇÃO'; Unhealthy = 'RUIM' }
    foreach ($d in (Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { [string]$_.BusType -ne 'USB' })) {   # pendrives e HDs USB fora
        $h = [string]$d.HealthStatus
        $txtH = if ($saude.ContainsKey($h)) { $saude[$h] } else { $h }
        Write-Host ("   {0} | {1} | {2} | {3:N0} GB | saúde: {4}" -f $d.FriendlyName, $d.MediaType, $d.BusType, ($d.Size / 1GB), $txtH) -ForegroundColor $(if ($h -eq 'Healthy') { 'Green' } else { 'Red' })
        $rc = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
        if ($rc) {
            $det = @()
            if ($rc.Temperature)  { $det += "temperatura $($rc.Temperature) °C" }
            if ($null -ne $rc.Wear) { $det += "desgaste $($rc.Wear)%" }
            if ($rc.PowerOnHours) { $det += "$($rc.PowerOnHours) h ligado" }
            if ($rc.ReadErrorsTotal -or $rc.WriteErrorsTotal) { $det += "erros: leitura $($rc.ReadErrorsTotal), gravação $($rc.WriteErrorsTotal)" }
            if ($det.Count) { Write-Host "     $($det -join ' | ')" -ForegroundColor DarkGray }
        }
    }
    Titulo 'Espaço livre'
    foreach ($vol in (Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and $_.Size -gt 0 } | Sort-Object DriveLetter)) {
        $pct = [math]::Round(100 * $vol.SizeRemaining / $vol.Size)
        Write-Host ("   {0}: {1:N0} GB livres de {2:N0} GB ({3}%)" -f $vol.DriveLetter, ($vol.SizeRemaining / 1GB), ($vol.Size / 1GB), $pct) -ForegroundColor $(if ($pct -lt 10) { 'Red' } elseif ($pct -lt 20) { 'Yellow' } else { 'Green' })
    }
    $so = Get-CimInstance Win32_OperatingSystem
    Titulo 'Memória'
    Write-Host ("   {0:N1} GB no total, {1:N1} GB livres agora" -f ($so.TotalVisibleMemorySize / 1MB), ($so.FreePhysicalMemory / 1MB))
}
function Ver-TarefasScript {
    Titulo 'Tarefas do script (\IFSP\) e o último resultado'
    $estados = @{ Ready = 'pronta'; Running = 'rodando'; Disabled = 'DESATIVADA'; Queued = 'na fila' }
    $codigos = @{ '0' = 'OK'; '267009' = 'rodando agora'; '267011' = 'ainda não rodou'; '267014' = 'encerrada'; '1' = 'erro (código 1)' }
    $tarefas = @(Get-ScheduledTask -TaskPath '\IFSP\' -ErrorAction SilentlyContinue)
    if ($tarefas.Count -eq 0) { Write-Host '   Nenhuma tarefa do script neste PC.' -ForegroundColor Yellow; return }
    Write-Host ('   {0,-22} {1,-11} {2,-17} {3,-26} {4}' -f 'Tarefa', 'Estado', 'Última vez', 'Resultado', 'Próxima') -ForegroundColor Cyan
    foreach ($t in $tarefas) {
        $i = $t | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
        $est = [string]$t.State; if ($estados.ContainsKey($est)) { $est = $estados[$est] }
        $ult = if ($i -and $i.LastRunTime -and $i.LastRunTime.Year -gt 2000) { '{0:dd/MM HH:mm:ss}' -f $i.LastRunTime } else { '(nunca)' }
        $prox = if ($i -and $i.NextRunTime) { '{0:dd/MM HH:mm}' -f $i.NextRunTime } else { '-' }
        $cod = if ($i) { [int64]$i.LastTaskResult } else { -1 }
        $res = if ($codigos.ContainsKey([string]$cod)) { $codigos[[string]$cod] } else { 'erro 0x{0:X}' -f $cod }
        $cor = if ($cod -in 0, 267009, 267011) { 'Green' } else { 'Yellow' }
        if ([string]$t.State -eq 'Disabled') { $cor = 'Red' }
        Write-Host ('   {0,-22} {1,-11} {2,-17} {3,-26} {4}' -f $t.TaskName, $est, $ult, $res, $prox) -ForegroundColor $cor
    }
}
function Menu-Diagnostico {
    Titulo 'Diagnóstico'
    Write-Host '   1 - Por que o PC desligou ou reiniciou (últimos eventos)'
    Write-Host '   2 - Versões do Windows e dos programas'
    Write-Host '   3 - Disco e saúde (SMART, espaço livre, memória)'
    Write-Host '   4 - Tarefas do script e o último resultado de cada uma'
    switch (Ler-Opcao 4) {
        1 { Ver-Reinicios }
        2 { Ver-Versoes }
        3 { Ver-DiscoSaude }
        4 { Ver-TarefasScript }
    }
}

# ---- Contas locais
function Contas-ParaLista {
    # sem as contas internas escondidas (Convidado, DefaultAccount, WDAGUtilityAccount); o Administrador interno (500) aparece
    return @(Get-LocalUser | Where-Object { $_.SID.Value -notmatch '-(501|503|504)$' } | Sort-Object Name)
}
function Conta-Bloqueada([string]$Nome) {
    try { return [bool](([ADSI]"WinNT://$env:COMPUTERNAME/$Nome,user").InvokeGet('IsAccountLocked')) } catch { return $false }
}
function Mostrar-Contas {
    $admins = @(Get-LocalGroupMember -SID $SID_Admins -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.SID })
    $contas = Contas-ParaLista
    Write-Host ('   {0,-3} {1,-20} {2,-11} {3,-10} {4,-7} {5,-17} {6}' -f 'Nº', 'Conta', 'Ativa', 'Bloqueada', 'Admin', 'Último logon', 'Papel') -ForegroundColor Cyan
    $n = 0
    foreach ($u in $contas) {
        $n++
        $bloq = Conta-Bloqueada $u.Name
        $papel = if ($u.Name -eq $ContaAdmin) { 'CTI (administradora)' } elseif ($u.Name -eq [string]$Cfg.Usuario) { 'conta de uso' } elseif ($u.SID.Value -match '-500$') { 'Administrador interno' } else { '' }
        $ult = if ($u.LastLogon) { '{0:dd/MM/yy HH:mm}' -f $u.LastLogon } else { '(nunca)' }
        $cor = if ($bloq) { 'Red' } elseif (-not $u.Enabled) { 'DarkGray' } else { 'Gray' }
        Write-Host ('   {0,-3} {1,-20} {2,-11} {3,-10} {4,-7} {5,-17} {6}' -f $n, $u.Name, $(if ($u.Enabled) { 'sim' } else { 'desativada' }),
                    $(if ($bloq) { 'SIM' } else { 'não' }), $(if ($admins -contains $u.SID.Value) { 'sim' } else { '' }), $ult, $papel) -ForegroundColor $cor
    }
    return $contas
}
function Menu-Contas {
    Titulo 'Contas locais deste PC'
    $contas = @(Mostrar-Contas)
    $wl = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue
    $auto = ([string]$wl.AutoAdminLogon -eq '1')
    Write-Host ''
    Write-Host ('   Logon automático: {0}' -f $(if ($auto) { "LIGADO (entra sozinho na conta $($wl.DefaultUserName))" } else { 'desligado (o PC mostra a tela de login)' })) -ForegroundColor Yellow
    Write-Host ''
    Write-Host '   1 - Desbloquear uma conta (travada por senhas erradas) ou ativar uma conta desativada'
    Write-Host '   2 - Logon automático: ligar ou desligar'
    switch (Ler-Opcao 2) {
        1 {
            $n = Ler-NumeroOuVoltar "Número da conta (1 a $($contas.Count))" 1 $contas.Count
            if ($null -eq $n) { $script:SemPausa = $true; return }
            $u = $contas[$n - 1]
            $bloq = Conta-Bloqueada $u.Name
            if (-not $bloq -and $u.Enabled) { Write-Host "   A conta $($u.Name) não está bloqueada nem desativada." -ForegroundColor Green; return }
            if ($bloq) {
                $adsi = [ADSI]"WinNT://$env:COMPUTERNAME/$($u.Name),user"
                $adsi.InvokeSet('IsAccountLocked', $false)
                $adsi.CommitChanges()
                Registrar-Manutencao "Conta $($u.Name) desbloqueada (ADSI WinNT IsAccountLocked = false)"
            }
            if (-not $u.Enabled) {
                if ($u.SID.Value -match '-500$') { Write-Host '   O Administrador interno fica desativado de propósito (use a conta CTI).' -ForegroundColor Yellow }
                elseif (Perguntar-SN "A conta $($u.Name) está desativada. Ativar?") {
                    Enable-LocalUser -SID $u.SID
                    Registrar-Manutencao "Conta $($u.Name) ativada (Enable-LocalUser)"
                }
            }
        }
        2 {
            if ($Cfg.Tipo -eq 'CTI') { Write-Host '   Este PC só tem a conta CTI, que sempre tem senha: não há logon automático.' -ForegroundColor Yellow; return }
            if ($auto) {
                Write-Host '   Desligado, o PC mostra a tela de login ao ligar. Se a conta de uso não tiver senha, basta clicar nela.' -ForegroundColor DarkGray
                if (Perguntar-SN 'Desligar o logon automático?') {
                    Definir-Autologon $false
                    Registrar-Manutencao 'Logon automático desligado (Winlogon AutoAdminLogon = 0)'
                }
            } else {
                if (Esta-NoDominio) { Write-Host '   Este PC está no domínio: cada pessoa entra com o próprio login (sem logon automático).' -ForegroundColor Yellow; return }
                $tem = Conta-TemSenha $Cfg.Usuario
                if ($tem -ne $false) { Write-Host "   A conta $($Cfg.Usuario) tem senha (ou não deu para verificar): tire a senha em Manutenção > Senha da conta de uso; isso já liga o logon automático." -ForegroundColor Yellow; return }
                if (Perguntar-SN "Ligar o logon automático na conta $($Cfg.Usuario)?") {
                    Definir-Autologon $true
                    Registrar-Manutencao "Logon automático ligado na conta $($Cfg.Usuario) (Winlogon AutoAdminLogon = 1)"
                }
            }
        }
    }
}

# ---- Sessão: quem está logado, mensagem, encerrar
function Sessoes-Logadas {
    $r = Rodar-Programa 'quser.exe' @()
    $lista = @()
    foreach ($l in ($r.Saida -split "`r?`n" | Select-Object -Skip 1)) {
        if ($l -match '^[\s>]*(\S+)\s+(?:(\S+)\s+)?(\d+)\s+(\S+)') {
            $lista += [pscustomobject]@{ Usuario = $Matches[1]; Id = [int]$Matches[3]; Estado = $Matches[4]; Atual = ($l -match '^\s*>') }
        }
    }
    return $lista
}
function Menu-Sessao {
    Titulo 'Sessões abertas neste PC'
    $sess = @(Sessoes-Logadas)
    $minha = (Get-Process -Id $PID).SessionId
    if ($sess.Count -eq 0) { Write-Host '   Ninguém logado (ou o Windows não informou).' -ForegroundColor Yellow }
    foreach ($s in $sess) {
        $est = if ($s.Estado -match '^(Ativo|Active)') { 'ativa' } else { "desconectada ($($s.Estado))" }
        $eu  = if ($s.Id -eq $minha) { '  << você (esta janela)' } else { '' }
        Write-Host ('   Sessão {0}: {1} - {2}{3}' -f $s.Id, $s.Usuario, $est, $eu)
    }
    Write-Host '   Uma sessão "desconectada" é de alguém que trocou de usuário sem sair (continua aberta, ocupando memória).' -ForegroundColor DarkGray
    $outras = @($sess | Where-Object { $_.Id -ne $minha })
    if ($outras.Count -eq 0) { Write-Host '   Não há outra sessão além da sua.' -ForegroundColor Green; return }
    Write-Host ''
    $id = Ler-NumeroOuVoltar 'Número da sessão a encerrar (logoff)' 1 999
    if ($null -eq $id) { $script:SemPausa = $true; return }
    $alvo = $outras | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    if (-not $alvo) { Write-Host "   Sessão $id não encontrada (ou é a sua)." -ForegroundColor Yellow; return }
    Write-Host "   ATENÇÃO: o que $($alvo.Usuario) não salvou será perdido." -ForegroundColor Red
    if (-not (Perguntar-SN "Encerrar a sessão de $($alvo.Usuario) agora?")) { return }
    Write-Host '   Encerrando... pode levar alguns segundos (nos PCs compartilhados, a limpeza da conta roda ao sair).' -ForegroundColor DarkGray
    $r = Rodar-Programa 'logoff.exe' @([string]$id)
    if ($r.Codigo -eq 0) { Registrar-Manutencao "Sessão de $($alvo.Usuario) encerrada pela CTI (logoff $id)" }
    else { Write-Host "   Não deu para encerrar ($($r.Saida))." -ForegroundColor Yellow }
}

# ---- Rede
function Ver-PlacasRede {
    Titulo 'Placas de rede: IP, MAC e Wake-on-LAN'
    foreach ($n in (Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $tipo = if ($n.MediaType -eq '802.3') { 'cabo' } elseif ($n.MediaType -match '802\.11') { 'Wi-Fi' } else { [string]$n.MediaType }
        $ip = @(Get-NetIPAddress -InterfaceIndex $n.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254.*' } | ForEach-Object { $_.IPAddress }) -join ', '
        $wol = ''
        if ($tipo -eq 'cabo') {
            $wol = if (WoL-Ligado $n.Name) { 'WoL: ligado' } else { 'WoL: DESLIGADO (opção 3)' }
        }
        $cor = if ($n.Status -eq 'Up') { 'Green' } else { 'DarkGray' }
        Write-Host ("   {0} ({1}) - {2}" -f $n.Name, $tipo, $n.InterfaceDescription) -ForegroundColor $cor
        Write-Host ("     {0} | {1} | MAC {2} | IP {3}{4}" -f $n.Status, $n.LinkSpeed, $n.MacAddress, $(if ($ip) { $ip } else { '-' }), $(if ($wol) { " | $wol" } else { '' }))
    }
    $hb = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -ErrorAction SilentlyContinue).HiberbootEnabled
    Write-Host ("   Inicialização rápida do Windows: {0}" -f $(if ($hb -eq 0) { 'desligada (bom para o Wake-on-LAN)' } else { 'LIGADA (atrapalha o Wake-on-LAN; opção 3 desliga)' })) -ForegroundColor $(if ($hb -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host '   O Wake-on-LAN só funciona pela placa com cabo (no Wi-Fi não). Na BIOS: WoL ligado e ErP desligado.' -ForegroundColor DarkGray
}
function Menu-Rede {
    Titulo 'Rede'
    Write-Host '   1 - Placas de rede: IP, MAC e Wake-on-LAN'
    Write-Host '   2 - Testar a rede (IP, gateway, DNS e internet) e limpar o cache de DNS'
    Write-Host '   3 - Preparar o Wake-on-LAN de novo (placas com cabo; desliga a inicialização rápida)'
    Write-Host '   4 - Veyon: serviço, porta 11100 e chaves'
    Write-Host '   5 - GLPI: o servidor responde?'
    switch (Ler-Opcao 5) {
        1 { Ver-PlacasRede }
        2 { Testar-Rede; Registrar-Manutencao 'Rede testada e cache de DNS limpo (Clear-DnsClientCache)' }
        3 { Preparar-WakeOnLan; Registrar-Manutencao 'Wake-on-LAN preparado de novo (Set-NetAdapterPowerManagement / *WakeOnMagicPacket; HiberbootEnabled = 0)' }
        4 { Diagnostico-Veyon }
        5 { [void](Testar-ServidorGlpi) }
    }
}

# ---- Horários
function Menu-Horarios {
    Titulo 'Horários (desligamento automático às 23:30)'
    Write-Host ('   ' + (Texto-Horarios $Cfg.Horarios)) -ForegroundColor Yellow
    Write-Host '   1 - Pausar os horários por algumas horas (ex.: atividade extra, competição)'
    Write-Host '   2 - Reativar os horários agora'
    Write-Host '   3 - Testar o desligamento com tempos curtos (desliga em 5 min; aviso 3 min antes)'
    Write-Host '   4 - Voltar os horários ao normal'
    Write-Host '   5 - Desativar o desligamento automático permanentemente (NÃO RECOMENDADO)' -ForegroundColor Red
    $opH = Ler-Opcao 5
    if ($opH -eq 0) { return }
    switch ($opH) {
        1 {
            $hs = Ler-NumeroOuVoltar 'Pausar por quantas horas? (1-48)' 1 48
            if ($null -eq $hs) { $script:SemPausa = $true; return }
            $Cfg.Horarios.PausadoAte = (Get-Date).AddHours($hs).ToString('yyyy-MM-dd HH:mm')
            Salvar-Config; Limpar-EstadoHorarios
            Registrar-Manutencao "Horários pausados até $($Cfg.Horarios.PausadoAte)"
        }
        2 {
            $Cfg.Horarios.PausadoAte = ''
            Salvar-Config
            Registrar-Manutencao 'Horários reativados'
        }
        5 {
            Write-Host ''
            Write-Host '   ATENÇÃO: este PC não vai mais desligar sozinho às 23:30, até alguém reativar' -ForegroundColor Red
            Write-Host '   (Manutenção > Horários > 2). Ele pode passar a noite e o fim de semana ligado.' -ForegroundColor Red
            if (Perguntar-SN 'Desativar permanentemente?') {
                $Cfg.Horarios.PausadoAte = '9999-12-31 23:59'
                Salvar-Config; Limpar-EstadoHorarios
                Registrar-Manutencao 'Desligamento automático DESATIVADO PERMANENTEMENTE'
            }
        }
        3 {
            Horarios-Normais
            $h = $Cfg.Horarios
            $h.Teste    = $true
            $h.TesteAte = (Get-Date).AddMinutes(30).ToString('yyyy-MM-dd HH:mm')
            $h.Desligar = (Get-Date).AddMinutes(5).ToString('HH:mm'); $h.AvisoMin = 3; $h.AdiarMin = 3
            Salvar-Config; Limpar-EstadoHorarios
            Registrar-Manutencao "Teste do desligamento até $($h.TesteAte): $(Texto-Horarios $h)"
            Write-Host ''
            Write-Host "   Desliga às $($h.Desligar). O aviso (com Adiar 3 min) aparece 3 min antes." -ForegroundColor Cyan
            Write-Host '   IMPORTANTE: com a CTI logada o PC não desliga. Faça logoff da CTI e entre na conta de uso' -ForegroundColor Cyan
            Write-Host '   (ou fique na tela de login, que desliga sem aviso).' -ForegroundColor Cyan
            Write-Host '   O teste volta sozinho ao normal em 30 min (ou logo depois de desligar o PC).' -ForegroundColor Cyan
        }
        4 {
            Horarios-Normais; Salvar-Config; Limpar-EstadoHorarios
            Registrar-Manutencao 'Horários voltaram ao normal'
        }
    }
    Start-ScheduledTask -TaskPath '\IFSP\' -TaskName 'Horarios' -ErrorAction SilentlyContinue   # aplica já
}

# ---- Favoritos (Manutenção)
function Menu-Favoritos {
    $comMoodle = [bool]$Cfg.Compartilhado -and [bool]$Cfg.Moodle
    $itens = @(Ler-ListaFavoritos ([string]$Cfg.Favoritos))
    Titulo ('Favoritos do Chrome e do Edge (pasta "{0}" na barra; todos os usuários do PC)' -f $PastaFavoritos)
    Mostrar-Favoritos $itens $comMoodle
    Write-Host ''
    Mostrar-FormatoFavoritos
    Write-Host ''
    Write-Host '   1 - Incluir favoritos'
    Write-Host '   2 - Tirar um favorito'
    Write-Host '   3 - Trocar a lista inteira'
    Write-Host '   4 - Gravar a lista deste PC no pendrive (sugestão para os próximos PCs deste perfil no campus)'
    $op = Ler-Opcao 4
    if ($op -eq 0) { return }
    $nova = $null
    switch ($op) {
        1 { $r = (Perguntar 'Favoritos a incluir (ENTER = voltar)').Trim()
            if ($r) { $nova = @($itens) + @(Ler-ListaFavoritos $r) } }
        2 {
            if ($itens.Count -eq 0) { Write-Host '   Não há favoritos para tirar (a pasta IFSP é fixa).' -ForegroundColor Yellow }
            else {
                for ($i = 0; $i -lt $itens.Count; $i++) { Write-Host ('  {0,2} - {1}' -f ($i + 1), (Texto-ListaFavoritos @($itens[$i]))) }
                $e = Ler-NumeroOuVoltar "Qual tirar? (1 a $($itens.Count))" 1 $itens.Count
                if ($null -eq $e) { $script:SemPausa = $true; return }
                $nova = @()
                for ($i = 0; $i -lt $itens.Count; $i++) { if ($i -ne ($e - 1)) { $nova += $itens[$i] } }
            }
        }
        3 { $r = (Perguntar 'Nova lista (0 = sem outros favoritos; ENTER = voltar)').Trim()
            if ($r -eq '0') { $nova = @() } elseif ($r) { $nova = @(Ler-ListaFavoritos $r) } }
        4 {
            if (-not (Pasta-Pendrive)) { Write-Host '   Pendrive com a pasta ManutencaoIFSP não encontrado.' -ForegroundColor Yellow }
            else {
                if (-not ($Cfg.PSObject.Properties.Name -contains 'Favoritos')) { Definir-CampoCfg 'Favoritos' '' }
                Gravar-DadosCampus
                Registrar-Manutencao "Favoritos deste PC gravados no pendrive (lista $(Perfil-Favoritos $Cfg))"
            }
        }
    }
    if ($null -ne $nova) {
        Definir-CampoCfg 'Favoritos' (Texto-ListaFavoritos $nova); Salvar-Config
        Aplicar-Favoritos
        Registrar-Manutencao "Favoritos alterados pela manutenção: $($Cfg.Favoritos)"
        Write-Host ''
        Mostrar-Favoritos @(Ler-ListaFavoritos ([string]$Cfg.Favoritos)) $comMoodle
        Write-Host '   Vale ao abrir o Chrome e o Edge de novo (feche os que estiverem abertos).' -ForegroundColor Cyan
        Write-Host '   Para usar esta lista nos próximos PCs do campus: opção 4 (com o pendrive).' -ForegroundColor DarkGray
    }
}

# ---- Pop-up de logon
# Textos do pop-up deste PC: regras.txt (regras ou aviso) e pasta-segura.txt (linha a mais com a Pasta Segura)
function Textos-Popup {
    if ($Cfg.ContaAlunos) {
        # o texto segue o LUGAR (lab, biblioteca ou outro), não os programas instalados
        $base = if ($Cfg.Tipo -like 'LAB-*') { $RegrasLab } elseif ((Espaco-DoCfg $Cfg) -eq 'CBI') { $RegrasBiblioteca } else { $RegrasOutrosLocais }
        return @{ Linhas = @($base); PastaSegura = $AvisoPastaSeguraAluno; Final = [string]$AvisoFinalAlunos }
    }
    return @{ Linhas = @($AvisoProfessor); PastaSegura = $AvisoPastaSeguraProf; Final = '' }
}
function Gravar-TextosPopup {
    if (-not $Cfg.Compartilhado) { return }
    $tx = Textos-Popup
    $utf8 = New-Object System.Text.UTF8Encoding($true)
    [IO.File]::WriteAllLines((Join-Path $Base 'regras.txt'), [string[]]@($tx.Linhas | Select-Object -Unique), $utf8)
    # texto vazio = sem arquivo (ex.: o aviso final não existe nos PCs de professores)
    foreach ($par in @(@('pasta-segura.txt', [string]$tx.PastaSegura), @('aviso-final.txt', [string]$tx.Final))) {
        $arq = Join-Path $Base $par[0]
        if ($par[1].Trim()) { [IO.File]::WriteAllText($arq, $par[1].Trim(), $utf8) }
        else { Remove-Item -LiteralPath $arq -Force -ErrorAction SilentlyContinue }
    }
}
function Menu-Popup {
    if (-not $Cfg.Compartilhado) { Write-Host '   Este tipo de PC não tem pop-up de logon (nada é apagado nele).' -ForegroundColor Yellow; return }
    $ligado = -not ($Cfg.PSObject.Properties.Name -contains 'PopupLogon') -or [bool]$Cfg.PopupLogon
    $tipoTxt = if ($Cfg.ContaAlunos) { "regras de uso para a conta $($Cfg.Usuario) (Aceito / Não aceito)" } else { "aviso para a conta $($Cfg.Usuario) (Entendi)" }
    Titulo 'Pop-up de logon'
    Write-Host "   Tipo: $tipoTxt"
    if ($ligado) { Write-Host '   Situação: LIGADO (aparece a cada logon)' -ForegroundColor Green }
    else         { Write-Host '   Situação: DESLIGADO' -ForegroundColor Red }
    Write-Host ''
    Write-Host '   Texto:' -ForegroundColor DarkGray
    $tx = Textos-Popup
    $linhas = @($tx.Linhas)
    if ($Cfg.PastaSegura) { $linhas += $tx.PastaSegura }
    if ($tx.Final)        { $linhas += $tx.Final }
    $linhas = @($linhas | Where-Object { $_ } | Select-Object -Unique)
    foreach ($l in $linhas) { Write-Host ("    {0} {1}" -f [char]0x2022, $l) -ForegroundColor DarkGray }
    Write-Host '   (para mudar o texto: $RegrasLab, $RegrasBiblioteca, $RegrasOutrosLocais, $AvisoFinalAlunos e $AvisoProfessor' -ForegroundColor DarkGray
    Write-Host '    na CONFIGURAÇÃO do script; depois, Reaplicar ou ligar/desligar aqui)' -ForegroundColor DarkGray
    Write-Host ''
    if ($ligado) { Write-Host '   1 - Desligar o pop-up' } else { Write-Host '   1 - Ligar o pop-up' }
    if ((Ler-Opcao 1) -eq 1) {
        Definir-CampoCfg 'PopupLogon' (-not $ligado); Salvar-Config
        Gravar-TextosPopup
        Registrar-Manutencao $(if ($ligado) { 'Pop-up de logon DESLIGADO' } else { 'Pop-up de logon ligado' })
        Write-Host '   Vale no próximo logon.' -ForegroundColor Cyan
    }
}

# ---- Bloqueios
# Lista: cada bloqueio deste PC com a situação; escolhe um (ou todos) e depois a ação.
function Menu-Bloqueios {
    while ($true) {
        Mostrar-Cabecalho
        Titulo 'Bloqueios deste computador (a conta CTI nunca é bloqueada)'
        $lista = @(Bloqueios-DoPC)
        $temVS = [bool]$Cfg.LabInfo -and (Test-Path $CodeExe)
        if ($lista.Count -eq 0 -and -not $temVS) { Write-Host '   Este tipo de PC não tem bloqueios.' -ForegroundColor Yellow; return }
        for ($i = 0; $i -lt $lista.Count; $i++) {
            $n = $lista[$i]
            Write-Host ('  {0,2} - {1}' -f ($i + 1), (Desc-Bloqueio $n))
            Write-Host ('       {0}' -f (Texto-Bloqueio $n)) -ForegroundColor (Cor-Bloqueio $n)
            Write-Host ''
        }
        $max = $lista.Count
        $nTodos = 0; $nVS = 0
        if ($lista.Count -gt 1) { $max++; $nTodos = $max; Write-Host ('  {0,2} - Todos os bloqueios acima' -f $nTodos) }
        if ($temVS) { $max++; $nVS = $max; Write-Host ('  {0,2} - VS Code: extensões (os alunos não instalam; a CTI instala e remove por aqui)' -f $nVS) }
        $script:SemPausa = $false
        $op = Ler-Opcao $max
        if ($op -eq 0) { return }
        if ($op -eq $nVS) { Menu-ExtensoesVSCode }
        elseif ($op -eq $nTodos) { Menu-UmBloqueio $lista }
        else { Menu-UmBloqueio @($lista[$op - 1]) }
        if (-not $script:SemPausa) { Pausa }
    }
}

# Ação sobre um ou mais bloqueios: desbloquear por horas, desbloquear permanentemente ou bloquear de novo
function Menu-UmBloqueio([string[]]$Nomes) {
    Write-Host ''
    if ($Nomes.Count -eq 1) {
        Titulo "Bloqueio: $(Desc-Bloqueio $Nomes[0])"
        Write-Host "   Situação: $(Texto-Bloqueio $Nomes[0])" -ForegroundColor (Cor-Bloqueio $Nomes[0])
        if ($Nomes[0] -eq 'Barra') { Write-Host '   Para mudar a barra de uma conta: desbloquear, entrar na conta, arrumar a barra e bloquear de novo.' -ForegroundColor DarkGray }
    } else {
        Titulo 'Todos os bloqueios deste computador'
    }
    Write-Host '   1 - Desbloquear por algumas horas (volta a bloquear sozinho)'
    Write-Host '   2 - Desbloquear permanentemente (NÃO RECOMENDADO)' -ForegroundColor Red
    Write-Host '   3 - Bloquear de novo agora'
    $acao = Ler-Opcao 3
    if ($acao -eq 0) { return }
    $ate = ''
    if ($acao -eq 1) {
        $hs  = Ler-NumeroOuVoltar 'Desbloquear por quantas horas? (1-72)' 1 72
        if ($null -eq $hs) { $script:SemPausa = $true; return }
        $ate = (Get-Date).AddHours($hs).ToString('yyyy-MM-dd HH:mm')
    }
    if ($acao -eq 2) {
        Write-Host ''
        Write-Host '   ATENÇÃO: fica desbloqueado até alguém bloquear de novo (Manutenção > Bloqueios > 3).' -ForegroundColor Red
        Write-Host '   Os usuários deste PC (alunos e professores) passam a poder mudar o que estava bloqueado.' -ForegroundColor Red
        if (-not (Perguntar-SN 'Desbloquear permanentemente?')) { return }
    }
    foreach ($n in $Nomes) {
        Definir-CampoCfg "Bloqueio$n" ($acao -ne 2)
        Definir-CampoCfg "Bloqueio${n}Ate" $ate
    }
    Salvar-Config
    foreach ($n in $Nomes) {
        Aplicar-Bloqueio $n
        $txt = switch ($acao) { 1 { "desbloqueado até $ate" } 2 { 'DESBLOQUEADO PERMANENTEMENTE' } 3 { 'bloqueado de novo' } }
        Registrar-Manutencao "Bloqueio - $(Desc-Bloqueio $n): $txt"
    }
    Write-Host '   Vale no próximo logon de cada usuário: quem já estiver logado continua como estava até sair e entrar de novo.' -ForegroundColor Cyan
}

# VS Code: instalar ou remover extensões da pasta comum (só a CTI, por aqui)
function Menu-ExtensoesVSCode {
    Titulo 'VS Code: extensões deste PC (os alunos usam, mas não instalam nem removem)'
    $inst = @(Extensoes-Instaladas)
    if ($inst.Count -eq 0) { Write-Host '   (nenhuma extensão instalada)' -ForegroundColor DarkGray }
    for ($i = 0; $i -lt $inst.Count; $i++) { Write-Host ('   - {0}' -f $inst[$i]) }
    Write-Host ''
    Write-Host '   1 - Instalar uma extensão nova (pede o identificador ou um arquivo .vsix)'
    Write-Host '   2 - Remover uma extensão'
    $op = Ler-Opcao 2
    if ($op -eq 1) {
        Write-Host ''
        Write-Host '   O identificador aparece no Marketplace (marketplace.visualstudio.com), na página da extensão,' -ForegroundColor DarkGray
        Write-Host '   em "Unique Identifier" (ex.: ms-vscode.cpptools). Sem internet: caminho de um .vsix (ex.: E:\ext.vsix).' -ForegroundColor DarkGray
        $r = (Perguntar 'Identificador ou caminho do .vsix (ENTER = voltar)').Trim().Trim('"')
        if (-not $r) { return }
        if ($r -like '*.vsix') {
            if (-not (Test-Path -LiteralPath $r)) { Write-Host "   Arquivo não encontrado: $r" -ForegroundColor Yellow; return }
        } elseif ($r -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*\.[A-Za-z0-9][A-Za-z0-9-]*$') {
            Write-Host '   Identificador inválido. Formato: editor.extensao (ex.: ms-vscode.cpptools).' -ForegroundColor Yellow; return
        }
        Write-Host '   Instalando (pode levar alguns minutos)...' -ForegroundColor DarkGray
        if ((Instalar-ExtensoesVSCode @($r)) -gt 0) {
            Registrar-Manutencao "VS Code: extensão instalada pela CTI: $r"
            Write-Host '   Para instalar em todos os labs nas próximas instalações, acrescente o identificador em' -ForegroundColor Cyan
            Write-Host '   $ExtensoesVSCode (seção CONFIGURAÇÃO do script) ou ponha o .vsix em softwares\vscode-extensoes.' -ForegroundColor Cyan
        }
    } elseif ($op -eq 2) {
        if ($inst.Count -eq 0) { Write-Host '   Não há extensões para remover.' -ForegroundColor Yellow; return }
        for ($i = 0; $i -lt $inst.Count; $i++) { Write-Host ('  {0,2} - {1}' -f ($i + 1), $inst[$i]) }
        $e = Ler-NumeroOuVoltar "Qual extensão remover? (1 a $($inst.Count))" 1 $inst.Count
        if ($null -eq $e) { $script:SemPausa = $true; return }
        $id = $inst[$e - 1]
        if (-not (Perguntar-SN "Remover a extensão $id deste PC?")) { return }
        $cod = Rodar-CodeExt '--uninstall-extension' $id
        Get-ChildItem $PastaExtVSCode -Directory -ErrorAction SilentlyContinue |
            Where-Object { (Id-ExtensaoDaPasta $_.Name) -eq $id } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $perm = Atualizar-PoliticaVSCode
        Registrar-Manutencao "VS Code: extensão removida pela CTI: $id (código $cod)"
        Write-Host "   Permitidas agora: $($perm -join ', ')" -ForegroundColor Green
    }
}

# ---- Papel de parede
# Como funciona: a CTI põe a imagem na pasta $PastaPapel (C:\ProgramData\IFSP\Papel de parede).
# A tarefa do sistema (a cada logon e a cada 5 min) pega a imagem MAIS NOVA da pasta e aplica, bloqueada,
# em todas as contas menos a CTI (que troca o seu papel de parede à vontade). Vale no próximo logon.
function Imagens-PastaPapel {
    return @(Get-ChildItem $PastaPapel -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Extension -in '.png', '.jpg', '.jpeg', '.bmp' } | Sort-Object LastWriteTime -Descending)
}
function Nome-PapelAtual {
    if ($Cfg.PapelOrigem) { return ([string]$Cfg.PapelOrigem).Split('|')[0] }
    $i = @(Imagens-PastaPapel)
    if ($i.Count -gt 0) { return $i[0].Name }
    return '(nenhuma imagem)'
}
# Tela de bloqueio e de login: a imagem do papel de parede do campus (sem as fotos e dicas da Microsoft).
# PersonalizationCSP funciona no Windows Pro; o sistema.ps1 atualiza o caminho quando o papel de parede muda.
function Definir-TelaBloqueio([string]$Arq) {
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    Definir-Reg $k 'LockScreenImagePath'   $Arq 'String'
    Definir-Reg $k 'LockScreenImageUrl'    $Arq 'String'
    Definir-Reg $k 'LockScreenImageStatus' 1
    $semDestaque = {
        param($hive)
        $c = "$hive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Definir-Reg $c 'RotatingLockScreenEnabled'        0    # sem "Windows em destaque"
        Definir-Reg $c 'RotatingLockScreenOverlayEnabled' 0    # sem dicas e curiosidades na tela de bloqueio
        Definir-Reg $c 'SubscribedContent-338387Enabled'  0
    }
    Para-CadaPerfil $semDestaque
    & $semDestaque 'HKCU:'
}

# Aplica a imagem na sessão atual (só a CTI, que roda o script)
function Papel-NaSessao([string]$Arq) {
    if (-not ('IFSPInst.Papel' -as [type])) {
        Add-Type -Namespace IFSPInst -Name Papel -MemberDefinition '[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int SystemParametersInfo(int a, int b, string c, int d);'
    }
    [void][IFSPInst.Papel]::SystemParametersInfo(20, 0, $Arq, 3)
}
function Aplicar-PapelAgora([bool]$EsperarImagem = $true) {
    $antes = [string]$Cfg.PapelCTI
    Start-ScheduledTask -TaskPath '\IFSP\' -TaskName 'Coletor de log' -ErrorAction SilentlyContinue
    Write-Host '   Aplicando...' -ForegroundColor DarkGray
    $novo = $Cfg
    for ($i = 0; $EsperarImagem -and $i -lt 20; $i++) {   # até ~20 s: espera a tarefa do sistema copiar a imagem nova
        Start-Sleep -Seconds 1
        $novo = (Get-Content $ArqConfig -Raw -Encoding UTF8 | ConvertFrom-Json)
        if ([string]$novo.PapelCTI -ne $antes) { break }
    }
    if (-not $EsperarImagem) { Start-Sleep -Seconds 3; $novo = (Get-Content $ArqConfig -Raw -Encoding UTF8 | ConvertFrom-Json) }
    $script:Cfg = $novo; Completar-Cfg
    if ($Cfg.PapelCTI -and (Test-Path $Cfg.PapelCTI)) { Papel-NaSessao $Cfg.PapelCTI }   # a CTI vê na hora
    Write-Host '   Pronto. Nos outros usuários, vale a partir do próximo logon.' -ForegroundColor Cyan
}

function Copiar-ImagemParaPasta {
    $pastas = @(Join-Path $Pen 'arquivos\wallpapers')
    $pd = Pasta-Pendrive
    if ($pd -and $pd -ne $Pen) { $pastas += (Join-Path $pd 'arquivos\wallpapers') }
    $imagens = @(Get-ChildItem $pastas -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Extension -in '.png', '.jpg', '.jpeg', '.bmp' } | Sort-Object Name, FullName)
    Titulo 'Nova imagem (1920x1080 de preferência)'
    for ($i = 0; $i -lt $imagens.Count; $i++) {
        Write-Host ('  {0,2} - {1}   ({2})' -f ($i + 1), $imagens[$i].Name, $imagens[$i].DirectoryName)
    }
    $nOutra = $imagens.Count + 1
    Write-Host ('  {0,2} - Digitar o caminho de outra imagem (.png, .jpg ou .bmp)' -f $nOutra)
    Write-Host '   0 - Voltar'
    $esc = Ler-Numero "Escolha (0 a $nOutra)" 0 $nOutra
    if ($esc -eq 0) { $script:SemPausa = $true; return }
    if ($esc -eq $nOutra) {
        $origem = (Perguntar 'Caminho completo da imagem (ENTER = voltar)').Trim().Trim('"')
        if (-not $origem) { $script:SemPausa = $true; return }
        if (-not $origem -or -not (Test-Path -LiteralPath $origem -PathType Leaf) -or ([IO.Path]::GetExtension($origem).ToLower() -notin '.png', '.jpg', '.jpeg', '.bmp')) {
            Write-Host '   Arquivo não encontrado ou não é .png, .jpg ou .bmp.' -ForegroundColor Yellow
            return
        }
    } else {
        $origem = $imagens[$esc - 1].FullName
    }
    New-Item -ItemType Directory -Path $PastaPapel -Force | Out-Null
    $destino = Join-Path $PastaPapel ([IO.Path]::GetFileName($origem))
    Copy-Item -LiteralPath $origem -Destination $destino -Force
    (Get-Item -LiteralPath $destino).LastWriteTime = Get-Date      # vira a mais nova da pasta
    Registrar-Manutencao "Papel de parede: $(Split-Path $origem -Leaf) copiado para a pasta $PastaPapel"
    Aplicar-PapelAgora
}

# Troca o tema (claro/escuro) de todos os usuários e o papel de parede pela imagem do campus do mesmo tema
function Trocar-Tema {
    $novo = if ($Cfg.Tema -eq 'claro') { 'escuro' } else { 'claro' }
    if (-not (Perguntar-SN "Trocar o tema de $($Cfg.Tema) para $novo, em todos os usuários?")) { return }
    Definir-CampoCfg 'Tema' $novo; Salvar-Config
    $script:valorClaro = if ($novo -eq 'claro') { 1 } else { 0 }
    $aplica = {
        param($hive)
        $k = "$hive\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Definir-Reg $k 'AppsUseLightTheme'    $script:valorClaro
        Definir-Reg $k 'SystemUsesLightTheme' $script:valorClaro
    }
    Para-CadaPerfil $aplica
    & $aplica 'HKCU:'
    Registrar-Manutencao "Tema trocado para $novo (vale para todos a partir do próximo logon)"
    # papel de parede do campus no tema novo (da cópia ou do pendrive)
    $pastas = @(Join-Path $Pen 'arquivos\wallpapers')
    $pd = Pasta-Pendrive
    if ($pd -and $pd -ne $Pen) { $pastas += (Join-Path $pd 'arquivos\wallpapers') }
    $img = $null
    foreach ($nomeImg in @(('{0}-{1}.png' -f $Cfg.Sigla, $novo), ('IFSP-{0}.png' -f $novo))) {
        foreach ($p in $pastas) { $f = Join-Path $p $nomeImg; if (-not $img -and (Test-Path $f)) { $img = $f } }
    }
    if ($img) {
        New-Item -ItemType Directory -Path $PastaPapel -Force | Out-Null
        $destino = Join-Path $PastaPapel (Split-Path $img -Leaf)
        Copy-Item -LiteralPath $img -Destination $destino -Force
        (Get-Item -LiteralPath $destino).LastWriteTime = Get-Date
        Registrar-Manutencao "Papel de parede trocado para $(Split-Path $img -Leaf) (tema $novo)"
        Aplicar-PapelAgora
    } else {
        Write-Host "   Não achei $($Cfg.Sigla)-$novo.png nem IFSP-$novo.png em arquivos\wallpapers: o papel de parede não mudou." -ForegroundColor Yellow
    }
}

function Menu-PapelDeParede {
    Titulo "Papel de parede e tema (tema atual: $($Cfg.Tema))"
    Write-Host "   Imagem atual: $(Nome-PapelAtual)"
    $txtB = if (Bloqueio-Ativo 'Papel') { 'BLOQUEADO: só a CTI troca' } else { "$(Texto-Bloqueio 'Papel'): cada usuário pode trocar o seu" }
    Write-Host "   Situação: $txtB" -ForegroundColor (Cor-Bloqueio 'Papel')
    Write-Host ''
    Write-Host '   Para trocar o de todos: ponha a imagem nova na pasta abaixo. A MAIS NOVA da pasta vale,' -ForegroundColor DarkGray
    Write-Host '   em até 5 minutos, para todos os usuários (no próximo logon). A CTI troca o seu à parte.' -ForegroundColor DarkGray
    Write-Host "   Pasta: $PastaPapel" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '   1 - Abrir a pasta do papel de parede'
    Write-Host '   2 - Escolher uma imagem do pendrive ou de outra pasta (copia para a pasta e aplica)'
    Write-Host '   3 - Aplicar agora a imagem mais nova da pasta'
    Write-Host '   4 - Bloqueio do papel de parede (desbloquear por algumas horas, permanentemente, ou bloquear de novo)'
    Write-Host ("   5 - Trocar o tema para {0} (todos os usuários) e o papel de parede do campus junto" -f $(if ($Cfg.Tema -eq 'claro') { 'escuro' } else { 'claro' }))
    switch (Ler-Opcao 5) {
        5 { Trocar-Tema }
        1 {
            New-Item -ItemType Directory -Path $PastaPapel -Force | Out-Null
            Start-Process explorer.exe $PastaPapel
            Write-Host '   Copie a imagem para a pasta que abriu. Depois, use a opção 3 (ou espere até 5 min).' -ForegroundColor Cyan
        }
        2 { Copiar-ImagemParaPasta }
        3 { Aplicar-PapelAgora }
        4 { if ($Cfg.Tipo -eq 'CTI') { Write-Host '   Nos PCs da CTI o papel de parede é livre.' -ForegroundColor Yellow } else { Menu-UmBloqueio @('Papel') } }
    }
}

# ---- Senha da conta de uso
#  PCs compartilhados (labs, uso de professores e de alunos): só a CTI define a senha (aqui ou à mão).
#  Administrativo: a própria pessoa também pode criar/trocar a dela.
#  Com senha, o PC sempre pede a senha ao ligar (nada de entrar sozinho).
function Menu-Senha {
    $nome = [string]$Cfg.Usuario
    if (-not (Get-LocalUser -Name $nome -ErrorAction SilentlyContinue)) { Write-Host "   A conta $nome não existe neste PC." -ForegroundColor Yellow; return }
    if ($Cfg.Tipo -eq 'CTI') {
        Titulo 'Senha da conta CTI (este PC só tem a conta CTI)'
        Write-Host '   A conta CTI sempre tem senha; aqui dá só para trocar.' -ForegroundColor DarkGray
        Write-Host '   1 - Trocar a senha da CTI'
        if ((Ler-Opcao 1) -eq 1) {
            Set-LocalUser -Name $ContaAdmin -Password (Ler-SenhaNova $ContaAdmin)
            Registrar-Manutencao 'Senha da conta CTI trocada pela manutenção'
        }
        return
    }
    $tem = Conta-TemSenha $nome
    Titulo "Senha da conta $nome"
    $estado = if ($tem -eq $true) { 'COM senha: o PC pede a senha ao ligar' } elseif ($tem -eq $false) { 'SEM senha: o PC entra sozinho nela ao ligar' } else { 'não deu para verificar' }
    Write-Host "   Situação: $estado" -ForegroundColor Yellow
    $quem = if ($Cfg.Compartilhado) { 'só a CTI (o próprio usuário não consegue trocar)' } else { 'a CTI ou a própria pessoa' }
    Write-Host "   Quem pode definir a senha: $quem" -ForegroundColor DarkGray
    Write-Host '   1 - Definir ou trocar a senha'
    Write-Host '   2 - Tirar a senha (o PC volta a entrar sozinho nesta conta)'
    switch (Ler-Opcao 2) {
        1 {
            $sn = Ler-SenhaNova $nome
            Set-LocalUser -Name $nome -Password $sn
            Definir-Autologon $false
            Registrar-Manutencao "Senha da conta $nome definida pela CTI (o PC passa a pedir a senha ao ligar)"
        }
        2 {
            if (Esta-NoDominio) { Write-Host "   Este PC está no domínio: a conta $nome é de reserva e precisa de senha (senão todos entram nela)." -ForegroundColor Yellow; return }
            if (-not (Perguntar-SN "Tirar a senha da conta ${nome}?")) { return }
            ([ADSI]"WinNT://$env:COMPUTERNAME/$nome,user").SetPassword('')
            Definir-Autologon $true
            Registrar-Manutencao "Senha da conta $nome tirada pela CTI (o PC volta a entrar sozinho)"
        }
    }
}

# ---- Pasta Segura (PCs compartilhados): pasta na Área de Trabalho da conta de uso que a limpeza não apaga
function Menu-PastaSeguraM {
    $perf = Perfil-DaConta (Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue)
    $caminho = if ($perf) { Join-Path $perf.LocalPath "Desktop\$PastaSegura" } else { '' }
    Titulo "Pasta Segura da conta $($Cfg.Usuario)"
    Write-Host '   Pasta na Área de Trabalho cujo conteúdo não é apagado nas limpezas (logon, logoff e desligar).' -ForegroundColor DarkGray
    Write-Host ("   Situação: {0}" -f $(if ($Cfg.PastaSegura) { 'LIGADA' } else { 'DESLIGADA' })) -ForegroundColor Yellow
    if ($Cfg.PastaSegura) { Write-Host '   1 - Tirar a Pasta Segura (o que estiver nela será apagado na próxima limpeza)' }
    else                  { Write-Host '   1 - Criar a Pasta Segura' }
    if ((Ler-Opcao 1) -eq 0) { return }
    if ($Cfg.PastaSegura) {
        $n = 0
        if ($caminho -and (Test-Path -LiteralPath $caminho)) { $n = @(Get-ChildItem -LiteralPath $caminho -Recurse -File -Force -ErrorAction SilentlyContinue).Count }
        Write-Host "   ATENÇÃO: a Pasta Segura tem $n arquivo(s). Eles serão APAGADOS na próxima limpeza." -ForegroundColor Red
        if (-not (Perguntar-SN 'Tirar a Pasta Segura mesmo assim?')) { return }
        Definir-CampoCfg 'PastaSegura' $false; Salvar-Config
        Registrar-Manutencao "Pasta Segura da conta $($Cfg.Usuario) desligada ($n arquivo(s) serão apagados na próxima limpeza)"
    } else {
        Definir-CampoCfg 'PastaSegura' $true; Salvar-Config
        if ($caminho) { New-Item -ItemType Directory -Path $caminho -Force | Out-Null }
        Registrar-Manutencao "Pasta Segura da conta $($Cfg.Usuario) criada"
        if (-not $caminho) { Write-Host '   A pasta aparece no primeiro logon da conta.' -ForegroundColor Cyan }
    }
}

# ---------------------------------------------------------------
#  Trocar o nome deste PC (mesmo lugar) e mudar o PC de lugar
# ---------------------------------------------------------------
# Tira as chaves e a linha do Veyon que eram do lugar antigo ($Antigo = respostas antigas). Usada ao mudar de lugar.
function Limpar-VeyonAntigo($Antigo) {
    if (-not $Antigo) { return }
    $grupoA = Grupo-Veyon $Antigo
    $grupoN = Grupo-Veyon $Cfg
    $mesmaSecao = ($Antigo.Sigla -eq $Cfg.Sigla -and $grupoA -eq $grupoN -and [bool]$Antigo.Compartilhado -eq [bool]$Cfg.Compartilhado)
    # 1) linha deste PC na lista da seção antiga, no pendrive
    if ([bool]$Antigo.Compartilhado -and -not $mesmaSecao) {
        $pd = Pasta-Pendrive
        if ($pd) {
            $csv = Join-Path $pd ('arquivos\veyon\{0}\{1}\computadores.csv' -f $Antigo.Sigla, $grupoA)
            if (Test-Path $csv) {
                $fica = @(Get-Content $csv -Encoding UTF8 | Where-Object { $_ -and $_.Split(';')[1] -ne $Antigo.NomePC -and $_.Split(';')[1] -ne $Cfg.NomePC })
                [IO.File]::WriteAllLines($csv, [string[]]$fica, (New-Object System.Text.UTF8Encoding($false)))
                Log "Veyon: $($Antigo.NomePC) tirado da lista da seção antiga ($(Nome-SecaoVeyon $grupoA)) no pendrive." 'Green'
            }
        } else {
            Log "AVISO: sem pendrive; $($Antigo.NomePC) continua na lista do Veyon da seção antiga ($(Nome-SecaoVeyon $grupoA)). Tire a linha à mão em arquivos\veyon\$($Antigo.Sigla)\$grupoA\computadores.csv." 'Yellow'
        }
    }
    # 2) chaves do lugar antigo neste PC (senão o professor do lab antigo continuaria vendo/controlando este PC)
    if (-not (Test-Path $VeyonCli)) { return }
    $lista  = (Rodar-Veyon authkeys list).Saida
    $tirar  = @()
    $chLabA = '{0}_{1}' -f $Antigo.Sigla, $Antigo.Local
    $chLabN = '{0}_{1}' -f $Cfg.Sigla, $Cfg.Local
    if ($chLabA -ne $chLabN -or -not [bool]$Cfg.Compartilhado) { $tirar += "$chLabA/public", "$chLabA/private" }
    elseif ($Antigo.Tipo -eq 'LAB-PROF' -and $Cfg.Tipo -ne 'LAB-PROF') { $tirar += "$chLabA/private" }   # deixou de ser o PC do professor
    $chCampA = '{0}_CAMPUS' -f $Antigo.Sigla
    $eraCentral = ($Antigo.Tipo -eq 'CTI' -and [bool]$Antigo.VeyonCentral)
    if ($eraCentral -and -not (Eh-CentralVeyon)) { $tirar += "$chCampA/private" }      # deixou de ser o PC central
    if ($Antigo.Sigla -ne $Cfg.Sigla -or -not (Usa-Veyon)) { $tirar += "$chCampA/public", "$chCampA/private" }
    foreach ($k in @($tirar | Select-Object -Unique)) {
        if ($lista -match [regex]::Escape($k)) {
            $null = Rodar-Veyon authkeys delete $k
            Log "Veyon: chave $k do lugar antigo apagada deste PC." 'Green'
        }
    }
    if ($Antigo.Tipo -eq 'LAB-PROF' -and $chLabA -ne $chLabN) {
        Log "AVISO: este PC era o do professor do lab $($Antigo.Local). Configure o novo PC do professor de lá (menu 3 - Veyon) e refaça o menu 3 nos PCs dos alunos desse lab." 'Yellow'
    }
    if (-not (Usa-Veyon)) { Log 'Veyon: o tipo novo não usa Veyon; ele fica instalado, mas sem chaves (ninguém controla este PC).' 'Yellow' }
}

# Manutenção > Trocar o nome (17): novo nome no mesmo lugar (mesmo tipo, local e conta). Vale depois de reiniciar.
function Trocar-NomePC {
    Titulo 'Trocar o nome deste PC (mesmo lugar)'
    $velho = [string]$Cfg.NomePC
    Write-Host "   Nome atual: $velho" -ForegroundColor Green
    Write-Host '   Para mudar o PC de lugar ou de tipo (ex.: da CAP para a CSP, do Lab 1 para uma sala), use a opção 18 da Manutenção.' -ForegroundColor DarkGray
    $novo = ''
    while ($true) {
        $r = (Perguntar 'Novo nome (0 = voltar)').Trim().ToUpper()
        if ($r -eq '0' -or $r -eq '') { $script:SemPausa = $true; return }
        if ($r -eq $velho) { Write-Host '   É o mesmo nome.' -ForegroundColor Yellow; continue }
        if (-not (Nome-PC-Valido $r)) {
            Write-Host '   Nome inválido: até 15 caracteres, só letras, números e hífen; não pode começar nem terminar com hífen, nem ter só números.' -ForegroundColor Yellow
            continue
        }
        if ($r -eq [string]$Cfg.Usuario -or $r -eq $ContaAdmin) { Write-Host "   O nome do PC não pode ser igual ao de uma conta ($r)." -ForegroundColor Yellow; continue }
        $novo = $r; break
    }
    if (-not (Perguntar-SN "Trocar o nome de $velho para $($novo)? (vale depois de reiniciar)")) { return }
    try { Rename-Computer -NewName $novo -Force -WarningAction SilentlyContinue -ErrorAction Stop }
    catch { Write-Host "   FALHA ao renomear: $($_.Exception.Message)" -ForegroundColor Red; return }
    Definir-CampoCfg 'NomePC' $novo
    Salvar-Config
    Log "PC renomeado de $velho para $novo (vale depois de reiniciar)." 'Green'
    # logon automático: o domínio da conta local é o nome do PC
    $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    if ([string](Get-ItemProperty -Path $wl -ErrorAction SilentlyContinue).AutoAdminLogon -eq '1') {
        Set-ItemProperty -Path $wl -Name DefaultDomainName -Value $novo
        Log 'Logon automático ajustado para o nome novo.'
    }
    # Veyon: a linha deste PC no pendrive (a antiga sai pelo MAC)
    if ((Usa-Veyon) -and -not (Eh-CentralVeyon)) {
        $pp = Pasta-VeyonPen
        if ($pp) { Registrar-PcNoVeyon $pp; Write-Host '   No PC do professor (e no central), a lista nova é carregada sozinha quando a CTI abrir o script lá com o pendrive.' -ForegroundColor Cyan }
        else { Write-Host '   Sem pendrive: a lista do Veyon não foi atualizada. Conecte o pendrive e use o menu 3 (Veyon) > 1 aqui.' -ForegroundColor Yellow }
    }
    if (Test-Path $GlpiBat) {
        Write-Host '   GLPI: o nome novo vai no próximo inventário (depois de reiniciar, menu inicial 4 > 3 envia na hora).' -ForegroundColor Cyan
        Write-Host '   Apague o computador antigo no GLPI se aparecer duplicado.' -ForegroundColor Cyan
    }
    Registrar-Manutencao "Nome do PC trocado de $velho para $novo"
    if (Perguntar-SN 'Reiniciar agora para o nome novo valer?') { Restart-Computer -Force }
}

# Manutenção > Mudar de lugar (18): responde as perguntas de novo (lugar, tipo, conta) e reaplica tudo, limpando o do lugar antigo
function Mudar-DeLugar {
    Titulo 'Mudar este PC de lugar ou de tipo'
    Write-Host "   Agora: $($Cfg.NomePC) | $($Cfg.Tipo) | local $($Cfg.Local) | conta $($Cfg.Usuario)" -ForegroundColor Green
    Write-Host '   O que acontece:'
    Write-Host '    - você responde as perguntas da instalação de novo (campus, local, tipo, nome, conta...);'
    Write-Host '    - o script reaplica tudo para o lugar novo (regras, bloqueios, horários, navegador, Veyon, GLPI);'
    Write-Host '    - o PC sai da lista do Veyon do lugar antigo e as chaves do lugar antigo são apagadas;'
    Write-Host '    - a conta de uso antiga aparece na etapa "Contas que já existem": dá para apagar, renomear ou manter.'
    Write-Host '   Os bloqueios e horários voltam ao padrão do tipo novo. Programas já instalados ficam.' -ForegroundColor DarkGray
    Write-Host '   Tenha o pendrive conectado (listas e chaves do Veyon).' -ForegroundColor Yellow
    if (-not (Perguntar-SN 'Continuar?')) { return }
    $script:CfgAntigo  = $Cfg | ConvertTo-Json -Depth 5 | ConvertFrom-Json
    $script:MudarLugar = $true
    $script:Reaplicar  = $true
}

# ---------------------------------------------------------------
#  Domínio (UCS ou Active Directory)
#  No domínio: cada pessoa entra com o próprio login; a conta local de uso fica de RESERVA (com senha, sem
#  logon automático); a CTI local continua administradora. Usuários do domínio: perfil NÃO é limpo, navegador
#  livre (sem anônimo) e podem trocar a senha; os outros bloqueios do tipo do PC valem para eles também.
# ---------------------------------------------------------------
function Ip-Valido([string]$Texto) {
    $ip = $null
    return ($Texto -match '^\d{1,3}(\.\d{1,3}){3}$') -and [Net.IPAddress]::TryParse($Texto, [ref]$ip)
}
function Esta-NoDominio {
    try { return [bool](Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).PartOfDomain } catch { return $false }
}
function Placas-Conectadas { return @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }) }
function Texto-DnsAtual {
    $l = @()
    foreach ($n in (Placas-Conectadas)) {
        $d = (Get-DnsClientServerAddress -InterfaceIndex $n.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $l += ('{0}: {1}' -f $n.Name, $(if ($d) { $d -join ', ' } else { '(automático, sem servidor)' }))
    }
    if ($l.Count -eq 0) { return '(nenhuma placa de rede conectada)' }
    return ($l -join ' | ')
}
function Fixar-DnsDominio([string]$Ip) {
    $placas = Placas-Conectadas
    if ($placas.Count -eq 0) { Log 'AVISO: nenhuma placa de rede conectada; o DNS não foi fixado.' 'Yellow'; return $false }
    $lista = @($Ip)
    if ($DnsSecundarioDominio) { $lista += $DnsSecundarioDominio }
    foreach ($n in $placas) { Set-DnsClientServerAddress -InterfaceIndex $n.ifIndex -ServerAddresses $lista }
    Clear-DnsClientCache
    Log "DNS fixado em $($lista -join ' e ') (placa(s): $(@($placas | ForEach-Object { $_.Name }) -join ', '))." 'Green'
    return $true
}
function Dns-Automatico {
    foreach ($n in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue)) {
        Set-DnsClientServerAddress -InterfaceIndex $n.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
    Clear-DnsClientCache
    Log 'DNS de volta ao automático (o da rede/DHCP).' 'Green'
}

# Pergunta domínio e IP do servidor (sugestões: deste PC ou do pendrive). Devolve $false se voltou.
function Ler-DadosDominio {
    $dc  = Ler-DadosCampus $Cfg.Sigla
    $dom = if ($Cfg.Dominio) { [string]$Cfg.Dominio } elseif ($dc.Dominio) { [string]$dc.Dominio } else { '' }
    $ip  = if ($Cfg.DominioDns) { [string]$Cfg.DominioDns } elseif ($dc.DominioDns) { [string]$dc.DominioDns } else { '' }
    while ($true) {
        $txt = if ($dom) { "Domínio: $dom   (ENTER confirma, ou digite outro; 0 = voltar)" } else { 'Nome do domínio (ex.: escola.ifsp.local; 0 = voltar)' }
        $r = (Perguntar $txt).Trim()
        if ($r -eq '0') { return $false }
        if ($r -eq '' -and $dom) { break }
        if ($r -match '^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$') { $dom = $r.ToLower(); break }
        Write-Host '   Nome inválido. Ex.: escola.ifsp.local' -ForegroundColor Yellow
    }
    while ($true) {
        $txt = if ($ip) { "IP do servidor do domínio: $ip   (ENTER confirma, ou digite outro; 0 = voltar)" } else { 'IP do servidor do domínio (vira o DNS do PC; 0 = voltar)' }
        $r = (Perguntar $txt).Trim()
        if ($r -eq '0') { return $false }
        if ($r -eq '' -and $ip) { break }
        if (Ip-Valido $r) { $ip = $r; break }
        Write-Host '   IP inválido. Ex.: 192.168.1.10' -ForegroundColor Yellow
    }
    Definir-CampoCfg 'Dominio' $dom
    Definir-CampoCfg 'DominioDns' $ip
    Salvar-Config
    Gravar-DadosCampus                    # pendrive: sugerido nos outros PCs do campus
    return $true
}

# Coloca o PC no domínio de $Cfg.Dominio: DNS fixo, conta de reserva com senha, usuário do domínio pedido na hora
# (não é guardado). Vale depois de reiniciar. Devolve $true se entrou.
function Ingressar-Dominio {
    if (-not $Cfg.Dominio -or -not $Cfg.DominioDns) { Log 'Domínio: nome ou servidor não informado.' 'Yellow'; return $false }
    if (Esta-NoDominio) { Log "Este PC já está num domínio ($((Get-CimInstance Win32_ComputerSystem).Domain))." 'Yellow'; return $false }
    if (-not (Fixar-DnsDominio $Cfg.DominioDns)) { return $false }
    $achou = $false
    try { $null = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$($Cfg.Dominio)" -Type SRV -Server $Cfg.DominioDns -DnsOnly -ErrorAction Stop; $achou = $true } catch { }
    if ($achou) { Log "Domínio $($Cfg.Dominio) encontrado no servidor $($Cfg.DominioDns)." 'Green' }
    else {
        Write-Host "   O servidor $($Cfg.DominioDns) não respondeu pelo domínio $($Cfg.Dominio) (rede, IP ou nome do domínio?)." -ForegroundColor Red
        if (-not (Perguntar-SN 'Tentar entrar no domínio mesmo assim?')) { return $false }
    }
    # conta local de uso: vira reserva (com senha e sem logon automático)
    if ($Cfg.Tipo -ne 'CTI' -and $Cfg.Usuario -and (Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue)) {
        if ((Conta-TemSenha $Cfg.Usuario) -ne $true) {
            Write-Host ''
            Write-Host "   No domínio, a conta local $($Cfg.Usuario) fica de RESERVA (para quando o servidor ou a rede cair)." -ForegroundColor Yellow
            Write-Host '   Ela precisa de senha (senão aparece na tela de login e todos entram nela). Só a CTI e o professor devem saber.' -ForegroundColor Yellow
            Set-LocalUser -Name $Cfg.Usuario -Password (Ler-SenhaNova $Cfg.Usuario)
            Log "Conta $($Cfg.Usuario): senha definida (reserva do domínio)." 'Green'
        }
        Definir-Autologon $false
        Log 'Logon automático desligado (no domínio, cada pessoa entra com o próprio login).'
    }
    Write-Host ''
    Write-Host '   Usuário do domínio com permissão para incluir computadores (ex.: Administrator).' -ForegroundColor Cyan
    Write-Host '   Usado só agora, para cadastrar este PC no servidor; a senha NÃO é guardada.' -ForegroundColor DarkGray
    $u = (Perguntar 'Usuário (0 = cancelar)').Trim()
    if (-not $u -or $u -eq '0') { Log 'Domínio: cancelado (o DNS ficou fixo; para voltar: Manutenção > Domínio > 3).' 'Yellow'; return $false }
    if ($u -notmatch '[\\@]') { $u = '{0}\{1}' -f $Cfg.Dominio, $u }
    $sen  = Read-Host '  > Senha' -AsSecureString
    $cred = New-Object System.Management.Automation.PSCredential($u, $sen)
    # Nome trocado e ainda sem reiniciar: entra no domínio já com o nome novo
    $kNome  = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName'
    $ativo  = (Get-ItemProperty "$kNome\ActiveComputerName" -ErrorAction SilentlyContinue).ComputerName
    $pend   = (Get-ItemProperty "$kNome\ComputerName" -ErrorAction SilentlyContinue).ComputerName
    $opcoes = @('AccountCreate')
    if ($pend -and $ativo -ne $pend) { $opcoes += 'JoinWithNewName' }
    try {
        Add-Computer -DomainName $Cfg.Dominio -Credential $cred -Options $opcoes -Force -ErrorAction Stop -WarningAction SilentlyContinue
    } catch {
        Log "FALHA ao entrar no domínio: $($_.Exception.Message)" 'Red'
        Write-Host '   Confira: usuário e senha, rede, o IP do servidor e se o relógio do PC está certo (diferença máxima de 5 min).' -ForegroundColor Yellow
        return $false
    }
    Definir-CampoCfg 'NoDominio' $true
    Salvar-Config
    $script:PrecisaReiniciar = $true
    Log "PC incluído no domínio $($Cfg.Dominio) (vale depois de reiniciar)." 'Green'
    if ($Cfg.Tipo -eq 'LAB-PROF') {
        Write-Host '   PC do professor do lab: depois de reiniciar, use Manutenção > Domínio > 4 para só os professores abrirem o Veyon Master.' -ForegroundColor Cyan
    }
    return $true
}

function Sair-Dominio {
    if (-not (Esta-NoDominio)) { Write-Host '   Este PC não está num domínio.' -ForegroundColor Yellow; return }
    $dom = (Get-CimInstance Win32_ComputerSystem).Domain
    Write-Host "   O PC sai do domínio $dom e volta a usar só as contas locais. Os perfis dos usuários do domínio ficam no disco." -ForegroundColor Yellow
    if (-not (Perguntar-SN "Tirar este PC do domínio $($dom)?")) { return }
    $cs = Get-WmiObject Win32_ComputerSystem
    $r1 = $cs.UnjoinDomainOrWorkgroup($null, $null, 0)            # 0 = só neste PC (não mexe na conta do PC no servidor)
    if ($r1.ReturnValue -ne 0) { Log "FALHA ao sair do domínio (código $($r1.ReturnValue))." 'Red'; return }
    $null = (Get-WmiObject Win32_ComputerSystem).JoinDomainOrWorkgroup('WORKGROUP', $null, $null, $null, 0)
    Definir-CampoCfg 'NoDominio' $false
    Salvar-Config
    Log "PC fora do domínio $dom (vale depois de reiniciar). Apague a conta do PC no servidor se quiser." 'Green'
    if (Perguntar-SN 'Voltar o DNS ao automático (o da rede)?') { Dns-Automatico }
    if ($Cfg.Tipo -ne 'CTI') { Write-Host "   Para o PC voltar a entrar sozinho na conta $($Cfg.Usuario), tire a senha dela (Manutenção > Senha da conta de uso)." -ForegroundColor Cyan }
    Registrar-Manutencao "PC tirado do domínio $dom"
    if (Perguntar-SN 'Reiniciar agora?') { Restart-Computer -Force }
}

# PC do professor do lab no domínio: Veyon Master só para Administradores, a conta local de uso e o grupo
# dos professores do domínio (alunos do domínio que entrarem neste PC não abrem). Reaplicado no menu do Veyon.
function Restringir-VeyonMaster {
    $exe = 'C:\Program Files\Veyon\veyon-master.exe'
    if ($Cfg.Tipo -ne 'LAB-PROF' -or -not (Esta-NoDominio) -or -not (Test-Path $exe)) { return }
    $grupo = [string]$Cfg.GrupoProfessores
    if (-not $grupo) { return }
    $dominioNb = $env:USERDOMAIN
    try { $dominioNb = (Get-CimInstance Win32_NTDomain -ErrorAction Stop | Where-Object { $_.DomainName } | Select-Object -First 1).DomainName } catch { }
    $alvo = if ($grupo -match '\\') { $grupo } else { '{0}\{1}' -f $dominioNb, $grupo }
    try { $null = (New-Object Security.Principal.NTAccount($alvo)).Translate([Security.Principal.SecurityIdentifier]) }
    catch { Log "AVISO: o grupo $alvo não foi encontrado no domínio; o Veyon Master continua aberto para todos." 'Yellow'; return }
    $out = & icacls.exe $exe /inheritance:r /grant:r '*S-1-5-32-544:(RX)' '*S-1-5-18:(RX)' "$($env:COMPUTERNAME)\$($Cfg.Usuario):(RX)" "$($alvo):(RX)" 2>&1
    if ($LASTEXITCODE -eq 0) { Log "Veyon Master: só Administradores, a conta $($Cfg.Usuario) e o grupo $alvo abrem." 'Green' }
    else { Log "AVISO: não consegui restringir o Veyon Master ($out)." 'Yellow' }
}

# Manutenção > Domínio (15)
function Menu-Dominio {
    Titulo 'Domínio (UCS ou Active Directory)'
    $no = Esta-NoDominio
    $txtNo = if ($no) { "SIM ($((Get-CimInstance Win32_ComputerSystem).Domain))" } elseif ($Cfg.NoDominio) { 'entrada feita, falta reiniciar' } else { 'não' }
    Write-Host ('   No domínio ........... {0}' -f $txtNo) -ForegroundColor $(if ($no) { 'Green' } else { 'Yellow' })
    Write-Host ('   Domínio guardado ..... {0}' -f $(if ($Cfg.Dominio) { "$($Cfg.Dominio) (servidor $($Cfg.DominioDns))" } else { '(nenhum)' }))
    Write-Host ('   DNS agora ............ {0}' -f (Texto-DnsAtual))
    Write-Host ''
    Write-Host '   1 - Entrar no domínio (informar ou confirmar o domínio e o servidor)'
    Write-Host '   2 - Sair do domínio'
    Write-Host '   3 - DNS: fixar no servidor do domínio, ou voltar ao automático'
    $max = 3
    if ($Cfg.Tipo -eq 'LAB-PROF') { Write-Host '   4 - Veyon Master só para os professores do domínio (PC do professor do lab)'; $max = 4 }
    switch (Ler-Opcao $max) {
        1 {
            if ($no) { Write-Host '   Este PC já está num domínio.' -ForegroundColor Yellow; return }
            if (-not (Ler-DadosDominio)) { $script:SemPausa = $true; return }
            if (Ingressar-Dominio) {
                Registrar-Manutencao "PC incluído no domínio $($Cfg.Dominio)"
                if (Perguntar-SN 'Reiniciar agora para valer?') { Restart-Computer -Force }
            }
        }
        2 { Sair-Dominio }
        3 {
            Write-Host '   F = fixar no servidor do domínio   A = voltar ao automático   0 = voltar'
            do { $r = (Perguntar 'Escolha').Trim().ToUpper() } until ($r -in 'F', 'A', '0')
            if ($r -eq 'F') {
                if (-not (Ler-DadosDominio)) { $script:SemPausa = $true; return }
                if (Fixar-DnsDominio $Cfg.DominioDns) { Registrar-Manutencao "DNS fixado no servidor do domínio ($($Cfg.DominioDns))" }
            } elseif ($r -eq 'A') {
                Dns-Automatico
                Registrar-Manutencao 'DNS de volta ao automático'
            }
        }
        4 {
            if (-not $no) { Write-Host '   Primeiro coloque o PC no domínio e reinicie.' -ForegroundColor Yellow; return }
            $sug = if ($Cfg.GrupoProfessores) { [string]$Cfg.GrupoProfessores } else { 'professores' }
            $g = (Perguntar "Grupo dos professores no domínio: $sug   (ENTER confirma, ou digite outro; 0 = voltar)").Trim()
            if ($g -eq '0') { $script:SemPausa = $true; return }
            if (-not $g) { $g = $sug }
            Definir-CampoCfg 'GrupoProfessores' $g
            Salvar-Config
            Restringir-VeyonMaster
            Registrar-Manutencao "Veyon Master restrito ao grupo $g"
        }
    }
}

# Menu da Manutenção: uma tela só, em duas colunas, com as opções agrupadas por tema.
# Cada linha: 'TÍTULO DO GRUPO' ou 'número|texto'. Números indisponíveis neste PC aparecem apagados.
$MenuManutEsq = @(
    'DIAGNÓSTICO'
    '1|Situação deste computador'
    '2|Diagnóstico (reinícios, programas, disco, tarefas)'
    '3|Logs (usuários, pendrives, regras, impressão)'
    'CONTAS, SESSÕES E HORÁRIOS'
    '4|Contas locais (desbloquear, logon automático)'
    '5|Senha da conta de uso'
    '6|Pasta Segura'
    '7|Sessões abertas (ver e encerrar)'
    '8|Horários (desligamento das 23:30)'
    'LIMPEZAS E BLOQUEIOS'
    '9|Limpezas (conta de uso, temporários, XAMPP)'
    '10|Bloqueios (Configurações, impressão...)'
)
$MenuManutDir = @(
    'APARÊNCIA E AVISOS'
    '11|Papel de parede e tema'
    '12|Pop-up de logon'
    '13|Favoritos do Chrome e do Edge'
    'REDE E WINDOWS'
    '14|Rede (IP, MAC, Wake-on-LAN, testes)'
    '15|Domínio (UCS ou AD)'
    '16|Rotinas do Windows (disco, relógio...)'
    'ESTE PC'
    '17|Trocar o nome deste PC'
    '18|Mudar de lugar ou de tipo'
    '19|Reaplicar / reinstalar programas'
)
function Celula-Menu([string]$Item, [int[]]$Apagados, [string]$CorGrupo) {
    if (-not $Item) { return @{ Texto = ''; Cor = 'Gray' } }
    if ($Item -notmatch '\|') { return @{ Texto = "  $Item"; Cor = $CorGrupo } }
    $p = $Item.Split('|')
    $cor = if ([int]$p[0] -in $Apagados) { 'DarkGray' } else { 'Gray' }
    return @{ Texto = ('  {0,3} - {1}' -f $p[0], $p[1]); Cor = $cor }
}
function Mostrar-MenuDuasColunas([string[]]$Esq, [string[]]$Dir, [int[]]$Apagados, [string]$CorGrupo, [int]$Largura = 60) {
    $n = [math]::Max($Esq.Count, $Dir.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $e = Celula-Menu $(if ($i -lt $Esq.Count) { $Esq[$i] } else { '' }) $Apagados $CorGrupo
        $d = Celula-Menu $(if ($i -lt $Dir.Count) { $Dir[$i] } else { '' }) $Apagados $CorGrupo
        Write-Host ($e.Texto.PadRight($Largura)) -ForegroundColor $e.Cor -NoNewline
        Write-Host $d.Texto -ForegroundColor $d.Cor
    }
}

function Menu-Manutencao {
    if (-not (Carregar-Cfg)) { Pausa; return }
    if (-not ($Cfg.PSObject.Properties.Name -contains 'Horarios')) { Horarios-Normais; Salvar-Config }
    Atualizar-ScriptsAntigos
    Sincronizar-VeyonAuto
    $sisArq = Join-Path $Base 'sistema.ps1'
    $antigo = (Test-Path $sisArq) -and ([IO.File]::ReadAllText($sisArq) -match 'TravasAtivas')
    $temHorarioM = [bool]$Cfg.Horarios.Ativo
    $apagados = @()
    if (-not $Cfg.Compartilhado) { $apagados += 6 }
    if (-not $temHorarioM)       { $apagados += 8 }
    $cor = $CoresArea.Manutencao
    $faixa = "MANUTENÇÃO - $($Cfg.NomePC) ($($Cfg.Tipo))"
    try {
        while ($true) {
            Mostrar-Cabecalho $faixa $cor
            Write-Host ('  ' + (Texto-Horarios $Cfg.Horarios)) -ForegroundColor DarkGray
            if ($antigo) {
                Write-Host '  ATENÇÃO: as tarefas deste PC são de uma versão anterior (v3.8 ou antes).' -ForegroundColor Red
                Write-Host '  Use a opção 19 (Reaplicar) para os bloqueios funcionarem como mostrados aqui.' -ForegroundColor Red
            }
            Write-Host ''
            Mostrar-MenuDuasColunas $MenuManutEsq $MenuManutDir $apagados $cor
            Write-Host ''
            Write-Host '    0 - Voltar ao menu inicial'
            $op = Ler-Numero 'Escolha (0 a 19)' 0 19
            if ($op -eq 0) { return }
            if ($op -eq 19) { $script:Reaplicar = $true; return }
            if ($op -eq 18) {
                Mostrar-Cabecalho $faixa $cor
                Mudar-DeLugar
                if ($script:MudarLugar) { return }
                continue
            }
            $script:SemPausa = $false
            Mostrar-Cabecalho $faixa $cor        # cada opção começa numa tela limpa
            try {
                switch ($op) {
                    1  { Ver-Situacao }
                    2  { Menu-Diagnostico }
                    3  { Menu-Logs }
                    4  { Menu-Contas }
                    5  { Menu-Senha }
                    6  { if ($Cfg.Compartilhado) { Menu-PastaSeguraM } else { Write-Host '   A Pasta Segura só existe nos PCs de uso compartilhado (nos administrativos nada é apagado).' -ForegroundColor Yellow } }
                    7  { Menu-Sessao }
                    8  { if ($temHorarioM) { Menu-Horarios } else { Write-Host '   Este tipo de PC não desliga sozinho (veja $TiposComDesligamento no script).' -ForegroundColor Yellow } }
                    9  { Menu-Limpezas }
                    10 { Menu-Bloqueios }
                    11 { Menu-PapelDeParede }
                    12 { Menu-Popup }
                    13 { Menu-Favoritos }
                    14 { Menu-Rede }
                    15 { Menu-Dominio }
                    16 { Menu-Rotinas }
                    17 { Trocar-NomePC }
                }
            } catch {
                Write-Host "   ERRO: $($_.Exception.Message)" -ForegroundColor Red
            }
            if (-not $script:SemPausa) { Pausa }
        }
    } finally { $script:CorArea = 'Cyan' }
}

# ===============================================================
#  INÍCIO
# ===============================================================
$ehAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
           [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $ehAdmin) {
    Write-Host 'ERRO: execute como administrador (use o INICIO.bat).' -ForegroundColor Red
    exit 1
}
try { $Host.UI.RawUI.WindowTitle = "Manutenção de Computadores IFSP v$Versao" } catch { }

try {
  # Laço externo: volta aqui quando a pessoa escolhe "voltar ao menu inicial" (tela do pendrive, respostas, perguntas)
  while ($true) {
    $script:Reaplicar  = $false
    $script:MudarLugar = $false
    $script:CfgAntigo  = $null
    # ---------------- Menu inicial: Instalar, Manutenção, Veyon ou GLPI ----------------
    while ($true) {
        Mostrar-Cabecalho
        Titulo 'O que deseja fazer?'
        Write-Host '   1 - Instalar / configurar este computador' -ForegroundColor $CoresArea.Instalacao
        Write-Host '   2 - Manutenção (situação, contas, limpezas, bloqueios, aparência, rede, rotinas...)' -ForegroundColor $CoresArea.Manutencao
        Write-Host '   3 - Veyon (instalar, configurar; carregar e conferir a lista) - use com o pendrive' -ForegroundColor $CoresArea.Veyon
        Write-Host '   4 - GLPI (agente de inventário: instalar, servidor, etiqueta, enviar) - qualquer PC' -ForegroundColor $CoresArea.Glpi
        Write-Host '   0 - Sair'
        $opInicial = Ler-Numero 'Escolha (0 a 4)' 0 4
        if ($opInicial -eq 0) { exit 0 }
        if ($opInicial -eq 1) { break }
        if ($opInicial -eq 2) {
            Menu-Manutencao
            if ($script:Reaplicar) { break }
        }
        if ($opInicial -eq 3) { Menu-VeyonInicial }
        if ($opInicial -eq 4) { Menu-GlpiInicial }
    }
    if ((Tela-Pendrive) -eq 'VOLTAR') { continue }
    Mostrar-Cabecalho

    # ---------------- Respostas (novas ou de uma execução anterior) ----------------
    $Cfg = $null
    $cfgAnterior = $null
    if (Test-Path $ArqConfig) {
        try { $cfgAnterior = Get-Content $ArqConfig -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $cfgAnterior = $null }
    }
    if ($cfgAnterior -and $cfgAnterior.NomePC -and $cfgAnterior.Usuario) {
        if ($cfgAnterior.Etapa -eq 'aguardando-CTI' -and $UsuarioAtual -eq $ContaAdmin) {
            Write-Host '  Continuando a instalação começada antes:' -ForegroundColor Cyan
            Mostrar-Resumo $cfgAnterior
            $Cfg = $cfgAnterior
        } else {
            Write-Host '  Este computador já foi configurado por este script:' -ForegroundColor Cyan
            Mostrar-Resumo $cfgAnterior
            if ($script:MudarLugar) {
                Write-Host '  Mudança de lugar ou de tipo: responda as perguntas para o lugar novo.' -ForegroundColor Yellow
                $null = Read-Host '  ENTER para começar'
            }
            elseif ($script:Reaplicar) { $Cfg = $cfgAnterior }
            else {
                do { $r = (Perguntar 'Usar as mesmas respostas?  (ENTER = usar, N = responder de novo, 0 = voltar ao menu inicial)').Trim().ToUpper() } until ($r -in '', 'S', 'N', '0')
                if ($r -eq '0') { continue }
                if ($r -ne 'N') { $Cfg = $cfgAnterior }
            }
        }
    }
    $repeticao = [bool]($Cfg -and $Cfg.Etapa -eq 'concluido')
    if (-not $Cfg) {
        $Cfg = Fazer-Perguntas
        if (-not $Cfg) { continue }                   # 0 na primeira pergunta: volta ao menu inicial
    }
    # Programas: perguntados ANTES de qualquer cópia (só como CTI: com outra conta, o script para antes)
    if ($UsuarioAtual -eq $ContaAdmin) {
        Completar-Cfg
        $esc = Escolher-Programas
        if ($esc -is [string]) { continue }           # 0 na primeira pergunta: volta ao menu inicial
        $Prog = $esc
    }
    break
  }
    $Cfg.Versao = $Versao
    if (-not ($Cfg.PSObject.Properties.Name -contains 'PaginaInicial')) {   # respostas de versão anterior
        $Cfg | Add-Member -NotePropertyName PaginaInicial -NotePropertyValue $Cfg.Site
    }
    Completar-Cfg                                        # marcadores do tipo: LabInfo, Compartilhado, ContaAlunos
    if ($script:MudarLugar -and $script:CfgAntigo) {
        Log "Mudança de lugar: era $($script:CfgAntigo.NomePC) ($($script:CfgAntigo.Tipo), local $($script:CfgAntigo.Local)); agora $($Cfg.NomePC) ($($Cfg.Tipo), local $($Cfg.Local))." 'Cyan'
    }
    $ehLab    = [bool]$Cfg.LabInfo                       # lab de informática
    $ehComp   = [bool]$Cfg.Compartilhado                 # uso compartilhado (labs, professores, alunos)
    $ehAlunos = [bool]$Cfg.ContaAlunos                   # conta Alunos
    # Moodle nos favoritos: todo PC de professores e alunos, se o campus tiver Moodle (pergunta da instalação)
    $comMoodle = $ehComp -and [bool]$Cfg.Moodle
    $pausaPerm = if ($Cfg.Horarios -and [string]$Cfg.Horarios.PausadoAte -like '9999*') { [string]$Cfg.Horarios.PausadoAte } else { '' }
    Horarios-Normais                                     # horários: valores normais (labs, salas, CIE) ou desativados
    if ($pausaPerm) { $Cfg.Horarios.PausadoAte = $pausaPerm; Log 'Desligamento automático continua DESATIVADO PERMANENTEMENTE (Manutenção > Horários).' 'Yellow' }
    $temHorario = [bool]$Cfg.Horarios.Ativo
    Definir-CampoCfg 'IconePastaSegura' $IconePastaSegura
    Definir-CampoCfg 'TemaVSCode' $TemaVSCode            # VS Code dos labs: tema a cada logon (menos na CTI)
    if (-not ($Cfg.PSObject.Properties.Name -contains 'PopupLogon')) { Definir-CampoCfg 'PopupLogon' $true }   # Manutenção > Pop-up
    # Bloqueios: as escolhas da CTI (Manutenção > Bloqueios) continuam ao reaplicar. Nomes antigos (v3.8) saem.
    foreach ($velho in 'TravasAtivas', 'TravasDesligadasAte', 'PapelTravado', 'PapelTravadoAplicado') { $Cfg.PSObject.Properties.Remove($velho) }
    $desbloq = @(Bloqueios-DoPC | Where-Object { -not (Bloqueio-Ativo $_) })
    if ($desbloq.Count -gt 0) { Log "Bloqueios que continuam desbloqueados (Manutenção > Bloqueios): $($desbloq -join ', ')." 'Yellow' }

    # ---------------- Pasta base, logs e respostas ----------------
    # SYSTEM e Administradores: controle total. Usuários: só leitura.
    New-Item -ItemType Directory -Path $Base -Force | Out-Null
    & icacls.exe $Base /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Falha ao ajustar permissões em $Base" }
    New-Item -ItemType Directory -Path $PastaLogs -Force | Out-Null
    Atualizar-ScriptsAntigos                             # antes de gravar o config.json novo
    Salvar-Config
    Log "--- Instalador v$Versao (revisão $Revisao) | $($Cfg.NomePC) | $($Cfg.Tipo) | usuário $($Cfg.Usuario) | tema $($Cfg.Tema) ---" 'Cyan'

    # ---------------- Conta CTI (administradora) ----------------
    $nomeAtivo    = $env:COMPUTERNAME
    $nomePendente = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName').ComputerName

    if ($UsuarioAtual -ne $ContaAdmin) {
        Titulo "Conta $ContaAdmin"
        if (Get-LocalUser -Name $ContaAdmin -ErrorAction SilentlyContinue) {
            Enable-LocalUser -Name $ContaAdmin
            Log "A conta $ContaAdmin já existe (a senha não foi alterada)."
        } else {
            Write-Host "  A conta $ContaAdmin (administradora) ainda não existe neste PC." -ForegroundColor Yellow
            $senha = Ler-SenhaNova $ContaAdmin
            New-LocalUser -Name $ContaAdmin -Password $senha -FullName $ContaAdmin `
                          -Description 'Coordenadoria de Tecnologia da Informação' -PasswordNeverExpires | Out-Null
            Log "Conta $ContaAdmin criada com a senha informada." 'Green'
        }
        Adicionar-AoGrupo $SID_Admins   $ContaAdmin
        Adicionar-AoGrupo $SID_Usuarios $ContaAdmin

        if ($nomeAtivo -ne $Cfg.NomePC -and $nomePendente -ne $Cfg.NomePC) {
            Rename-Computer -NewName $Cfg.NomePC -Force -WarningAction SilentlyContinue
            Log "O PC será renomeado de $nomeAtivo para $($Cfg.NomePC) (após reiniciar)." 'Green'
        }
        $Cfg.Etapa = 'aguardando-CTI'
        Salvar-Config

        Write-Host ''
        Log "PARADA: o restante precisa ser feito logado como $ContaAdmin." 'Yellow'
        Write-Host '   1) Reinicie o PC'
        Write-Host "   2) Entre na conta $ContaAdmin"
        Write-Host '   3) Conecte o pendrive e rode o INICIO.bat dele de novo como administrador (as respostas já estão guardadas)'
        Write-Host ''
        if (Perguntar-SN 'Reiniciar agora?') { Restart-Computer -Force }
        exit 0
    }
    Adicionar-AoGrupo $SID_Usuarios $ContaAdmin    # a tarefa de logon vale para o grupo Usuários

    # =================== Pendrive: o que precisa dele é feito agora; depois pode tirar ===================
    # Os programas já foram escolhidos (Escolher-Programas), antes da cópia
    $instalar = [bool]$Prog.Instalar
    Fase-Pendrive

    # =================== 1. Nome do PC ===================
    Etapa 'Nome do computador'
    if ($nomeAtivo -eq $Cfg.NomePC) {
        Log "Nome do PC já é $($Cfg.NomePC)."
    } elseif ($nomePendente -eq $Cfg.NomePC) {
        Log "Renomeação para $($Cfg.NomePC) já agendada; falta reiniciar." 'Yellow'
        $PrecisaReiniciar = $true
    } else {
        Rename-Computer -NewName $Cfg.NomePC -Force -WarningAction SilentlyContinue
        Log "PC será renomeado de $nomeAtivo para $($Cfg.NomePC) (após reiniciar)." 'Green'
        $PrecisaReiniciar = $true
    }

    # =================== 3. Contas existentes ===================
    Etapa 'Contas que já existem neste PC'
    $renomeada = $false
    $outras = @(Get-LocalUser | Where-Object {
        $_.SID.Value -notmatch '-(500|501|503|504)$' -and $_.Name -ne $ContaAdmin -and $_.Name -ne $Cfg.Usuario })
    if ($outras.Count -eq 0) { Log 'Nenhuma outra conta encontrada.' }
    foreach ($u in $outras) {
        $perf  = Perfil-DaConta $u
        $admin = $false
        try { $admin = [bool](Get-LocalGroupMember -SID $SID_Admins | Where-Object { $_.SID -eq $u.SID }) } catch { }
        $ms    = ([string]$u.PrincipalSource -eq 'MicrosoftAccount')
        $info  = @()
        if ($perf)  { $info += "arquivos em $($perf.LocalPath)" } else { $info += 'sem arquivos' }
        if ($admin) { $info += 'administradora' }
        if ($ms)    { $info += 'conta Microsoft' }
        if (-not $u.Enabled) { $info += 'desativada' }
        Write-Host ''
        Write-Host "   Conta: $($u.Name)  ($($info -join ', '))" -ForegroundColor White
        $podeRenomear = (-not $renomeada) -and (-not $ms) -and -not (Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue)
        if ($podeRenomear) { Write-Host "     R = renomear para $($Cfg.Usuario) (mantém os arquivos)" }
        Write-Host '     M = manter como está'
        Write-Host '     A = apagar a conta e os arquivos dela'
        do {
            $op = (Perguntar 'Escolha').Trim().ToUpper()
        } until ($op -eq 'M' -or $op -eq 'A' -or ($op -eq 'R' -and $podeRenomear))

        if ($op -eq 'M') { Log "Conta $($u.Name) mantida." ; continue }

        if ($perf -and $perf.Loaded) {
            Log "AVISO: a conta $($u.Name) está em uso agora; nada foi feito. Reinicie e rode de novo." 'Yellow'
            continue
        }
        if ($op -eq 'A') {
            if (-not (Perguntar-SN "Tem certeza? A conta $($u.Name) e TODOS os arquivos dela serão apagados")) {
                Log "Conta $($u.Name) mantida." ; continue
            }
            if ($perf) { $caminho = $perf.LocalPath; $perf | Remove-CimInstance; Log "Arquivos $caminho apagados." }
            Remove-LocalUser -SID $u.SID
            Log "Conta $($u.Name) apagada." 'Green'
        } else {
            $antigoNome = $u.Name
            Rename-LocalUser -SID $u.SID -NewName $Cfg.Usuario
            Set-LocalUser -SID $u.SID -FullName $Cfg.Usuario
            Remover-DoGrupo $SID_Admins $Cfg.Usuario
            Log "Conta $antigoNome renomeada para $($Cfg.Usuario) (arquivos mantidos; a pasta continua $($perf.LocalPath))." 'Green'
            $renomeada = $true
            if ($ehAlunos) {
                ([ADSI]"WinNT://$env:COMPUTERNAME/$($Cfg.Usuario),user").SetPassword('')
                Log "Senha da conta $($Cfg.Usuario) removida (a CTI pode definir uma na Manutenção > Senha)."
            } else {
                if (Perguntar-SN "Tirar a senha desta conta, para o PC entrar sozinho nela?") {
                    ([ADSI]"WinNT://$env:COMPUTERNAME/$($Cfg.Usuario),user").SetPassword('')
                    Log "Senha da conta $($Cfg.Usuario) removida."
                } else {
                    Log "AVISO: a conta $($Cfg.Usuario) tem senha; o PC vai mostrar a tela de login em vez de entrar sozinho." 'Yellow'
                }
            }
        }
    }

    if ($Cfg.Tipo -eq 'CTI') {
        # PC do setor CTI: só a conta CTI (com senha); sem conta de uso e sem logon automático
        Etapa 'Conta CTI (este PC não tem conta de uso)'
        Definir-Autologon $false
        if ((Conta-TemSenha $ContaAdmin) -eq $false) { Log 'AVISO: a conta CTI está SEM senha. Defina uma (Manutenção > Senha).' 'Yellow' }
        Log 'Só a conta CTI: sem logon automático (o PC pede a senha da CTI ao ligar).' 'Green'
    } else {
        # =================== 4. Conta de uso + logon automático ===================
        Etapa "Conta $($Cfg.Usuario) e logon automático"
        $nova = -not (Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue)
        if ($nova) {
            New-LocalUser -Name $Cfg.Usuario -NoPassword -FullName $Cfg.Usuario -Description 'Conta de uso do computador' | Out-Null
            ([ADSI]"WinNT://$env:COMPUTERNAME/$($Cfg.Usuario),user").SetPassword('')
            Log "Conta $($Cfg.Usuario) criada, sem senha." 'Green'
        }
        # Primeiro tira dos Administradores: o Windows não deixa um ADMIN ficar sem senha
        # e sem poder trocá-la (erro 1322 / "último Administrador").
        Adicionar-AoGrupo $SID_Usuarios $Cfg.Usuario
        Remover-DoGrupo   $SID_Admins   $Cfg.Usuario
        Enable-LocalUser -Name $Cfg.Usuario
        # A senha que a conta já tiver não é mexida (pode ter sido definida pela CTI na Manutenção)
        if ($ehComp) {
            # Uso compartilhado (labs, professores, alunos): só a CTI define a senha (Manutenção > Senha)
            Set-LocalUser -Name $Cfg.Usuario -FullName $Cfg.Usuario -PasswordNeverExpires $true -UserMayChangePassword $false
            Log "Conta $($Cfg.Usuario): usuário padrão; só a CTI define ou troca a senha (Manutenção > Senha)."
        } else {
            # Administrativo: a própria pessoa pode criar ou trocar a sua senha
            Set-LocalUser -Name $Cfg.Usuario -PasswordNeverExpires $true -UserMayChangePassword $true
            Log "Conta $($Cfg.Usuario): usuário padrão; a própria pessoa pode criar uma senha."
        }

        Definir-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' 'DevicePasswordLessBuildVersion' 0
        if ((Esta-NoDominio) -and (Conta-TemSenha $Cfg.Usuario) -ne $true) {
            Write-Host "   Este PC está no domínio: a conta local $($Cfg.Usuario) é de reserva e precisa de senha." -ForegroundColor Yellow
            Set-LocalUser -Name $Cfg.Usuario -Password (Ler-SenhaNova $Cfg.Usuario)
            Log "Conta $($Cfg.Usuario): senha definida (reserva do domínio)." 'Green'
        }
        if ((Conta-TemSenha $Cfg.Usuario) -eq $true) {
            Definir-Autologon $false
            Log "A conta $($Cfg.Usuario) tem senha: o PC vai pedir a senha ao ligar (sem logon automático)." 'Yellow'
        } else {
            Definir-Autologon $true
            Log "Logon automático na conta $($Cfg.Usuario) (enquanto ela não tiver senha)." 'Green'
        }

        # Recriar o perfil (PCs compartilhados): no próximo logon ele nasce do perfil padrão, já configurado
        if ($ehComp -and -not $renomeada -and -not $nova) {
            $perfU = Perfil-DaConta (Get-LocalUser -Name $Cfg.Usuario)
            if ($perfU) {
                # A conta já existia: PC que estava em uso antes do script (recomendado recriar) ou reaplicação
                # num PC já configurado por ele (não precisa: o perfil já é limpo a cada logon)
                Write-Host ''
                Write-Host "  A conta $($Cfg.Usuario) já existia neste PC. Recriar o perfil apaga tudo em $($perfU.LocalPath);" -ForegroundColor DarkGray
                Write-Host '  no próximo logon ela nasce limpa, já com a configuração deste script.' -ForegroundColor DarkGray
                if ($repeticao) { Write-Host '  Recomendado: N (este PC já foi configurado por este script; o perfil é limpo a cada logon).' -ForegroundColor Yellow }
                else            { Write-Host '  Recomendado: S (a conta é de antes deste script: tira os arquivos e ajustes antigos).' -ForegroundColor Yellow }
                if (Perguntar-SN "Recriar o perfil da conta $($Cfg.Usuario) do zero?") {
                    if ($perfU.Loaded) {
                        Log "AVISO: o perfil $($perfU.LocalPath) está em uso; não foi recriado. Reinicie e rode de novo." 'Yellow'
                    } else {
                        $perfU | Remove-CimInstance
                        Log "Perfil $($perfU.LocalPath) apagado; será recriado no próximo logon." 'Green'
                    }
                }
            }
        }
    }

    # =================== 5. Programas ===================
    Etapa 'Programas do pendrive'
    if ($instalar) {
        # Sem a janela "Este programa pode não ter sido instalado corretamente" durante as instalações
        $pcaChave = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'
        $pcaAntes = (Get-ItemProperty -Path $pcaChave -ErrorAction SilentlyContinue).DisablePCA
        Definir-Reg $pcaChave 'DisablePCA' 1
        $pcaMexido = $true
        # Windows Update sem reinício automático enquanto a instalação roda (volta ao normal no fim)
        $auChave = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        $auAntes = (Get-ItemProperty -Path $auChave -ErrorAction SilentlyContinue).NoAutoRebootWithLoggedOnUsers
        Definir-Reg $auChave 'NoAutoRebootWithLoggedOnUsers' 1
        $auMexido = $true
        Instalar-Programas 'basicos' 'básicos (todos os PCs)'
        if ($Cfg.LabInfo) { Instalar-Programas 'laboratorio' 'do laboratório de informática' }
    } else {
        Log 'Programas não reinstalados (escolha do operador).'
        if ($Cfg.Glpi) { [void](Instalar-AgenteGlpi) }   # o agente GLPI não depende da lista de programas
    }
    if ($ehLab -and (Test-Path 'C:\Program Files\Microsoft VS Code\Code.exe')) {
        # VS Code: extensões numa pasta comum (os alunos usam, mas não instalam nem removem;
        # a CTI instala novas pela Manutenção > Bloqueios > VS Code)
        New-Item -ItemType Directory -Path $PastaExtVSCode -Force | Out-Null
        [Environment]::SetEnvironmentVariable('VSCODE_EXTENSIONS', $PastaExtVSCode, 'Machine')
        if ($instalar) {
            $itens = @($ExtensoesVSCode)
            $pastaVsix = Join-Path (Pasta-Sw) 'vscode-extensoes'
            if (Test-Path $pastaVsix) { $itens += @(Get-ChildItem $pastaVsix -Filter '*.vsix' | Select-Object -ExpandProperty FullName) }
            $null = Instalar-ExtensoesVSCode $itens
        } else {
            $perm = Atualizar-PoliticaVSCode
            Log "VS Code: permitidas só as extensões da pasta comum: $($perm -join ', ')." 'Green'
        }
        # Ícone do VS Code na Área de Trabalho de todos (professor e alunos do lab)
        $sh = New-Object -ComObject WScript.Shell
        $a  = $sh.CreateShortcut($AtalhoVSCode)
        $a.TargetPath       = $CodeExe
        $a.WorkingDirectory = Split-Path $CodeExe
        $a.Description      = 'Visual Studio Code'
        $a.Save()
        Log 'VS Code: ícone na Área de Trabalho de todos.' 'Green'
        if ($TemaVSCode) { Log "VS Code: tema '$TemaVSCode' a cada logon (professor e alunos; a CTI escolhe o seu)." 'Green' }
    }
    if ($ehLab) {
        # Firewall: libera na rede local os programas do lab que abrem portas (sem pedir senha ao aluno)
        $grupoFw = 'IFSP - Programas do laboratório'
        Get-NetFirewallRule -Group $grupoFw -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
        foreach ($pf in $ProgramasFirewall) {
            foreach ($exe in @(Get-Item -Path $pf.Caminho -ErrorAction SilentlyContinue)) {
                # tira regras antigas criadas pela janela do Windows (um "Cancelar" vira regra de bloqueio)
                Get-NetFirewallApplicationFilter -Program $exe.FullName -ErrorAction SilentlyContinue |
                    Get-NetFirewallRule -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
                foreach ($proto in 'TCP', 'UDP') {
                    try {
                        New-NetFirewallRule -DisplayName "IFSP - $($pf.Nome) ($proto)" -Group $grupoFw -Direction Inbound `
                            -Program $exe.FullName -Protocol $proto -Action Allow -Profile Any -RemoteAddress LocalSubnet | Out-Null
                    } catch { Log "AVISO: não criei a regra de firewall de $($pf.Nome) ($($_.Exception.Message))" 'Yellow' }
                }
                Log "Firewall: $($pf.Nome) liberado para a rede local (o aluno não precisa de senha)." 'Green'
            }
        }

    } else {
        # PC que deixou de ser de lab (mudança de lugar): sem as regras de firewall do lab
        Get-NetFirewallRule -Group 'IFSP - Programas do laboratório' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    }
    # VLC: sem atalho na Área de Trabalho (todos os tipos de PC); fica no Menu Iniciar
    Get-ChildItem 'C:\Users\Public\Desktop', 'C:\Users\Default\Desktop' -Filter 'VLC*.lnk' -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    # ONLYOFFICE na Área de Trabalho de todos (todos os tipos de PC, inclusive a CTI)
    if (-not (Get-ChildItem 'C:\Users\Public\Desktop' -Filter 'ONLYOFFICE*.lnk' -Force -ErrorAction SilentlyContinue)) {
        $ooMenu = Atalho-MenuIniciar 'ONLYOFFICE*.lnk'
        if ($ooMenu) { Copy-Item -Path $ooMenu -Destination 'C:\Users\Public\Desktop' -Force; Log 'ONLYOFFICE: ícone na Área de Trabalho de todos.' }
    }
    if ($ehComp) {
        # PCs compartilhados: Área de Trabalho só com Lixeira, Chrome e ONLYOFFICE (+ VS Code nos labs
        # e Veyon Master no PC do professor do lab)
        $removidos = @(Get-ChildItem 'C:\Users\Public\Desktop', 'C:\Users\Default\Desktop' -Filter '*.lnk' -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -ne 'Google Chrome.lnk' -and $_.Name -notlike 'ONLYOFFICE*.lnk' -and
                                      -not ($ehLab -and $_.FullName -eq $AtalhoVSCode) -and
                                      -not ($Cfg.Tipo -eq 'LAB-PROF' -and $_.Name -eq 'Veyon Master.lnk') })
        $removidos | Remove-Item -Force -ErrorAction SilentlyContinue
        $ficam = if ($ehLab) { 'Lixeira, Chrome, ONLYOFFICE e VS Code' } else { 'Lixeira, Chrome e ONLYOFFICE' }
        if ($removidos.Count -gt 0) { Log "Área de Trabalho: $($removidos.Count) atalho(s) de programas removido(s); fica $ficam." 'Green' }
    }
    if ($Cfg.ContaAlunos -and $Cfg.LabInfo -and (Test-Path 'C:\xampp\htdocs')) {
        Padrao-Xampp                                     # htdocs e bancos do MySQL: padrão de recém-instalado
    } elseif (Test-Path (Join-Path $Base 'xampp-pendrive')) {
        Remove-Item -LiteralPath (Join-Path $Base 'xampp-pendrive') -Recurse -Force -ErrorAction SilentlyContinue
    }

    # =================== Veyon e Wake-on-LAN (labs) ===================
    Etapa 'Veyon e Wake-on-LAN'
    if ($script:MudarLugar -and $script:CfgAntigo) { Limpar-VeyonAntigo $script:CfgAntigo }
    if (Usa-Veyon) {
        if ($script:VeyonFeito) { Log 'Veyon: já configurado no começo (com o pendrive).' }
        else                    { Configurar-Veyon ([bool]$instalar) }
        if ($ehComp) { Preparar-WakeOnLan }
    } else {
        Log 'Não se aplica a este tipo de PC.'
    }

    # =================== 6. Apps pré-instalados e OneDrive ===================
    Etapa 'Apps pré-instalados e OneDrive'
    Log 'Removendo apps pré-instalados (pode levar alguns minutos)...'
    $provisionados = @(Get-AppxProvisionedPackage -Online)
    foreach ($app in $AppsRemover) {
        $removeu = $false
        foreach ($p in ($provisionados | Where-Object { $_.DisplayName -eq $app })) {
            try   { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -AllUsers | Out-Null; $removeu = $true }
            catch { Log "AVISO: não removi o provisionado $app ($($_.Exception.Message))" 'Yellow' }
        }
        $instalados = @(Get-AppxPackage -AllUsers -Name $app | Select-Object -ExpandProperty PackageFullName -Unique)
        foreach ($pf in $instalados) {
            try   { Remove-AppxPackage -Package $pf -AllUsers; $removeu = $true }
            catch { Log "AVISO: não removi $pf ($($_.Exception.Message))" 'Yellow' }
        }
        if ($removeu) { Log "App removido: $app" 'Green' }
    }
    # Impede que o Windows fixe/instale o "novo Outlook" em perfis novos
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate',
                   'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate') {
        if (Test-Path $k) {
            try   { Remove-Item -Path $k -Recurse -Force; Log "Removida a instalação automática do Outlook ($k)." }
            catch { Log "AVISO: não consegui remover $k ($($_.Exception.Message))" 'Yellow' }
        }
    }

    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
    $odMaquina = Get-ChildItem 'C:\Program Files\Microsoft OneDrive\*\OneDriveSetup.exe', 'C:\Program Files (x86)\Microsoft OneDrive\*\OneDriveSetup.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($odMaquina) { Start-Process $odMaquina.FullName -ArgumentList '/uninstall /allusers' -Wait; Log 'OneDrive (máquina) desinstalado.' }
    foreach ($exe in "$env:SystemRoot\System32\OneDriveSetup.exe", "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        if (Test-Path $exe) { Start-Process $exe -ArgumentList '/uninstall' -Wait; break }
    }
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 1
    # Sem conteúdo "da nuvem" em perfis novos (ex.: novo Outlook fixado na barra, fixados de instale-me)
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent'       1
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures'     1
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 1
    $tiraOneDriveDoRun = {
        param($hive)
        $run = "$hive\Software\Microsoft\Windows\CurrentVersion\Run"
        if (Test-Path $run) { Remove-ItemProperty -Path $run -Name 'OneDriveSetup', 'OneDrive' -ErrorAction SilentlyContinue }
    }
    Para-CadaPerfil $tiraOneDriveDoRun
    & $tiraOneDriveDoRun 'HKCU:'
    Log 'OneDrive desativado (política + não inicia nos perfis).' 'Green'

    # =================== 7. Tema e papel de parede ===================
    Etapa "Tema ($($Cfg.Tema)) e papel de parede"
    $claro = if ($Cfg.Tema -eq 'claro') { 1 } else { 0 }
    $aplicaTema = {
        param($hive)
        $k = "$hive\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Definir-Reg $k 'AppsUseLightTheme'    $claro
        Definir-Reg $k 'SystemUsesLightTheme' $claro
    }
    Para-CadaPerfil $aplicaTema
    & $aplicaTema 'HKCU:'
    Log "Modo $($Cfg.Tema) aplicado (e reaplicado a cada logon, em todos os usuários)." 'Green'

    # Papel de parede: a imagem fica na pasta $PastaPapel (C:\ProgramData\IFSP\Papel de parede). A CTI pode
    # pôr outra lá depois (a MAIS NOVA vale). Todas as contas, menos a CTI, recebem a imagem bloqueada.
    New-Item -ItemType Directory -Path $PastaPapel -Force | Out-Null
    & icacls.exe $PastaPapel /grant "${ContaAdmin}:(OI)(CI)M" | Out-Null      # a CTI copia imagens sem pedir permissão
    $imgsPasta = @(Imagens-PastaPapel)
    if ($Cfg.PapelPersonalizado -and $imgsPasta.Count -gt 0) {
        Log "Papel de parede: mantida a imagem que a CTI pôs na pasta ($($imgsPasta[0].Name))."
    } else {
        $pastaWall  = Join-Path $Pen 'arquivos\wallpapers'
        $wallOrigem = Join-Path $pastaWall ('{0}-{1}.png' -f $Cfg.Sigla, $Cfg.Tema)
        if (-not (Test-Path $wallOrigem)) { $wallOrigem = Join-Path $pastaWall ('IFSP-{0}.png' -f $Cfg.Tema) }
        if (Test-Path $wallOrigem) {
            $imgsPasta | Remove-Item -Force -ErrorAction SilentlyContinue
            $dest = Join-Path $PastaPapel (Split-Path $wallOrigem -Leaf)
            Copy-Item -Path $wallOrigem -Destination $dest -Force
            (Get-Item -LiteralPath $dest).LastWriteTime = Get-Date
            Log "Papel de parede: $(Split-Path $wallOrigem -Leaf) (fica na pasta $PastaPapel)."
        } elseif ($imgsPasta.Count -eq 0) {
            Log "AVISO: nenhum papel de parede em arquivos\wallpapers nem em $PastaPapel." 'Yellow'
        }
        Definir-CampoCfg 'PapelPersonalizado' $false
    }
    # A mais nova da pasta vira um arquivo com nome novo (o Windows só relê a imagem da política quando o caminho muda)
    $img  = @(Imagens-PastaPapel) | Select-Object -First 1
    $wall = $null
    if ($img) {
        $wall = Join-Path $Base ('papel-de-parede-{0:yyyyMMdd-HHmmss}{1}' -f (Get-Date), $img.Extension.ToLower())
        Copy-Item -LiteralPath $img.FullName -Destination $wall -Force
        Get-ChildItem $Base -Filter 'papel-de-parede*' -File | Where-Object { $_.FullName -ne $wall } | Remove-Item -Force -ErrorAction SilentlyContinue
        Definir-CampoCfg 'PapelDeParede' $wall
        Definir-CampoCfg 'PapelOrigem'   ('{0}|{1}' -f $img.Name, $img.LastWriteTimeUtc.Ticks)
        Definir-CampoCfg 'PapelVersao'   (Get-Date -Format 'yyyyMMddHHmmss')
    }
    $papelBloq = Bloqueio-Ativo 'Papel'         # Manutenção > Bloqueios (ou > Papel de parede > 4)
    Definir-CampoCfg 'BloqueioPapelAplicado' $papelBloq
    Salvar-Config
    # Até a v3.3 o bloqueio era da máquina (valia até para a CTI): sai daqui
    Apagar-Reg 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' @('Wallpaper', 'WallpaperStyle')
    Apagar-Reg 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop' @('NoChangingWallPaper')
    if ($wall) {
        # Perfil padrão e conta de uso: imagem bloqueada (a tarefa do sistema reaplica a cada logon, menos na CTI)
        $bloqWall = {
            param($hive)
            if ($papelBloq) {
                Definir-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\System"        'Wallpaper'      $wall 'String'
                Definir-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\System"        'WallpaperStyle' '4'   'String'   # 4 = Preencher
                Definir-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" 'NoChangingWallPaper' 1
            } else {
                Apagar-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\System"        @('Wallpaper', 'WallpaperStyle')
                Apagar-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" @('NoChangingWallPaper')
            }
        }
        Para-CadaPerfil $bloqWall
        # CTI (esta sessão): sem bloqueio; recebe a imagem (cópia própria, que a troca não apaga) e pode trocar a sua
        Apagar-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System' @('Wallpaper', 'WallpaperStyle')
        Apagar-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop' @('NoChangingWallPaper')
        $copiaCti = Join-Path $Base ('papel-cti-{0:yyyyMMdd-HHmmss}{1}' -f (Get-Date), [IO.Path]::GetExtension($wall))
        Copy-Item -LiteralPath $wall -Destination $copiaCti -Force
        Get-ChildItem $Base -Filter 'papel-cti-*' -File | Where-Object { $_.FullName -ne $copiaCti } | Remove-Item -Force -ErrorAction SilentlyContinue
        Definir-Reg 'HKCU:\Control Panel\Desktop' 'WallpaperStyle' '10' 'String'
        Definir-Reg 'HKCU:\Control Panel\Desktop' 'TileWallpaper'  '0'  'String'
        Papel-NaSessao $copiaCti
        Definir-CampoCfg 'PapelCTI' $copiaCti
        Salvar-Config
        if ($papelBloq) { Log 'Papel de parede bloqueado em todas as contas, menos a CTI (para trocar: Manutenção > Papel de parede).' 'Green' }
        else            { Log "Papel de parede: $(Texto-Bloqueio 'Papel') (Manutenção > Bloqueios)." 'Yellow' }
        Definir-TelaBloqueio $wall
        Log 'Tela de bloqueio e de login: a mesma imagem, sem as fotos e dicas da Microsoft.' 'Green'
    }

    # =================== 8. Energia ===================
    Etapa 'Energia'
    & powercfg.exe /setactive SCHEME_MIN | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & powercfg.exe /duplicatescheme SCHEME_MIN | Out-Null
        & powercfg.exe /setactive SCHEME_MIN | Out-Null
    }
    if ($LASTEXITCODE -eq 0) { Log 'Plano Alto desempenho ativado.' 'Green' }
    else                     { Log 'AVISO: o Windows não aceitou o plano Alto desempenho.' 'Yellow' }
    & powercfg.exe /change standby-timeout-ac 0 | Out-Null     # na tomada: nunca suspende
    & powercfg.exe /change monitor-timeout-ac 15 | Out-Null    # tela apaga em 15 min
    & powercfg.exe /hibernate off | Out-Null                   # sem hibernação (ajuda o Wake-on-LAN)
    Log 'Na tomada: nunca suspende; tela apaga em 15 min; sem hibernação.'

    # =================== 9. Barra de tarefas e Menu Iniciar ===================
    Etapa 'Barra de tarefas e Menu Iniciar'
    $chromeLnk = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk'
    $pinChrome = ''
    if (Test-Path $chromeLnk) {
        $pinChrome = '<taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"/>'
    } else {
        Log 'AVISO: atalho do Chrome não encontrado; Chrome não foi fixado na barra.' 'Yellow'
    }
    $pinOffice = ''                                     # ONLYOFFICE na barra de todos os tipos de PC
    $oo = Atalho-MenuIniciar 'ONLYOFFICE*.lnk'
    if ($oo) {
        $ooRel = $oo.Replace('C:\ProgramData', '%ALLUSERSPROFILE%')
        $pinOffice = "<taskbar:DesktopApp DesktopApplicationLinkPath=`"$ooRel`"/>"
    } else {
        Log 'AVISO: atalho do ONLYOFFICE não encontrado; não foi fixado na barra.' 'Yellow'
    }
    $xmlBarra = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationID="Microsoft.Windows.Explorer"/>
        $pinChrome
        $pinOffice
        <taskbar:UWA AppUserModelID="Microsoft.WindowsNotepad_8wekyb3d8bbwe!App"/>
        <taskbar:UWA AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"/>
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
    $polExp = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    if ($ehComp) {
        # PCs compartilhados: barra fixa por política, reaplicada a cada logon (vale para todos, inclusive a CTI).
        # Dá para desbloquear na Manutenção > Bloqueios (a tarefa do sistema mantém como estiver escolhido).
        $xmlArquivo = Join-Path $Base 'barra-tarefas.xml'
        Set-Content -Path $xmlArquivo -Value $xmlBarra -Encoding UTF8
        Aplicar-BloqueioBarra (Bloqueio-Ativo 'Barra')
        if (Bloqueio-Ativo 'Barra') { Log 'Barra: Explorador, Chrome, ONLYOFFICE, Bloco de Notas e Calculadora (bloqueada).' 'Green' }
        else { Log "Barra de tarefas: $(Texto-Bloqueio 'Barra') (Manutenção > Bloqueios)." 'Yellow' }
    } else {
        # Outros locais: vale no primeiro logon de contas novas; a pessoa pode mudar depois
        Apagar-Reg $polExp @('StartLayoutFile', 'LockedStartLayout')
        $shellDef = 'C:\Users\Default\AppData\Local\Microsoft\Windows\Shell'
        New-Item -ItemType Directory -Path $shellDef -Force | Out-Null
        Set-Content -Path (Join-Path $shellDef 'LayoutModification.xml') -Value $xmlBarra -Encoding UTF8
        Log 'Barra: Explorador, Chrome, ONLYOFFICE, Bloco de Notas e Calculadora (pode ser mudada).' 'Green'
    }
    Definir-Reg $polExp 'HideTaskViewButton' 1
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'SearchOnTaskbarMode'   0
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Log 'Barra sem widgets, sem caixa de pesquisa, sem Visão de Tarefas e sem Copilot.'

    if ($ehLab) {
        $startOrigem  = Join-Path $Pen 'arquivos\start2.bin'
        $startDestino = Join-Path $Base 'start2.bin'
        if (Test-Path $startOrigem) { Copy-Item -Path $startOrigem -Destination $startDestino -Force }
        if (Test-Path $startDestino) {
            $relStart = 'AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
            $perfis = @('C:\Users\Default')
            $perfU = Perfil-DaConta (Get-LocalUser -Name $Cfg.Usuario -ErrorAction SilentlyContinue)
            if ($perfU) { $perfis += $perfU.LocalPath }
            foreach ($pf in $perfis) {
                $dest = Join-Path $pf $relStart
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                Copy-Item -Path $startDestino -Destination (Join-Path $dest 'start2.bin') -Force
            }
            Log 'Menu Iniciar: fixados do laboratório copiados (start2.bin).' 'Green'
        } else {
            Log 'Menu Iniciar: sem arquivos\start2.bin (opcional); fixados não alterados.'
        }
    }
    Definir-Reg $polExp 'HideRecentlyAddedApps' 1
    $menuLimpo = {
        param($hive)
        $kS = "$hive\Software\Microsoft\Windows\CurrentVersion\Start"
        $kA = "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Definir-Reg $kS 'AllAppsViewMode'            2   # 2 = Lista
        Definir-Reg $kA 'Start_TrackProgs'           0   # apps mais usados/recentes
        Definir-Reg $kA 'Start_TrackDocs'            0   # arquivos recentes
        Definir-Reg $kA 'Start_IrisRecommendations'  0   # dicas e sugestões
        Definir-Reg $kA 'Start_AccountNotifications' 0   # avisos de conta
        Definir-Reg $kA 'ShowTaskViewButton'         0
        Definir-Reg "$hive\Software\Policies\Microsoft\Windows\Explorer" 'HideRecentlyAddedApps' 1
    }
    Para-CadaPerfil $menuLimpo
    & $menuLimpo 'HKCU:'
    Log 'Menu Iniciar: "Todos" em lista, sem recomendações nem recentes.' 'Green'

    # Win+V (histórico da área de transferência) ativado para todos
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowClipboardHistory' 1
    $winV = {
        param($hive)
        Definir-Reg "$hive\Software\Microsoft\Clipboard" 'EnableClipboardHistory' 1
        if ($ehComp) { Definir-Reg "$hive\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" 'RestartApps' 0 }
    }
    Para-CadaPerfil $winV
    Definir-Reg 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory' 1
    Log 'Win+V ativado.'

    # =================== 10. Navegadores ===================
    Etapa 'Navegadores (Chrome e Edge)'
    $Favoritos = Montar-JsonFavoritos           # pasta Favoritos: IFSP (SUAP, Moodle) e a lista do PC (Manutenção > Favoritos)

    # Começa do zero (o PC pode ter mudado de tipo) e grava só o que vale para este tipo
    foreach ($k in 'HKLM:\SOFTWARE\Policies\Google\Chrome', 'HKLM:\SOFTWARE\Policies\Microsoft\Edge') {
        if (Test-Path $k) { Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue }
    }

    $ch = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
    Definir-Reg $ch 'DefaultBrowserSettingEnabled' 0          # não pergunta se quer ser o padrão
    # Página inicial/páginas ao abrir NÃO vão por política: fora de domínio o Windows/Chrome ignora.
    # Vão pelo arquivo initial_preferences (perfis novos) e pela URL nos atalhos (abaixo).
    Definir-Reg $ch 'ShowHomeButton'        1
    Definir-Reg $ch 'BookmarkBarEnabled'    1
    Definir-Reg $ch 'ManagedBookmarks'      $Favoritos 'String'

    $ed = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    Definir-Reg $ed 'HideFirstRunExperience'       1
    Definir-Reg $ed 'DefaultBrowserSettingEnabled' 0
    Definir-Reg $ed 'HubsSidebarEnabled'           0          # barra lateral
    Definir-Reg $ed 'Microsoft365CopilotChatIconEnabled' 0    # botão Copilot/Chat
    Definir-Reg $ed 'ShowMicrosoftRewards'         0
    Definir-Reg $ed 'EdgeShoppingAssistantEnabled' 0
    Definir-Reg $ed 'ShowRecommendationsEnabled'   0
    Definir-Reg $ed 'SpotlightExperiencesAndRecommendationsEnabled' 0
    Definir-Reg $ed 'PersonalizationReportingEnabled' 0
    Definir-Reg $ed 'NewTabPageContentEnabled'     0
    Definir-Reg $ed 'NewTabPageQuickLinksEnabled'  0
    Definir-Reg $ed 'StartupBoostEnabled'          0
    Definir-Reg $ed 'BackgroundModeEnabled'        0
    Definir-Reg $ed 'ShowHomeButton'        1
    Definir-Reg $ed 'FavoritesBarEnabled'   1
    Definir-Reg $ed 'ManagedFavorites'      $Favoritos 'String'

    # Anônimo/InPrivate (PCs compartilhados): política de USUÁRIO, em todas as contas menos a CTI. A tarefa do sistema
    # reaplica a cada logon e a cada 5 min (vale também para contas criadas depois). Bloqueio "Navegador".
    $null = Para-Conta $Cfg.Usuario $script:PolNavegadorConta
    foreach ($linha in $RestricoesUsuario) {      # a CTI (esta sessão) fica sempre com o navegador normal
        $c = $linha.Split('|'); Apagar-Reg "HKCU:\$($c[0])" @($c[1])
    }
    if ($ehComp) {
        Definir-Reg $ch 'DeveloperToolsAvailability' 1        # F12 liberado
        Definir-Reg $ed 'DeveloperToolsAvailability' 1
        Definir-Reg $ed 'ImportFavorites'            0
        if (Bloqueio-Ativo 'Navegador') { Log "Chrome sempre anônimo e Edge sempre InPrivate, sem login nem senhas salvas ($($Cfg.Usuario) e demais contas; a CTI usa o navegador normal)." 'Green' }
        else { Log "Navegador: $(Texto-Bloqueio 'Navegador') (Manutenção > Bloqueios)." 'Yellow' }
    } else {
        Log 'Chrome e Edge em modo normal (login e senhas liberados).' 'Green'
    }
    $favTxt = if ($comMoodle) { 'SUAP e Moodle' } else { 'SUAP' }
    $nFav = @(Ler-ListaFavoritos ([string]$Cfg.Favoritos)).Count
    Log ("Página inicial {0}; favoritos: pasta {1} > IFSP ({2}){3}." -f $Cfg.PaginaInicial, $PastaFavoritos, $favTxt, $(if ($nFav -gt 0) { " e mais $nFav favorito(s) da lista do campus" } else { '' })) 'Green'

    # Atalho do Edge na área de trabalho: apaga e impede que as atualizações recriem
    Get-ChildItem 'C:\Users\*\Desktop\Microsoft Edge.lnk' -Force -ErrorAction SilentlyContinue | Remove-Item -Force
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' 'CreateDesktopShortcutDefault' 0
    Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' 'CreateDesktopShortcut{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}' 0

    # Página inicial do campus: as políticas de página inicial só valem em PC de domínio.  Por isso:
    #  1) initial_preferences (Chrome e Edge): página inicial e páginas ao abrir para perfis NOVOS;
    #  2) URL nos atalhos (Menu Iniciar, área de trabalho e barra de tarefas de todas as contas).
    $prefs = [ordered]@{
        homepage               = $Cfg.PaginaInicial
        homepage_is_newtabpage = $false
        browser                = [ordered]@{ show_home_button = $true; check_default_browser = $false }
        session                = [ordered]@{ restore_on_startup = 4; startup_urls = @($Cfg.PaginaInicial) }
        bookmark_bar           = [ordered]@{ show_on_all_tabs = $true }
        sync_promo             = [ordered]@{ show_on_first_run_allowed = $false }
        distribution           = [ordered]@{ skip_first_run_ui = $true; suppress_first_run_default_browser_prompt = $true;
                                             import_bookmarks = $false; import_history = $false; import_search_engine = $false }
    }
    $jsonPrefs = ConvertTo-Json -InputObject $prefs -Depth 5
    $utf8SemBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($dir in 'C:\Program Files\Google\Chrome\Application', 'C:\Program Files (x86)\Microsoft\Edge\Application') {
        if (Test-Path $dir) {
            [IO.File]::WriteAllText((Join-Path $dir 'initial_preferences'), $jsonPrefs, $utf8SemBom)
            Log "Página inicial para perfis novos: $dir\initial_preferences"
        }
    }
    $shell = New-Object -ComObject WScript.Shell
    $atalhosNav = @('C:\Users\Public\Desktop\Google Chrome.lnk', $chromeLnk,
                    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk')
    $atalhosNav += @(Get-ChildItem 'C:\Users\*\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk',
                                   'C:\Users\*\Desktop\*.lnk' -Force -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -in 'Google Chrome.lnk', 'Microsoft Edge.lnk' } | Select-Object -ExpandProperty FullName)
    foreach ($lnk in $atalhosNav) {
        if (Test-Path $lnk) {
            $a = $shell.CreateShortcut($lnk)
            $a.Arguments = "--start-maximized $($Cfg.PaginaInicial)"     # sem perfil guardado, a janela abria pequena
            $a.Save()
        }
    }
    Log 'Atalhos do Chrome e do Edge abrem maximizados, no site do campus.' 'Green'

    # Chrome como navegador e leitor de PDF padrão (vale para perfis novos)
    if (Test-Path $chromeLnk) {
        $progPdf = if (Test-Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\ChromePDF') { 'ChromePDF' } else { 'ChromeHTML' }
        $xmlAssoc = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".htm"  ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".pdf"  ProgId="$progPdf" ApplicationName="Google Chrome" />
  <Association Identifier="http"  ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@
        $assocArq = Join-Path $Base 'associacoes.xml'
        Set-Content -Path $assocArq -Value $xmlAssoc -Encoding UTF8
        & dism.exe /Online /Import-DefaultAppAssociations:"$assocArq" | Out-Null
        if ($LASTEXITCODE -eq 0) { Log 'Chrome definido como navegador e leitor de PDF padrão (contas novas).' 'Green' }
        else { Log "AVISO: o DISM não importou as associações (código $LASTEXITCODE)." 'Yellow' }
        if ($renomeada) { Log 'Obs.: na conta renomeada (perfil antigo) o navegador/leitor de PDF padrão não muda.' 'DarkGray' }
    }

    # =================== 11. Impressão ===================
    Etapa 'Impressão e bloqueios'
    if ($ehAlunos) {
        # Sem instalação automática de impressoras da rede
        Definir-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' 'AutoSetup' 0
        # Bloqueio "Impressao": a conta Alunos não adiciona/remove impressoras nem imprime nas do campus
        Aplicar-BloqueioImpressao (Bloqueio-Ativo 'Impressao')
        if (Bloqueio-Ativo 'Impressao') { Log 'Alunos: bloqueio de impressão nas impressoras do campus (PDF liberado), reaplicado a cada logon e a cada 5 min.' 'Green' }
        else { Log "Impressão da conta Alunos: $(Texto-Bloqueio 'Impressao') (Manutenção > Bloqueios)." 'Yellow' }
    } else {
        Apagar-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' @('AutoSetup')
        Log 'Impressão liberada neste tipo de PC.'
    }
    if ($ehAlunos) {
        Aplicar-BloqueioConfiguracoes (Bloqueio-Ativo 'Configuracoes')
        if (Bloqueio-Ativo 'Configuracoes') { Log 'Bloqueios da conta Alunos: sem Painel de Controle/Configurações e sem Editor do Registro (CTI livre; Manutenção > Bloqueios).' 'Green' }
        else { Log "Configurações da conta Alunos: $(Texto-Bloqueio 'Configuracoes') (Manutenção > Bloqueios)." 'Yellow' }
    } elseif (Get-LocalUser -Name $ContaAluno -ErrorAction SilentlyContinue) {
        Aplicar-BloqueioConfiguracoes $false
    }

    # =================== 12. Scripts de logon, log e tarefas ===================
    Etapa 'Scripts de logon, log e tarefas agendadas'
    if (-not [Diagnostics.EventLog]::SourceExists('IFSP')) { New-EventLog -LogName Application -Source 'IFSP' }

    # ---- Pop-up de logon: listas $RegrasLab, $RegrasBiblioteca, $RegrasOutrosLocais e $AvisoProfessor, no topo do script ----
    Gravar-TextosPopup

    # ---- Script de logon (todo usuário, a cada logon; e no logoff dos PCs compartilhados) ----
    $logonScript = Join-Path $Base 'logon-usuario.ps1'
    $conteudoLogon = @'
# logon-usuario.ps1 - Manutenção de Computadores IFSP
# Roda a cada logon de qualquer usuário (tarefa \IFSP\Logon do usuario) e, nos PCs de uso
# compartilhado (labs, professores, alunos), também no logoff (política local, com -Modo Logoff).
# -Modo Ajustes: chamado pelo próprio script, em paralelo com o pop-up de regras.
param([string]$Modo = 'Logon')
$ErrorActionPreference = 'SilentlyContinue'
$Base = 'C:\ProgramData\IFSP'
$cfg  = Get-Content (Join-Path $Base 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $cfg) { exit }
$usuario = $env:USERNAME
$ehCTI   = ($usuario -eq 'CTI')
# usuário do domínio (UCS/AD): perfil não é limpo e não vê o aviso de limpeza (o domínio de uma conta local é o nome do PC)
$ehDoDominio = [bool]($env:USERDOMAIN -and $env:USERDOMAIN -ne $env:COMPUTERNAME)
$ehComp  = [bool]$cfg.Compartilhado      # uso compartilhado: limpeza das pastas, Win+V, Bloco de Notas
$ehAlunos = [bool]$cfg.ContaAlunos       # conta Alunos: pop-up de regras, impressoras de rede
function Registrar([int]$Id, [string]$Msg) {
    try { Write-EventLog -LogName Application -Source 'IFSP' -EventId $Id -EntryType Information -Message $Msg } catch { }
}
function Limpar-Htdocs {      # XAMPP: htdocs e bancos do MySQL voltam ao padrão (recém-instalado)
    $htdocs = 'C:\xampp\htdocs'
    $padrao = 'C:\ProgramData\IFSP\htdocs-padrao'
    if (-not (Test-Path -LiteralPath $htdocs)) { return $false }
    Get-ChildItem -LiteralPath $htdocs -Force | Remove-Item -Recurse -Force
    if (Test-Path -LiteralPath $padrao) { Copy-Item -Path (Join-Path $padrao '*') -Destination $htdocs -Recurse -Force }
    $dados    = 'C:\xampp\mysql\data'
    $bdPadrao = 'C:\ProgramData\IFSP\mysql-data-padrao'
    if ((Test-Path -LiteralPath $bdPadrao) -and (Test-Path -LiteralPath $dados)) {
        Get-Process -Name mysqld -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Get-ChildItem -LiteralPath $dados -Force | Remove-Item -Recurse -Force
        Copy-Item -Path (Join-Path $bdPadrao '*') -Destination $dados -Recurse -Force
    }
    return $true
}

# Pop-up PRIMEIRO (PCs compartilhados, exceto a CTI; Manutenção > Pop-up de logon liga/desliga), para aparecer
# o mais rápido possível. Os outros ajustes (limpeza, tema, volume...) rodam ao mesmo tempo, em outro processo
# (-Modo Ajustes). Alunos: regras, Aceito / Não aceito (recusar ou fechar = logoff). Professores: aviso, Entendi.
$popupLigado = -not ($cfg.PSObject.Properties.Name -contains 'PopupLogon') -or [bool]$cfg.PopupLogon
if ($Modo -eq 'Logon' -and $ehComp -and -not $ehCTI -and $popupLigado -and -not ($ehDoDominio -and -not $ehAlunos)) {
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -Modo Ajustes"
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $onde = if ([string]$cfg.Tipo -like 'LAB-*') { 'dos laboratórios' } else { 'dos computadores' }
    $tituloTxt = if ($ehAlunos) { "Regras de uso $onde – IFSP Campus " + $cfg.Campus } else { 'Antes de começar – IFSP Campus ' + $cfg.Campus }

    $fonte = 'Segoe UI'
    $f = New-Object System.Windows.Forms.Form
    $f.Text            = $tituloTxt
    $f.FormBorderStyle = 'None'
    $f.WindowState     = 'Maximized'
    $f.TopMost         = $true
    $f.ShowInTaskbar   = $true
    $f.BackColor       = [System.Drawing.Color]::FromArgb(24, 25, 28)

    $painel = New-Object System.Windows.Forms.Panel
    $painel.Size      = New-Object System.Drawing.Size(860, 600)
    $painel.BackColor = [System.Drawing.Color]::FromArgb(43, 45, 49)
    $f.Controls.Add($painel)

    $titulo = New-Object System.Windows.Forms.Label
    $titulo.Text      = $tituloTxt
    $titulo.Font      = New-Object System.Drawing.Font($fonte, 16, [System.Drawing.FontStyle]::Bold)
    $titulo.ForeColor = [System.Drawing.Color]::White
    $titulo.Location  = New-Object System.Drawing.Point(30, 25)
    $titulo.Size      = New-Object System.Drawing.Size(800, 40)
    $painel.Controls.Add($titulo)

    $texto = New-Object System.Windows.Forms.Label
    # Texto das regras: arquivo regras.txt (gravado pelo instalador a partir das listas de regras), uma por linha
    # Linhas de um arquivo de texto (sem BOM, sem espaços nas pontas, sem linhas vazias); arquivo vazio = nenhuma
    function Ler-Linhas([string]$Arq) {
        if (-not (Test-Path -LiteralPath $Arq)) { return @() }
        $t = ''
        try { $t = [IO.File]::ReadAllText($Arq, [Text.Encoding]::UTF8) } catch { return @() }
        return @($t -split "`r?`n" | ForEach-Object { $_.Trim().TrimStart([char]0xFEFF).Trim() } | Where-Object { $_ })
    }
    $regras = @(Ler-Linhas (Join-Path $Base 'regras.txt'))
    if ($regras.Count -eq 0) { $regras = @('Ao sair, salve seus arquivos (na nuvem ou no pendrive): este computador é limpo a cada uso.') }
    if ($cfg.PastaSegura -and -not $ehDoDominio) { $regras += @(Ler-Linhas (Join-Path $Base 'pasta-segura.txt')) }
    $regras += @(Ler-Linhas (Join-Path $Base 'aviso-final.txt'))     # último aviso (só alunos): ex.: desligar os PCs
    if ($ehDoDominio) { $regras = @($regras | Where-Object { $_ -notmatch 'limp[oa] a cada uso|apagad' }) }   # domínio: nada é apagado
    # nunca a mesma linha duas vezes, venha de onde vier (todos os tipos de PC e de login)
    $vistas = @{}
    $regras = @(foreach ($r in $regras) { $k = $r.ToLower(); if (-not $vistas.ContainsKey($k)) { $vistas[$k] = $true; $r } })
    $texto.Text = (($regras | ForEach-Object { [char]0x2022 + '  ' + $_.Trim() }) -join "`r`n`r`n")
    $texto.Font      = New-Object System.Drawing.Font($fonte, 13)
    $texto.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $texto.Location  = New-Object System.Drawing.Point(30, 85)
    $texto.Size      = New-Object System.Drawing.Size(800, 430)
    $painel.Controls.Add($texto)

    $btnSim = New-Object System.Windows.Forms.Button
    $btnSim.Text         = 'Aceito'
    $btnSim.Font         = New-Object System.Drawing.Font($fonte, 12, [System.Drawing.FontStyle]::Bold)
    $btnSim.Size         = New-Object System.Drawing.Size(170, 48)
    $btnSim.Location     = New-Object System.Drawing.Point(470, 530)
    $btnSim.BackColor    = [System.Drawing.Color]::FromArgb(50, 160, 65)
    $btnSim.ForeColor    = [System.Drawing.Color]::White
    $btnSim.FlatStyle    = 'Flat'
    $btnSim.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $painel.Controls.Add($btnSim)

    if (-not $ehAlunos) {                         # professor: só um botão, no lugar do "Não aceito"
        $btnSim.Text = 'Entendi'
        $btnSim.Location = New-Object System.Drawing.Point(660, 530)
    }
    $btnNao = New-Object System.Windows.Forms.Button
    $btnNao.Text         = 'Não aceito'
    $btnNao.Font         = New-Object System.Drawing.Font($fonte, 12)
    $btnNao.Size         = New-Object System.Drawing.Size(170, 48)
    $btnNao.Location     = New-Object System.Drawing.Point(660, 530)
    $btnNao.BackColor    = [System.Drawing.Color]::FromArgb(90, 92, 98)
    $btnNao.ForeColor    = [System.Drawing.Color]::White
    $btnNao.FlatStyle    = 'Flat'
    $btnNao.DialogResult = [System.Windows.Forms.DialogResult]::No
    if ($ehAlunos) { $painel.Controls.Add($btnNao) }

    $f.AcceptButton = $btnSim
    $centralizar = {
        $painel.Left = [int](($f.ClientSize.Width  - $painel.Width)  / 2)
        $painel.Top  = [int](($f.ClientSize.Height - $painel.Height) / 2)
    }
    $f.Add_Shown({ & $centralizar; $f.Activate() })
    $f.Add_Resize({ & $centralizar })

    $resposta = $f.ShowDialog()
    if (-not $ehAlunos) {
        Registrar 1001 "Aviso de logon visto por $usuario"
    } elseif ($resposta -eq [System.Windows.Forms.DialogResult]::OK) {
        Registrar 1001 "Regras ACEITAS por $usuario"
    } else {
        Registrar 1002 "Regras RECUSADAS por $usuario (logoff)"
        & shutdown.exe /l
        exit
    }
    exit
}

# 0) Limpeza do perfil (PCs compartilhados, exceto a CTI e os usuários do domínio). A "Pasta Segura" (se ligada) nunca é apagada.
if ($ehComp -and -not $ehCTI -and -not $ehDoDominio) {
    $desk = [Environment]::GetFolderPath('Desktop')
    $segura = $null
    if ($cfg.PastaSegura) {
        $segura = Join-Path $desk 'Pasta Segura'
        if (-not (Test-Path -LiteralPath $segura)) { New-Item -ItemType Directory -Path $segura -Force | Out-Null }
        # ícone de cadeado: desktop.ini escondido dentro da pasta + pasta marcada como "somente leitura"
        $icone = if ($cfg.IconePastaSegura) { [string]$cfg.IconePastaSegura } else { '%SystemRoot%\System32\shell32.dll,47' }
        $ini = Join-Path $segura 'desktop.ini'
        $iniOk = (Test-Path -LiteralPath $ini) -and ((Get-Content -LiteralPath $ini -Raw) -match [regex]::Escape("IconResource=$icone"))
        if (-not $iniOk) {
            if (Test-Path -LiteralPath $ini) { & attrib.exe -h -s -r "$ini" }
            Set-Content -LiteralPath $ini -Encoding Unicode -Value @('[.ShellClassInfo]', "IconResource=$icone", 'InfoTip=O que estiver aqui não é apagado nas limpezas.')
            & attrib.exe +h +s "$ini"
            & attrib.exe +r "$segura"
        }
    }
    $pastas = @(foreach ($f in 'Desktop', 'MyDocuments', 'MyPictures', 'MyVideos', 'MyMusic') { [Environment]::GetFolderPath($f) })
    $pastas += (Join-Path $env:USERPROFILE 'Downloads')
    $pastas += $env:TEMP
    foreach ($p in $pastas) {
        if ($p -and (Test-Path -LiteralPath $p)) {
            Get-ChildItem -LiteralPath $p -Force |
                Where-Object { $_.Name -ne 'desktop.ini' -and $_.FullName -ne $segura -and
                               -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
                Remove-Item -Recurse -Force
        }
    }
    Clear-RecycleBin -Force

    # VS Code: começa sempre limpo (abas, recentes, histórico e contas da aula anterior)
    $vsUser = Join-Path $env:APPDATA 'Code'
    if (Test-Path -LiteralPath $vsUser) { Remove-Item -LiteralPath $vsUser -Recurse -Force }
    # ... e com o tema escolhido pela CTI ($TemaVSCode no instalador), que dá para trocar durante a aula
    if ($cfg.TemaVSCode -and (Test-Path 'C:\Program Files\Microsoft VS Code\Code.exe')) {
        $vsCfg = Join-Path $vsUser 'User'
        New-Item -ItemType Directory -Path $vsCfg -Force | Out-Null
        $json = @{ 'workbench.colorTheme' = [string]$cfg.TemaVSCode } | ConvertTo-Json
        [IO.File]::WriteAllText((Join-Path $vsCfg 'settings.json'), $json, (New-Object System.Text.UTF8Encoding($false)))
    }
    foreach ($linha in (& cmdkey.exe /list 2>$null)) {
        if ($linha -match 'vscode' -and $linha -match ':\s*(\S*vscode\S*)\s*$') {
            $alvo = $Matches[1]
            & cmdkey.exe "/delete:$alvo" 2>$null | Out-Null
            if ($alvo -match 'target=(.+)$') { & cmdkey.exe "/delete:$($Matches[1])" 2>$null | Out-Null }
        }
    }

    # Bloco de Notas: apaga abas da sessão anterior; não reabrir apps após reiniciar
    $wl = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
    if (-not (Test-Path $wl)) { New-Item -Path $wl -Force | Out-Null }
    Set-ItemProperty -Path $wl -Name RestartApps -Value 0 -Type DWord
    $np = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState'
    foreach ($pasta in 'TabState', 'WindowState') {
        $alvo = Join-Path $np $pasta
        if (Test-Path $alvo) { Get-ChildItem $alvo -Force | Remove-Item -Recurse -Force }
    }
}

# 1) Win+V: apaga o histórico da área de transferência (PCs compartilhados)
if ($ehComp) {
    $pinned = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Clipboard\Pinned'
    if (Test-Path $pinned) { Get-ChildItem $pinned -Force | Remove-Item -Recurse -Force }
    try {
        $null = [Windows.ApplicationModel.DataTransfer.Clipboard, Windows.ApplicationModel.DataTransfer, ContentType = WindowsRuntime]
        $null = [Windows.ApplicationModel.DataTransfer.Clipboard]::ClearHistory()
    } catch { }
}

# 2) Alunos: tira impressoras de rede adicionadas na conta (o bloqueio das locais é feito pelo sistema),
#    a não ser que a CTI tenha desbloqueado a impressão (Manutenção > Bloqueios)
$impBloq = -not ($null -ne $cfg.BloqueioImpressao -and -not [bool]$cfg.BloqueioImpressao)
if ($impBloq -and $cfg.BloqueioImpressaoAte -and ((Get-Date) -lt [datetime]$cfg.BloqueioImpressaoAte)) { $impBloq = $false }
if ($ehAlunos -and -not $ehCTI -and $impBloq) {
    Get-Printer | Where-Object { $_.Type -eq 'Connection' } | Remove-Printer
}

if ($Modo -eq 'Logoff') {      # no logoff: só a limpeza e o registro
    # XAMPP volta ao padrão, a não ser que a CTI tenha desbloqueado (Manutenção > Bloqueios > XAMPP)
    $xBloq = -not ($null -ne $cfg.BloqueioXampp -and -not [bool]$cfg.BloqueioXampp)
    if ($xBloq -and $cfg.BloqueioXamppAte -and ((Get-Date) -lt [datetime]$cfg.BloqueioXamppAte)) { $xBloq = $false }
    if ($cfg.ContaAlunos -and $cfg.LabInfo -and -not $ehCTI -and $xBloq) {
        if (Limpar-Htdocs) { Registrar 1003 "htdocs e bancos do XAMPP restaurados no logoff de $usuario" }
    }
    if ($ehComp -and -not $ehCTI -and -not $ehDoDominio) { Registrar 1003 "Perfil de $usuario limpo no logoff" }
    exit
}

# 3) Agente (labs, salas e CIE; menos a CTI): aviso do desligamento das 23:30, com o botão Adiar
$agente = Join-Path $Base 'agente-usuario.ps1'
if ($cfg.Horarios.Ativo -and -not $ehCTI -and (Test-Path $agente)) {
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$agente`""
}

# 4) Tema claro/escuro escolhido pela CTI (todos os usuários, reaplicado sempre)
Add-Type -Namespace IFSP -Name Win32 -MemberDefinition @"
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr hWnd, uint Msg, System.UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out System.UIntPtr lpdwResult);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
"@
$claro = if ($cfg.Tema -eq 'claro') { 1 } else { 0 }
$k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
$atual = Get-ItemProperty $k
$mudou = ($atual.AppsUseLightTheme -ne $claro) -or ($atual.SystemUsesLightTheme -ne $claro)
Set-ItemProperty -Path $k -Name AppsUseLightTheme    -Value $claro -Type DWord
Set-ItemProperty -Path $k -Name SystemUsesLightTheme -Value $claro -Type DWord
if ($mudou) {
    $r = [System.UIntPtr]::Zero
    [void][IFSP.Win32]::SendMessageTimeout([System.IntPtr]0xffff, 0x1A, [System.UIntPtr]::Zero, 'ImmersiveColorSet', 2, 5000, [ref]$r)
}

# 5) Papel de parede: bloqueado por política em cada conta (menos a CTI), pela tarefa do sistema.

# 6) Volume 0 e mudo ao entrar (todos os usuários, em todos os tipos de PC). Nada é bloqueado:
#    qualquer usuário pode tirar o mudo e aumentar o volume depois.
if ($true) {
$codigo = @"
using System;
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);
    int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice { int Activate(ref Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev); }
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator { int f(); int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint); }
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class LabAudio {
    static IAudioEndpointVolume Vol() {
        var en = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(en.GetDefaultAudioEndpoint(0, 1, out dev));
        IAudioEndpointVolume epv = null;
        var id = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref id, 23, 0, out epv));
        return epv;
    }
    public static void Zerar() {
        var v = Vol();
        Marshal.ThrowExceptionForHR(v.SetMasterVolumeLevelScalar(0f, Guid.Empty));
        Marshal.ThrowExceptionForHR(v.SetMute(true, Guid.Empty));
    }
}
"@
Add-Type -TypeDefinition $codigo
for ($t = 1; $t -le 5; $t++) {          # tenta por até ~25 s (o serviço de áudio pode demorar no logon)
    try { [LabAudio]::Zerar(); break } catch { Start-Sleep -Seconds 5 }
}
}
'@
    Set-Content -Path $logonScript -Value $conteudoLogon -Encoding UTF8

    $acaoLog = New-ScheduledTaskAction -Execute 'conhost.exe' `
               -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$logonScript`""
    $gatLog  = New-ScheduledTaskTrigger -AtLogOn
    $prinLog = New-ScheduledTaskPrincipal -GroupId $SID_Usuarios -RunLevel Limited   # qualquer usuário que fizer logon
    $confLog = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    try {
        Register-ScheduledTask -TaskName 'Logon do usuario' -TaskPath '\IFSP\' -Action $acaoLog -Trigger $gatLog `
                               -Principal $prinLog -Settings $confLog -Force | Out-Null
        Log 'Tarefa "\IFSP\Logon do usuario" criada.' 'Green'
    } catch {
        Log "AVISO: não consegui criar a tarefa de logon ($($_.Exception.Message))" 'Yellow'
    }

    # ---- Script do sistema (SYSTEM): log, políticas, impressão e limpeza ao desligar ----
    $sisScript = Join-Path $Base 'sistema.ps1'
    $conteudoSis = @'
# sistema.ps1 - Manutenção de Computadores IFSP - roda como SYSTEM.
#   -Modo Coleta   : a cada 5 min e a cada logon: log, política dos widgets e os bloqueios escolhidos na
#                    Manutenção > Bloqueios (Configurações, impressão, navegador, barra, papel de parede; nunca na CTI).
#   -Modo Desligar : (PCs compartilhados) limpa o perfil de uso ao desligar/reiniciar.
#   -Modo Logon    : a cada logon (PCs compartilhados: tira atalhos de programas da área de trabalho).
#   -Modo Horarios : a cada minuto (labs, salas, CIE): desligamento às 23h30 com aviso/adiar; com a CTI logada, não desliga.
param([string]$Modo = 'Coleta')
$ErrorActionPreference = 'SilentlyContinue'
$Base   = 'C:\ProgramData\IFSP'
$Logs   = Join-Path $Base 'logs'
$Estado = Join-Path $Logs 'ultima-coleta.txt'
$Pc     = $env:COMPUTERNAME
$cfg    = Get-Content (Join-Path $Base 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Escrever([datetime]$Quando, [string]$Tipo, [string]$Texto) {
    $arq = Join-Path $Logs ('{0:yyyy-MM}.log' -f $Quando)
    Add-Content -Path $arq -Encoding UTF8 -Value ('{0:yyyy-MM-dd HH:mm:ss} | {1} | {2,-18} | {3}' -f $Quando, $Pc, $Tipo, $Texto)
}
function NomeDoSid([string]$Sid) {
    try { (New-Object Security.Principal.SecurityIdentifier($Sid)).Translate([Security.Principal.NTAccount]).Value.Split('\')[-1] } catch { $Sid }
}
# Bloqueio valendo agora? (Manutenção > Bloqueios; campo que não existe = bloqueado)
function Bloqueado([string]$Nome) {
    $v = $cfg."Bloqueio$Nome"
    if ($null -ne $v -and -not [bool]$v) { return $false }
    $ate = [string]$cfg."Bloqueio${Nome}Ate"
    if ($ate -and ((Get-Date) -lt [datetime]$ate)) { return $false }
    return $true
}
# Contas locais começam com o SID da máquina; as do domínio (UCS/AD), não
$sidMaquina = ''
try { $sidMaquina = (Get-LocalUser | Where-Object { $_.SID.Value -match '-500$' } | Select-Object -First 1).SID.AccountDomainSid.Value } catch { }
function Eh-ContaLocal([string]$Sid) { return (-not $sidMaquina) -or $Sid.StartsWith("$sidMaquina-") }
function Dado($Evento, [string]$Nome) {
    (([xml]$Evento.ToXml()).Event.EventData.Data | Where-Object { $_.Name -eq $Nome }).'#text'
}
function Limpar-Htdocs {      # XAMPP: htdocs e bancos do MySQL voltam ao padrão (recém-instalado)
    $htdocs = 'C:\xampp\htdocs'
    $padrao = 'C:\ProgramData\IFSP\htdocs-padrao'
    if (-not (Test-Path -LiteralPath $htdocs)) { return $false }
    Get-ChildItem -LiteralPath $htdocs -Force | Remove-Item -Recurse -Force
    if (Test-Path -LiteralPath $padrao) { Copy-Item -Path (Join-Path $padrao '*') -Destination $htdocs -Recurse -Force }
    $dados    = 'C:\xampp\mysql\data'
    $bdPadrao = 'C:\ProgramData\IFSP\mysql-data-padrao'
    if ((Test-Path -LiteralPath $bdPadrao) -and (Test-Path -LiteralPath $dados)) {
        Get-Process -Name mysqld -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Get-ChildItem -LiteralPath $dados -Force | Remove-Item -Recurse -Force
        Copy-Item -Path (Join-Path $bdPadrao '*') -Destination $dados -Recurse -Force
    }
    return $true
}

# ---- Desligamento às 23:30 (tarefa \IFSP\Horarios, a cada minuto): labs, salas de aula e CIE
if ($Modo -eq 'Horarios') {
    $arqCfg    = Join-Path $Base 'config.json'
    $EstadoDir = Join-Path $Base 'estado'
    $arqSt     = Join-Path $EstadoDir 'horarios.json'
    $pedido    = Join-Path $EstadoDir 'adiar.txt'
    $agora     = Get-Date
    $h = $cfg.Horarios
    if (-not $h -or -not $h.Ativo) { exit }

    function Restaurar-Horarios([string]$Motivo) {
        $padrao = Get-Content (Join-Path $Base 'horarios-padrao.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $script:cfg.Horarios = $padrao
        $script:cfg | ConvertTo-Json | Set-Content -Path $arqCfg -Encoding UTF8
        Escrever (Get-Date) 'MANUTENCAO' "Horários voltaram ao normal ($Motivo)"
    }
    # teste com prazo vencido: volta ao normal
    if ($h.Teste -and $h.TesteAte -and ($agora -gt [datetime]$h.TesteAte)) { Restaurar-Horarios 'fim do tempo de teste'; $h = $cfg.Horarios }

    $st = $null
    if (Test-Path $arqSt) { try { $st = Get-Content $arqSt -Raw -Encoding UTF8 | ConvertFrom-Json } catch { } }
    if (-not $st) { $st = New-Object psobject }
    foreach ($campo in 'DesligarEm', 'Aviso', 'Pausado', 'Atualizado') {
        if (-not ($st.PSObject.Properties.Name -contains $campo)) { $st | Add-Member -NotePropertyName $campo -NotePropertyValue $null }
    }
    $st.Atualizado = $agora.ToString('yyyy-MM-dd HH:mm:ss')
    $salvar = { $st | ConvertTo-Json | Set-Content -Path $arqSt -Encoding UTF8 }
    $desligar = {
        param([string]$Motivo)
        $st.Aviso = $false; $st.DesligarEm = ''
        & $salvar
        Escrever (Get-Date) 'DESLIGAMENTO AUTO' $Motivo
        if ($h.Teste) { Restaurar-Horarios 'teste concluído' }
        & shutdown.exe /s /f /t 0 /c "Desligamento automático: $Motivo"
        exit
    }

    # pausado (ex.: atividade extra)
    if ($h.PausadoAte -and ($agora -lt [datetime]$h.PausadoAte)) {
        $st.Pausado = $true; $st.Aviso = $false; $st.DesligarEm = ''
        Remove-Item $pedido -Force -ErrorAction SilentlyContinue
        & $salvar; exit
    }
    $st.Pausado = $false

    # CTI logada (em qualquer sessão): o PC nunca desliga sozinho e ninguém recebe aviso
    $ctiLogada = $false
    foreach ($proc in @(Get-CimInstance Win32_Process -Filter "Name='explorer.exe'")) {
        $dono = Invoke-CimMethod -InputObject $proc -MethodName GetOwner
        if ($dono.User -eq 'CTI') { $ctiLogada = $true }
    }
    if (-not ($st.PSObject.Properties.Name -contains 'CTILogada')) { $st | Add-Member -NotePropertyName CTILogada -NotePropertyValue $false }
    $st.CTILogada = $ctiLogada
    if ($ctiLogada) {
        $st.Aviso = $false; $st.DesligarEm = ''
        Remove-Item $pedido -Force -ErrorAction SilentlyContinue
        & $salvar; exit
    }

    # pedido de adiamento (botão no aviso)
    if (Test-Path $pedido) {
        $quem = ([string](Get-Content $pedido -Raw)).Trim()
        Remove-Item $pedido -Force
        if ($st.DesligarEm) {
            $novo = ([datetime]$st.DesligarEm).AddMinutes([int]$h.AdiarMin)
            $st.DesligarEm = $novo.ToString('yyyy-MM-dd HH:mm:ss'); $st.Aviso = $false
            Escrever $agora 'ADIAMENTO' ('Desligamento adiado para {0:HH:mm} por {1}' -f $novo, $quem)
        }
    }

    # horário limite: janela da noite começa no aviso (ex.: 23:20) e vai até FimJanela (ex.: 06:00)
    $hDesl = [datetime]::ParseExact($h.Desligar,  'HH:mm', $null).TimeOfDay
    $hFim  = [datetime]::ParseExact($h.FimJanela, 'HH:mm', $null).TimeOfDay
    $hIni  = $hDesl - [timespan]::FromMinutes([int]$h.AvisoMin)
    if ($hIni.Ticks -lt 0) { $hIni = $hIni + [timespan]::FromDays(1) }
    $tDia  = $agora.TimeOfDay
    if ($hIni -le $hFim) { $naJanela = ($tDia -ge $hIni) -and ($tDia -lt $hFim) }
    else                 { $naJanela = ($tDia -ge $hIni) -or  ($tDia -lt $hFim) }
    if ($naJanela) {
        if (-not $st.DesligarEm) {
            $cand = $agora.Date + $hDesl
            if ($cand.AddMinutes(-[int]$h.AvisoMin) -gt $agora) { $cand = $cand.AddDays(-1) }   # depois da meia-noite
            $minimo = $agora.AddMinutes([int]$h.AvisoMin)                                          # sempre dá o aviso
            if ($cand -lt $minimo) { $cand = $minimo }
            $st.DesligarEm = $cand.ToString('yyyy-MM-dd HH:mm:ss')
        }
        $desl = [datetime]$st.DesligarEm
        $st.Aviso = ($agora -ge $desl.AddMinutes(-[int]$h.AvisoMin))
        if ($agora -ge $desl) { & $desligar ("horário limite ({0})" -f $h.Desligar) }
    } else {
        $st.DesligarEm = ''; $st.Aviso = $false
        Remove-Item $pedido -Force -ErrorAction SilentlyContinue
    }

    & $salvar
    exit
}

# ---- Política dos widgets (o Windows só deixa a conta SYSTEM gravar esta chave)
$dsh = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
if ((Get-ItemProperty -Path $dsh -ErrorAction SilentlyContinue).AllowNewsAndInterests -ne 0) {
    try {
        if (-not (Test-Path $dsh)) { New-Item -Path $dsh -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -Path $dsh -Name AllowNewsAndInterests -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
        Escrever (Get-Date) 'CONFIG' 'Widgets desativados por política'
    } catch {
        $marca = Join-Path $Logs 'aviso-widgets.txt'
        if (-not (Test-Path $marca)) {
            Escrever (Get-Date) 'AVISO' "Widgets: não consegui gravar a política ($($_.Exception.Message))"
            Set-Content -Path $marca -Value (Get-Date)
        }
    }
}

# ---- Bloqueio de impressão para a conta Alunos (impressoras reais; PDF/XPS continuam liberados).
#      Com o bloqueio "Impressao" desbloqueado, tira a negação que tiver sido posta antes.
if ($cfg.ContaAlunos) {
    $al = Get-LocalUser -Name $cfg.Usuario
    $impBloq = Bloqueado 'Impressao'
    if ($al) {
        $virtuais = @('PORTPROMPT:', 'XPSPORT:', 'NUL:', 'NUL')
        foreach ($imp in (Get-Printer | Where-Object { $_.Type -eq 'Local' })) {
            if ($virtuais -contains ([string]$imp.PortName).ToUpper()) { continue }
            $completa = Get-Printer -Name $imp.Name -Full
            if (-not $completa.PermissionSDDL) { continue }
            $sd = New-Object System.Security.AccessControl.RawSecurityDescriptor($completa.PermissionSDDL)
            $jaTem = $false
            for ($i = $sd.DiscretionaryAcl.Count - 1; $i -ge 0; $i--) {
                $ace = $sd.DiscretionaryAcl[$i]
                if ($ace.AceQualifier -eq [System.Security.AccessControl.AceQualifier]::AccessDenied -and
                    $ace.SecurityIdentifier -eq $al.SID -and ($ace.AccessMask -band 8)) {
                    $jaTem = $true
                    if (-not $impBloq) { $sd.DiscretionaryAcl.RemoveAce($i) }
                }
            }
            if ($jaTem -and -not $impBloq) {
                $secoes = [System.Security.AccessControl.AccessControlSections]'Owner, Group, Access'
                try {
                    Set-Printer -Name $imp.Name -PermissionSDDL ($sd.GetSddlForm($secoes)) -ErrorAction Stop
                    Escrever (Get-Date) 'IMPRESSAO' "Impressão desbloqueada para $($cfg.Usuario) em: $($imp.Name)"
                } catch {
                    Escrever (Get-Date) 'AVISO' "Não consegui desbloquear a impressora $($imp.Name) ($($_.Exception.Message))"
                }
            }
            if ($impBloq -and -not $jaTem) {
                # 8 = permissão "Imprimir" (PRINTER_ACCESS_USE); negar vale mais que permitir
                $nega = New-Object System.Security.AccessControl.CommonAce(
                            [System.Security.AccessControl.AceFlags]::None,
                            [System.Security.AccessControl.AceQualifier]::AccessDenied, 8, $al.SID, $false, $null)
                $sd.DiscretionaryAcl.InsertAce(0, $nega)
                $secoes = [System.Security.AccessControl.AccessControlSections]'Owner, Group, Access'
                try {
                    Set-Printer -Name $imp.Name -PermissionSDDL ($sd.GetSddlForm($secoes)) -ErrorAction Stop
                    Escrever (Get-Date) 'IMPRESSAO' "Impressão bloqueada para $($cfg.Usuario) em: $($imp.Name)"
                } catch {
                    Escrever (Get-Date) 'AVISO' "Não consegui bloquear a impressora $($imp.Name) ($($_.Exception.Message))"
                }
            }
        }
    }
}

# ---- Bloqueios da conta Alunos (no logon e a cada 5 min; a CTI fica livre). Só com a conta logada.
#      "Configuracoes": sem Painel de Controle/Configurações e sem Editor do Registro.
#      "Impressao": não adiciona nem remove impressoras.
if (($Modo -eq 'Logon' -or $Modo -eq 'Coleta') -and $cfg.ContaAlunos) {
    $hivesAl = @()
    $al = Get-LocalUser -Name $cfg.Usuario -ErrorAction SilentlyContinue
    if ($al -and (Test-Path "Registry::HKEY_USERS\$($al.SID.Value)")) { $hivesAl += "Registry::HKEY_USERS\$($al.SID.Value)" }
    # domínio: os usuários do domínio logados neste PC de alunos recebem os mesmos bloqueios
    foreach ($hk in (Get-ChildItem 'Registry::HKEY_USERS' | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' })) {
        if (-not (Eh-ContaLocal $hk.PSChildName)) { $hivesAl += "Registry::HKEY_USERS\$($hk.PSChildName)" }
    }
    foreach ($hiveAl in $hivesAl) {
        $kE = "$hiveAl\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        $kS = "$hiveAl\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        foreach ($k in $kE, $kS) { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } }
        if (Bloqueado 'Configuracoes') {
            Set-ItemProperty -Path $kE -Name NoControlPanel       -Value 1 -Type DWord
            Set-ItemProperty -Path $kS -Name DisableRegistryTools -Value 1 -Type DWord
        } else {
            Remove-ItemProperty -Path $kE -Name NoControlPanel       -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $kS -Name DisableRegistryTools -ErrorAction SilentlyContinue
        }
        if (Bloqueado 'Impressao') {
            Set-ItemProperty -Path $kE -Name NoAddPrinter    -Value 1 -Type DWord
            Set-ItemProperty -Path $kE -Name NoDeletePrinter -Value 1 -Type DWord
        } else {
            Remove-ItemProperty -Path $kE -Name NoAddPrinter, NoDeletePrinter -ErrorAction SilentlyContinue
        }
    }
}

# ---- Bloqueio "Barra": barra de tarefas fixa nos PCs compartilhados (política da máquina; vale no próximo logon)
if (($Modo -eq 'Logon' -or $Modo -eq 'Coleta') -and $cfg.Compartilhado) {
    $polExp = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    $xmlBarra = Join-Path $Base 'barra-tarefas.xml'
    if ((Bloqueado 'Barra') -and (Test-Path $xmlBarra)) {
        if (-not (Test-Path $polExp)) { New-Item -Path $polExp -Force | Out-Null }
        if ((Get-ItemProperty $polExp).LockedStartLayout -ne 1) {
            New-ItemProperty -Path $polExp -Name StartLayoutFile   -Value $xmlBarra -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $polExp -Name LockedStartLayout -Value 1         -PropertyType DWord        -Force | Out-Null
            Escrever (Get-Date) 'CONFIG' 'Barra de tarefas bloqueada (vale no próximo logon)'
        }
    } elseif ((Get-ItemProperty $polExp -ErrorAction SilentlyContinue).LockedStartLayout -eq 1) {
        Remove-ItemProperty -Path $polExp -Name StartLayoutFile, LockedStartLayout -ErrorAction SilentlyContinue
        Escrever (Get-Date) 'CONFIG' 'Barra de tarefas desbloqueada (vale no próximo logon)'
    }
}

# ---- PCs compartilhados: Área de Trabalho de todos só com Lixeira, Chrome e ONLYOFFICE (remove atalhos
#      que instaladores criarem). Só no logon (tarefa "Logon do sistema") e ao desligar/reiniciar.
#      Nos labs, o ícone do VS Code fica; no PC do professor do lab, também o do Veyon Master.
if ($cfg.Compartilhado -and ($Modo -eq 'Logon' -or $Modo -eq 'Desligar')) {
    Get-ChildItem 'C:\Users\Public\Desktop', 'C:\Users\Default\Desktop' -Filter '*.lnk' -Force |
        Where-Object { $_.Name -ne 'Google Chrome.lnk' -and $_.Name -notlike 'ONLYOFFICE*.lnk' -and
                       -not ($cfg.LabInfo -and $_.FullName -eq 'C:\Users\Public\Desktop\Visual Studio Code.lnk') -and
                       -not ($cfg.Tipo -eq 'LAB-PROF' -and $_.Name -eq 'Veyon Master.lnk') } |
        Remove-Item -Force
}

# ---- VLC: sem atalho na Área de Trabalho em nenhum PC (uma atualização do VLC pode recriar)
Get-ChildItem 'C:\Users\Public\Desktop' -Filter 'VLC*.lnk' -Force | Remove-Item -Force

# ---- Navegadores: nos PCs compartilhados, Chrome anônimo e Edge InPrivate em todas as contas, MENOS a CTI.
#      Política de usuário, no registro de cada conta logada; nos administrativos, nada fica restrito.
#      As linhas do Chrome/Edge seguem o bloqueio "Navegador"; esconder "Alterar uma senha" vale sempre.
#      (a mesma lista está em $RestricoesUsuario, no instalador)
if ($Modo -eq 'Logon' -or $Modo -eq 'Coleta') {
    $restricoes = @(
        'Software\Policies\Google\Chrome|IncognitoModeAvailability|2'
        'Software\Policies\Google\Chrome|BrowserSignin|0'
        'Software\Policies\Google\Chrome|SyncDisabled|1'
        'Software\Policies\Google\Chrome|BrowserGuestModeEnabled|0'
        'Software\Policies\Google\Chrome|BrowserAddPersonEnabled|0'
        'Software\Policies\Google\Chrome|PasswordManagerEnabled|0'
        'Software\Policies\Microsoft\Edge|InPrivateModeAvailability|2'
        'Software\Policies\Microsoft\Edge|BrowserSignin|0'
        'Software\Policies\Microsoft\Edge|SyncDisabled|1'
        'Software\Policies\Microsoft\Edge|BrowserGuestModeEnabled|0'
        'Software\Policies\Microsoft\Edge|BrowserAddProfileEnabled|0'
        'Software\Policies\Microsoft\Edge|PasswordManagerEnabled|0'
        'Software\Microsoft\Windows\CurrentVersion\Policies\System|DisableChangePassword|1'
    )
    foreach ($hk in (Get-ChildItem 'Registry::HKEY_USERS' | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' })) {
        $raiz = "Registry::HKEY_USERS\$($hk.PSChildName)"
        $restrito = [bool]$cfg.Compartilhado -and ((NomeDoSid $hk.PSChildName) -ne 'CTI')
        $local    = Eh-ContaLocal $hk.PSChildName      # usuários do domínio: navegador livre e podem trocar a senha
        $navBloq  = $restrito -and $local -and (Bloqueado 'Navegador')
        foreach ($linha in $restricoes) {
            $c = $linha.Split('|')
            $k = "$raiz\$($c[0])"
            $aplica = if ($c[0] -like 'Software\Policies\*') { $navBloq } else { $restrito -and $local }
            if ($aplica) {
                if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
                if ((Get-ItemProperty -Path $k).($c[1]) -ne [int]$c[2]) {
                    New-ItemProperty -Path $k -Name $c[1] -Value ([int]$c[2]) -PropertyType DWord -Force | Out-Null
                }
            } elseif (Test-Path $k) {
                Remove-ItemProperty -Path $k -Name $c[1] -ErrorAction SilentlyContinue
            }
        }
        # Bloqueio "Barra": não fixar nem desafixar na barra de tarefas (todas as contas dos PCs compartilhados, menos a CTI)
        $kPin = "$raiz\Software\Policies\Microsoft\Windows\Explorer"
        if ($restrito -and (Bloqueado 'Barra')) {
            if (-not (Test-Path $kPin)) { New-Item -Path $kPin -Force | Out-Null }
            if ((Get-ItemProperty -Path $kPin).NoPinningToTaskbar -ne 1) {
                New-ItemProperty -Path $kPin -Name NoPinningToTaskbar -Value 1 -PropertyType DWord -Force | Out-Null
            }
        } elseif (Test-Path $kPin) {
            Remove-ItemProperty -Path $kPin -Name NoPinningToTaskbar -ErrorAction SilentlyContinue
        }
        # v3.2 a v3.5 gravavam por engano chaves de 1 letra em Software\Policies (G, M, I...): apaga as vazias
        Get-ChildItem "$raiz\Software\Policies" -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName.Length -eq 1 -and $_.SubKeyCount -eq 0 -and $_.ValueCount -eq 0 } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

# ---- Papel de parede: a imagem MAIS NOVA da pasta "Papel de parede" vale para todos, bloqueada (bloqueio "Papel"),
#      MENOS a CTI (que troca o seu à vontade). Vale no próximo logon de cada usuário.
if ($Modo -eq 'Logon' -or $Modo -eq 'Coleta') {
    $pastaPapel = Join-Path $Base 'Papel de parede'
    $img = Get-ChildItem $pastaPapel -File | Where-Object { $_.Extension -in '.png', '.jpg', '.jpeg', '.bmp' } |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $kS = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
    $kA = 'Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop'
    $gravarPapel = {
        param([string]$Hive, [bool]$Bloquear)
        if ($Bloquear -and $cfg.PapelDeParede) {
            foreach ($k in "$Hive\$kS", "$Hive\$kA") { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } }
            if ((Get-ItemProperty "$Hive\$kS").Wallpaper -ne $cfg.PapelDeParede) {
                New-ItemProperty -Path "$Hive\$kS" -Name Wallpaper      -Value $cfg.PapelDeParede -PropertyType String -Force | Out-Null
                New-ItemProperty -Path "$Hive\$kS" -Name WallpaperStyle -Value '4'                -PropertyType String -Force | Out-Null
            }
            New-ItemProperty -Path "$Hive\$kA" -Name NoChangingWallPaper -Value 1 -PropertyType DWord -Force | Out-Null
        } else {
            Remove-ItemProperty -Path "$Hive\$kS" -Name Wallpaper, WallpaperStyle -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "$Hive\$kA" -Name NoChangingWallPaper -ErrorAction SilentlyContinue
        }
    }
    $bloquear = (Bloqueado 'Papel') -and ($cfg.Tipo -ne 'CTI')
    $mudou  = $false
    $definirCampo = {
        param([string]$Nome, $Valor)
        if ($cfg.PSObject.Properties.Name -contains $Nome) { $cfg.$Nome = $Valor }
        else { $cfg | Add-Member -NotePropertyName $Nome -NotePropertyValue $Valor }
    }
    if ($img) {
        $marca = '{0}|{1}' -f $img.Name, $img.LastWriteTimeUtc.Ticks
        if ($cfg.PapelOrigem -ne $marca) {
            # imagem nova na pasta: vira um arquivo com nome novo (o Windows só relê quando o caminho muda)
            $novo = Join-Path $Base ('papel-de-parede-{0:yyyyMMdd-HHmmss}{1}' -f (Get-Date), $img.Extension.ToLower())
            Copy-Item -LiteralPath $img.FullName -Destination $novo -Force
            Get-ChildItem $Base -Filter 'papel-de-parede*' -File | Where-Object { $_.FullName -ne $novo } | Remove-Item -Force
            & $definirCampo 'PapelDeParede' $novo
            & $definirCampo 'PapelOrigem' $marca
            $csp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'      # tela de bloqueio e de login
            if (-not (Test-Path $csp)) { New-Item -Path $csp -Force | Out-Null }
            New-ItemProperty -Path $csp -Name LockScreenImagePath   -Value $novo -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $csp -Name LockScreenImageUrl    -Value $novo -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $csp -Name LockScreenImageStatus -Value 1     -PropertyType DWord  -Force | Out-Null
            & $definirCampo 'PapelVersao' (Get-Date -Format 'yyyyMMddHHmmss')
            & $definirCampo 'PapelPersonalizado' $true
            Escrever (Get-Date) 'CONFIG' "Papel de parede trocado para $($img.Name) (vale no próximo logon; a CTI também recebe e pode trocar o seu)"
            $mudou = $true
            # CTI: recebe a imagem nova também, sem bloqueio (cópia própria, que a próxima troca não apaga)
            $cti = Get-LocalUser -Name 'CTI'
            if ($cti) {
                $copiaCti = Join-Path $Base ('papel-cti-{0:yyyyMMdd-HHmmss}{1}' -f (Get-Date), $img.Extension.ToLower())
                Copy-Item -LiteralPath $img.FullName -Destination $copiaCti -Force
                Get-ChildItem $Base -Filter 'papel-cti-*' -File | Where-Object { $_.FullName -ne $copiaCti } | Remove-Item -Force
                & $definirCampo 'PapelCTI' $copiaCti
                $gravarCti = {
                    param([string]$Hive)
                    $kd = "$Hive\Control Panel\Desktop"
                    New-ItemProperty -Path $kd -Name Wallpaper      -Value $copiaCti -PropertyType String -Force | Out-Null
                    New-ItemProperty -Path $kd -Name WallpaperStyle -Value '10'      -PropertyType String -Force | Out-Null
                    New-ItemProperty -Path $kd -Name TileWallpaper  -Value '0'       -PropertyType String -Force | Out-Null
                }
                $hc = "Registry::HKEY_USERS\$($cti.SID.Value)"
                if (Test-Path $hc) { & $gravarCti $hc }
                else {
                    $pc = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $cti.SID.Value }
                    if ($pc -and (Test-Path (Join-Path $pc.LocalPath 'NTUSER.DAT'))) {
                        & reg.exe load 'HKU\IFSPCti' (Join-Path $pc.LocalPath 'NTUSER.DAT') | Out-Null
                        if ($LASTEXITCODE -eq 0) {
                            try { & $gravarCti 'Registry::HKEY_USERS\IFSPCti' }
                            finally { [gc]::Collect(); [gc]::WaitForPendingFinalizers(); & reg.exe unload 'HKU\IFSPCti' | Out-Null }
                        }
                    }
                }
            }
        }
    }
    if ([string]$cfg.BloqueioPapelAplicado -ne [string]$bloquear) {
        & $definirCampo 'BloqueioPapelAplicado' $bloquear
        Escrever (Get-Date) 'CONFIG' $(if ($bloquear) { 'Papel de parede bloqueado (menos na CTI)' } else { 'Papel de parede desbloqueado' })
        $mudou = $true
    }
    if ($mudou) {
        $cfg | ConvertTo-Json | Set-Content -Path (Join-Path $Base 'config.json') -Encoding UTF8
        # perfil padrão e conta de uso sem logon agora: grava direto no registro deles
        $offline = @(@{ Nome = 'Default'; Dat = 'C:\Users\Default\NTUSER.DAT' })
        $uu = if ($cfg.Usuario -and $cfg.Usuario -ne 'CTI') { Get-LocalUser -Name $cfg.Usuario } else { $null }
        $pu = if ($uu) { Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $uu.SID.Value } } else { $null }
        if ($pu -and -not $pu.Loaded) { $offline += @{ Nome = $cfg.Usuario; Dat = (Join-Path $pu.LocalPath 'NTUSER.DAT') } }
        foreach ($o in $offline) {
            if (-not (Test-Path $o.Dat)) { continue }
            & reg.exe load 'HKU\IFSPPapel' $o.Dat | Out-Null
            if ($LASTEXITCODE -ne 0) { continue }
            try { & $gravarPapel 'Registry::HKEY_USERS\IFSPPapel' $bloquear }
            finally { [gc]::Collect(); [gc]::WaitForPendingFinalizers(); & reg.exe unload 'HKU\IFSPPapel' | Out-Null }
        }
    }
    # contas logadas agora: bloqueada em todas, menos na CTI
    foreach ($hk in (Get-ChildItem 'Registry::HKEY_USERS' | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' })) {
        $ehContaCTI = ((NomeDoSid $hk.PSChildName) -eq 'CTI')
        & $gravarPapel "Registry::HKEY_USERS\$($hk.PSChildName)" ($bloquear -and -not $ehContaCTI)
    }
}

# ---- Logon automático x senha (a CTI pode definir senha em qualquer conta de uso; nos administrativos, a pessoa também)
#      Se a conta passou a ter senha, desliga o logon automático (evita o erro de senha no boot);
#      se a senha foi tirada, religa. Com o logon automático desligado, confere no máximo 1 vez por hora.
if ($Modo -eq 'Coleta' -and $cfg.Usuario -and $cfg.Tipo -ne 'CTI') {
    $wl    = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $auto  = [string](Get-ItemProperty -Path $wl).AutoAdminLogon
    $marca = Join-Path $Logs 'ultima-checagem-senha.txt'
    $checar = ($auto -eq '1')
    if (-not $checar) {
        $ult = $null
        if (Test-Path $marca) { try { $ult = [datetime][long](Get-Content $marca -Raw).Trim() } catch { } }
        $checar = (-not $ult) -or (((Get-Date) - $ult).TotalMinutes -ge 60)
    }
    if ($checar -and (Get-LocalUser -Name $cfg.Usuario)) {
        Set-Content -Path $marca -Value (Get-Date).Ticks
        Add-Type -Namespace IFSP -Name Logon -MemberDefinition @"
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool LogonUser(string user, string domain, string pass, int type, int provider, out System.IntPtr token);
[DllImport("kernel32.dll")]
public static extern bool CloseHandle(System.IntPtr h);
"@
        $tok = [System.IntPtr]::Zero
        $ok  = [IFSP.Logon]::LogonUser($cfg.Usuario, '.', '', 2, 0, [ref]$tok)
        $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if ($ok) { [void][IFSP.Logon]::CloseHandle($tok) }
        $semSenha = $ok -or ($err -eq 1327)       # 1327 = senha em branco (restrição do Windows)
        $comSenha = (-not $ok) -and ($err -eq 1326)  # 1326 = senha incorreta, ou seja, a conta tem senha
        if ($comSenha -and $auto -eq '1') {
            Set-ItemProperty -Path $wl -Name AutoAdminLogon -Value '0'
            Escrever (Get-Date) 'CONFIG' "A conta $($cfg.Usuario) tem senha: logon automático desligado"
        } elseif ($semSenha -and $auto -ne '1') {
            Set-ItemProperty -Path $wl -Name AutoAdminLogon  -Value '1'
            Set-ItemProperty -Path $wl -Name DefaultUserName -Value $cfg.Usuario
            Set-ItemProperty -Path $wl -Name DefaultPassword -Value ''
            Escrever (Get-Date) 'CONFIG' "A conta $($cfg.Usuario) está sem senha: logon automático religado"
        }
    }
}

# ---- Limpeza do perfil de uso ao desligar/reiniciar (PCs compartilhados; script de desligamento da política local)
if ($Modo -eq 'Desligar' -and $cfg.Compartilhado) {
    $u = Get-LocalUser -Name $cfg.Usuario
    if ($u) {
        $perf = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $u.SID.Value }
        if ($perf -and -not $perf.Loaded) {
            $segura = if ($cfg.PastaSegura) { Join-Path $perf.LocalPath 'Desktop\Pasta Segura' } else { '' }
            foreach ($sub in 'Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos', 'Music', 'AppData\Local\Temp') {
                $p = Join-Path $perf.LocalPath $sub
                if (Test-Path -LiteralPath $p) {
                    Get-ChildItem -LiteralPath $p -Force |
                        Where-Object { $_.Name -ne 'desktop.ini' -and $_.FullName -ne $segura -and
                                       -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
                        Remove-Item -Recurse -Force
                }
            }
            $lixeira = 'C:\$Recycle.Bin\' + $u.SID.Value
            if (Test-Path -LiteralPath $lixeira) {
                Get-ChildItem -LiteralPath $lixeira -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force
            }
            Escrever (Get-Date) 'LIMPEZA' "Perfil $($cfg.Usuario) limpo ao desligar/reiniciar"
        }
    }
}

# ---- XAMPP: htdocs e bancos voltam ao original ao desligar/reiniciar (só PCs da conta Alunos com os programas do lab)
if ($Modo -eq 'Desligar' -and $cfg.ContaAlunos -and $cfg.LabInfo -and (Bloqueado 'Xampp')) {
    if (Limpar-Htdocs) { Escrever (Get-Date) 'LIMPEZA' 'htdocs e bancos do XAMPP restaurados ao desligar/reiniciar' }
}

if ($Modo -eq 'Logon') { exit }   # a coleta do log fica só com a tarefa "Coletor de log" (evita linhas repetidas)

# ---- Coleta: transforma eventos do Windows em linhas do log
$desde = (Get-Date).AddDays(-1)
if (Test-Path $Estado) { try { $desde = [datetime][long](Get-Content $Estado -Raw).Trim() } catch { } }

$eventos = @()
$eventos += Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Winlogon'; Id = 7001, 7002; StartTime = $desde }
$eventos += Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 6005, 1074; StartTime = $desde }
$eventos += Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Partition/Diagnostic'; Id = 1006; StartTime = $desde }
$eventos += Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'IFSP'; StartTime = $desde }
$eventos = @($eventos | Where-Object { $_ -and $_.TimeCreated -gt $desde } | Sort-Object TimeCreated)

foreach ($e in $eventos) {
    if ($e.ProviderName -eq 'IFSP') {
        $tipo = switch ($e.Id) { 1001 { 'REGRAS ACEITAS' } 1002 { 'REGRAS RECUSADAS' } 1003 { 'LIMPEZA' } 1005 { 'LOGOFF OCIOSO' } 1006 { 'MANUTENCAO' } default { 'AVISO' } }
        Escrever $e.TimeCreated $tipo $e.Message
        continue
    }
    switch ($e.Id) {
        7001 { Escrever $e.TimeCreated 'LOGON'  (NomeDoSid (Dado $e 'UserSid')) }
        7002 { Escrever $e.TimeCreated 'LOGOFF' (NomeDoSid (Dado $e 'UserSid')) }
        6005 { Escrever $e.TimeCreated 'PC LIGADO' '' }
        1074 { Escrever $e.TimeCreated 'DESLIGAR/REINICIAR' ((($e.Message -split "`r?`n") | Where-Object { $_.Trim() })[0]) }
        1006 {
            if ((Dado $e 'BusType') -eq '7') {              # 7 = USB
                $nome  = ('{0} {1}' -f (Dado $e 'Manufacturer'), (Dado $e 'Model')).Trim()
                $serie = Dado $e 'SerialNumber'
                $cap   = 0; [double]::TryParse([string](Dado $e 'Capacity'), [ref]$cap) | Out-Null
                if ($cap -gt 0) { Escrever $e.TimeCreated 'PENDRIVE CONECTADO' ('{0} | {1:N1} GB | série {2}' -f $nome, ($cap / 1GB), $serie) }
                else            { Escrever $e.TimeCreated 'PENDRIVE REMOVIDO'  ('{0} | série {1}' -f $nome, $serie) }
            }
        }
    }
}
if ($eventos.Count -gt 0) { Set-Content -Path $Estado -Value $eventos[-1].TimeCreated.Ticks }
'@
    Set-Content -Path $sisScript -Value $conteudoSis -Encoding UTF8

    $prinSys = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -LogonType ServiceAccount -RunLevel Highest
    $confSys = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
               -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    try {
        $acaoCol = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$sisScript`" -Modo Coleta"
        $gatCol  = @(
            (New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 5)),
            (New-ScheduledTaskTrigger -AtLogOn)
        )
        Register-ScheduledTask -TaskName 'Coletor de log' -TaskPath '\IFSP\' -Action $acaoCol `
            -Trigger $gatCol -Principal $prinSys -Settings $confSys -Force | Out-Null
        Log 'Tarefa "\IFSP\Coletor de log" criada (a cada 5 min e a cada logon).' 'Green'
    } catch {
        Log "AVISO: não consegui criar a tarefa do sistema ($($_.Exception.Message))" 'Yellow'
    }
    Start-ScheduledTask -TaskName 'Coletor de log' -TaskPath '\IFSP\' -ErrorAction SilentlyContinue
    if ($ehComp) {
        try {
            $acaoLs = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$sisScript`" -Modo Logon"
            Register-ScheduledTask -TaskName 'Logon do sistema' -TaskPath '\IFSP\' -Action $acaoLs `
                -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Principal $prinSys -Settings $confSys -Force | Out-Null
            $ficamTxt = if ($Cfg.LabInfo) { 'Lixeira, Chrome, ONLYOFFICE e VS Code' } else { 'Lixeira, Chrome e ONLYOFFICE' }
            Log "Tarefa ""\IFSP\Logon do sistema"" criada (a cada logon: Área de Trabalho só com $ficamTxt)." 'Green'
        } catch {
            Log "AVISO: não consegui criar a tarefa de logon do sistema ($($_.Exception.Message))" 'Yellow'
        }
    } else {
        Unregister-ScheduledTask -TaskName 'Logon do sistema' -TaskPath '\IFSP\' -Confirm:$false -ErrorAction SilentlyContinue
    }
    # ---- Horários (labs, salas, CIE): pasta de estado (usuários gravam o pedido de adiar),
    #      valores normais, agente na sessão do usuário e tarefa do SYSTEM a cada minuto
    $estadoDir = Join-Path $Base 'estado'
    New-Item -ItemType Directory -Path $estadoDir -Force | Out-Null
    & icacls.exe $estadoDir /grant '*S-1-5-32-545:(OI)(CI)M' | Out-Null
    $padraoArq = [pscustomobject]$HorariosPadrao
    $padraoArq.Ativo = $temHorario
    $padraoArq | ConvertTo-Json | Set-Content -Path (Join-Path $Base 'horarios-padrao.json') -Encoding UTF8
    $agenteScript = Join-Path $Base 'agente-usuario.ps1'
    $conteudoAgente = @'
# agente-usuario.ps1 - Manutenção de Computadores IFSP (labs, salas de aula e CIE)
# Roda escondido na sessão de cada usuário (menos a CTI) e mostra o aviso do desligamento das 23:30,
# com o botão "Adiar". (v3.3: sem logoff nem desligamento por falta de uso)
$ErrorActionPreference = 'SilentlyContinue'
$Base    = 'C:\ProgramData\IFSP'
$Estado  = Join-Path $Base 'estado'
$usuario = $env:USERNAME
$ehCTI   = ($usuario -eq 'CTI')
$mutex = New-Object System.Threading.Mutex($false, 'Local\IFSP-Agente')
if (-not $mutex.WaitOne(0)) { exit }       # já está rodando nesta sessão

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

function Registrar([int]$Id, [string]$Msg) {
    try { Write-EventLog -LogName Application -Source 'IFSP' -EventId $Id -EntryType Information -Message $Msg } catch { }
}
function Ler-Json([string]$Arq) {
    try { return (Get-Content $Arq -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}
function Novo-Aviso([string]$Titulo, [string]$TextoBtnOk, [string]$TextoBtnAdiar) {
    $fonte = 'Segoe UI'
    $f = New-Object System.Windows.Forms.Form
    $f.Text = 'IFSP'; $f.FormBorderStyle = 'FixedDialog'; $f.ControlBox = $false
    $f.TopMost = $true; $f.ShowInTaskbar = $true; $f.StartPosition = 'CenterScreen'
    $f.ClientSize = New-Object System.Drawing.Size(560, 200)
    $f.BackColor = [System.Drawing.Color]::FromArgb(43, 45, 49)
    $l1 = New-Object System.Windows.Forms.Label
    $l1.Text = $Titulo; $l1.ForeColor = [System.Drawing.Color]::White
    $l1.Font = New-Object System.Drawing.Font($fonte, 14, [System.Drawing.FontStyle]::Bold)
    $l1.Location = New-Object System.Drawing.Point(20, 18); $l1.Size = New-Object System.Drawing.Size(520, 30)
    $l2 = New-Object System.Windows.Forms.Label
    $l2.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 80)
    $l2.Font = New-Object System.Drawing.Font($fonte, 20, [System.Drawing.FontStyle]::Bold)
    $l2.Location = New-Object System.Drawing.Point(20, 55); $l2.Size = New-Object System.Drawing.Size(520, 42)
    $l3 = New-Object System.Windows.Forms.Label
    $l3.Text = 'Salve seus trabalhos (na nuvem ou no pendrive).'
    $l3.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $l3.Font = New-Object System.Drawing.Font($fonte, 11)
    $l3.Location = New-Object System.Drawing.Point(20, 100); $l3.Size = New-Object System.Drawing.Size(520, 25)
    $bOk = New-Object System.Windows.Forms.Button
    $bOk.Text = $TextoBtnOk; $bOk.Font = New-Object System.Drawing.Font($fonte, 11)
    $bOk.Size = New-Object System.Drawing.Size(170, 40); $bOk.Location = New-Object System.Drawing.Point(370, 140)
    $bOk.BackColor = [System.Drawing.Color]::FromArgb(90, 92, 98); $bOk.ForeColor = [System.Drawing.Color]::White; $bOk.FlatStyle = 'Flat'
    $f.Controls.AddRange(@($l1, $l2, $l3, $bOk))
    $bAd = $null
    if ($TextoBtnAdiar) {
        $bAd = New-Object System.Windows.Forms.Button
        $bAd.Text = $TextoBtnAdiar; $bAd.Font = New-Object System.Drawing.Font($fonte, 11, [System.Drawing.FontStyle]::Bold)
        $bAd.Size = New-Object System.Drawing.Size(170, 40); $bAd.Location = New-Object System.Drawing.Point(185, 140)
        $bAd.BackColor = [System.Drawing.Color]::FromArgb(50, 160, 65); $bAd.ForeColor = [System.Drawing.Color]::White; $bAd.FlatStyle = 'Flat'
        $f.Controls.Add($bAd)
    }
    return @{ Form = $f; Contador = $l2; BtnOk = $bOk; BtnAdiar = $bAd }
}

$script:cfg = $null; $script:st = $null
$script:avisoDesl = $null
$script:dispensado = ''; $script:pediuAdiar = ''; $script:n = 0

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $script:n++
    $agora  = Get-Date
    if ($script:n % 5 -eq 1) {             # a cada 5 s: configuração e estado dos horários
        $script:cfg = Ler-Json (Join-Path $Base 'config.json')
        $script:st  = Ler-Json (Join-Path $Estado 'horarios.json')
    }
    $h = $null
    if ($script:cfg) { $h = $script:cfg.Horarios }
    if (-not $h -or -not $h.Ativo) { return }
    $pausado = ($h.PausadoAte -and ($agora -lt [datetime]$h.PausadoAte))

    # --- aviso do desligamento no horário limite
    $st = $script:st
    if ($st -and $st.Aviso -and $st.DesligarEm -and $st.DesligarEm -ne $script:pediuAdiar) {
        $desl  = [datetime]$st.DesligarEm
        $falta = $desl - $agora
        if ($falta.Ticks -lt 0) { $falta = [timespan]::Zero }
        $mostrar = ($script:dispensado -ne $st.DesligarEm) -or ($falta.TotalSeconds -le 120)
        if ($mostrar -and -not $script:avisoDesl) {
            $txtAdiar = if ([int]$h.AdiarMin -eq 60) { 'Adiar 1 hora' } else { "Adiar $($h.AdiarMin) min" }
            $a = Novo-Aviso ('Este computador será desligado às {0:HH:mm}' -f $desl) 'OK' $txtAdiar
            $a.BtnAdiar.Add_Click({
                Set-Content -Path (Join-Path $Estado 'adiar.txt') -Value $usuario
                $script:pediuAdiar = $script:st.DesligarEm
                if ($script:avisoDesl) { $script:avisoDesl.Form.Close(); $script:avisoDesl = $null }
            })
            $a.BtnOk.Add_Click({
                $script:dispensado = $script:st.DesligarEm
                if ($script:avisoDesl) { $script:avisoDesl.Form.Close(); $script:avisoDesl = $null }
            })
            $script:avisoDesl = $a
            $a.Form.Show()
        }
        if ($script:avisoDesl) { $script:avisoDesl.Contador.Text = 'Faltam {0:mm\:ss}' -f $falta }
    } elseif ($script:avisoDesl) {
        $script:avisoDesl.Form.Close(); $script:avisoDesl = $null
    }
})
$timer.Start()
[System.Windows.Forms.Application]::Run()
'@
    Set-Content -Path $agenteScript -Value $conteudoAgente -Encoding UTF8
    if ($temHorario) {
        try {
            $acaoHor = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$sisScript`" -Modo Horarios"
            $gatHor  = @(
                (New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 1)),
                (New-ScheduledTaskTrigger -AtStartup)
            )
            $confHor = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
                       -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
            Register-ScheduledTask -TaskName 'Horarios' -TaskPath '\IFSP\' -Action $acaoHor -Trigger $gatHor `
                -Principal $prinSys -Settings $confHor -Force | Out-Null
            Log ("Desligamento automático às {0} (aviso {1} min, botão Adiar {2} min); com a CTI logada não desliga." -f `
                 $HorariosPadrao.Desligar, $HorariosPadrao.AvisoMin, $HorariosPadrao.AdiarMin) 'Green'
        } catch {
            Log "AVISO: não consegui criar a tarefa de horários ($($_.Exception.Message))" 'Yellow'
        }
    } else {
        Unregister-ScheduledTask -TaskName 'Horarios' -TaskPath '\IFSP\' -Confirm:$false -ErrorAction SilentlyContinue
        Log 'Este PC não desliga sozinho (tipo de PC ou espaço sem desligamento automático).'
    }
    Log "Log do computador em $PastaLogs (um arquivo por mês)."
    Log 'Volume 0 e mudo a cada logon, em todos os usuários (cada um pode aumentar depois).'
    if ($ehComp) { Log "Senha da conta $($Cfg.Usuario): só a CTI define (Manutenção > Senha). Com senha, o PC pede a senha ao ligar." }
    else         { Log "Se a conta $($Cfg.Usuario) ganhar senha, o logon automático é desligado sozinho (e religado se a senha for tirada)." }

    # ---- Política local: limpeza no LOGOFF e ao DESLIGAR (PCs compartilhados) ----
    try {
        $gpDir = Join-Path $env:SystemRoot 'System32\GroupPolicy'
        foreach ($d in 'Machine\Scripts\Startup', 'Machine\Scripts\Shutdown', 'User\Scripts\Logon', 'User\Scripts\Logoff') {
            New-Item -ItemType Directory -Path (Join-Path $gpDir $d) -Force | Out-Null
        }
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        if ($ehComp) {
            Set-Content -Path (Join-Path $gpDir 'Machine\Scripts\scripts.ini') -Encoding Unicode -Value @(
                '[Shutdown]'
                "0CmdLine=$psExe"
                "0Parameters=-NoProfile -ExecutionPolicy Bypass -File `"$sisScript`" -Modo Desligar"
            )
            Set-Content -Path (Join-Path $gpDir 'User\Scripts\scripts.ini') -Encoding Unicode -Value @(
                '[Logoff]'
                "0CmdLine=$psExe"
                "0Parameters=-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$logonScript`" -Modo Logoff"
            )
        } else {
            Set-Content -Path (Join-Path $gpDir 'Machine\Scripts\scripts.ini') -Encoding Unicode -Value @('[Shutdown]')
            Set-Content -Path (Join-Path $gpDir 'User\Scripts\scripts.ini')    -Encoding Unicode -Value @('[Logoff]')
        }
        # gpt.ini: informa que a política local tem scripts (computador e usuário) e aumenta as versões
        $gpt = Join-Path $gpDir 'gpt.ini'
        $ver = 0; $extMaq = ''; $extUsu = ''
        if (Test-Path $gpt) {
            $c = Get-Content $gpt
            $m = $c | Select-String '^Version=(\d+)';                 if ($m) { $ver    = [int]$m.Matches[0].Groups[1].Value }
            $m = $c | Select-String '^gPCMachineExtensionNames=(.*)'; if ($m) { $extMaq = $m.Matches[0].Groups[1].Value.Trim() }
            $m = $c | Select-String '^gPCUserExtensionNames=(.*)';    if ($m) { $extUsu = $m.Matches[0].Groups[1].Value.Trim() }
        }
        $cseScripts = '[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]'
        if ($extMaq -notmatch '42B5FAAE-6536-11D2-AE5A-0000F87571E3') { $extMaq += $cseScripts }
        if ($extUsu -notmatch '42B5FAAE-6536-11D2-AE5A-0000F87571E3') { $extUsu += $cseScripts }
        $verMaq = ($ver -band 0xFFFF) + 1
        $verUsu = (($ver -shr 16) -band 0xFFFF) + 1
        Set-Content -Path $gpt -Encoding ASCII -Value @(
            '[General]'
            'gPCFunctionalityVersion=2'
            "gPCMachineExtensionNames=$extMaq"
            "gPCUserExtensionNames=$extUsu"
            "Version=$(($verUsu -shl 16) + $verMaq)"
        )
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'SyncForegroundPolicy' -ErrorAction SilentlyContinue
        'N' | & gpupdate.exe /force | Out-Null      # 'N' = não fazer logoff/reiniciar se ele perguntar
        if ($ehComp) {
            $okDesl = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Shutdown\0\0'
            if ($okDesl) { Log 'Limpeza no logoff e ao desligar: scripts da política local configurados.' 'Green' }
            else         { Log 'AVISO: o script de desligamento não apareceu na política local (confira após reiniciar).' 'Yellow' }
        } else {
            Log 'Sem limpeza de pastas neste tipo de PC.'
        }
    } catch {
        Log "AVISO: não consegui configurar os scripts da política local ($($_.Exception.Message))" 'Yellow'
    }

    # Religa o Assistente de Compatibilidade de Programas (desligado só durante as instalações)
    if ($pcaMexido) {
        if ($null -eq $pcaAntes) { Apagar-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' @('DisablePCA') }
        else { Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' 'DisablePCA' $pcaAntes }
    }
    if ($auMexido) {
        if ($null -eq $auAntes) { Apagar-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' @('NoAutoRebootWithLoggedOnUsers') }
        else { Definir-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoRebootWithLoggedOnUsers' $auAntes }
    }

    # Aplica já nesta sessão (tema, papel de parede etc.)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $logonScript

    Apagar-InstaladoresDaCopia

    # GLPI: agente instalado agora ou com o servidor trocado: manda o inventário já (se houver rede)
    if ($GlpiMudou) { Enviar-InventarioGlpi }

    # Domínio (UCS/AD): informado nas perguntas e o PC ainda fora dele: oferece entrar agora
    if ($Cfg.Dominio -and -not (Esta-NoDominio) -and -not $Cfg.NoDominio) {
        Titulo "Domínio ($($Cfg.Dominio))"
        if (Perguntar-SN "Colocar este PC no domínio $($Cfg.Dominio) agora? (precisa de rede e de um usuário do domínio)") {
            [void](Ingressar-Dominio)
        } else {
            Log "Domínio: o PC não entrou agora. Para entrar depois: Manutenção > Domínio." 'Yellow'
        }
    }

    # ---------------- Fim ----------------
    $Cfg.Etapa = 'concluido'
    $Cfg.Data  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
    Salvar-Config
    Write-Host ''
    Write-Host ('  ' + ([string]([char]0x2550) * 62)) -ForegroundColor Green
    Log "Instalação concluída: $($Cfg.NomePC) ($($Cfg.Tipo))." 'Green'
    Write-Host ('  ' + ([string]([char]0x2550) * 62)) -ForegroundColor Green
    Write-Host "   Log desta instalação: $LogArquivo"
    Write-Host ''
    if ($PrecisaReiniciar) { Write-Host '   É preciso reiniciar para aplicar o novo nome e os programas.' -ForegroundColor Yellow }
    $txtReinicio = if ($Cfg.Tipo -eq 'CTI' -or $Cfg.NoDominio -or (Esta-NoDominio)) { 'Reiniciar agora?' } else { "Reiniciar agora? (vai entrar sozinho na conta $($Cfg.Usuario))" }
    if (Perguntar-SN $txtReinicio) { Restart-Computer -Force }
}
catch {
    Log "ERRO: $($_.Exception.Message)" 'Red'
    Log "Linha: $($_.InvocationInfo.ScriptLineNumber)" 'Red'
    exit 1
}
