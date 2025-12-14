# ==============================================================================
# NOME: POS System Auto-Healer & Network Monitor
# AUTOR: [Seu Nome]
# DESCRIÇÃO: 
#   Automação para ambientes de Varejo/Food Service.
#   1. Monitora processos críticos (Java/PDV) e realiza reinício automático (Self-Healing).
#   2. Valida conectividade com periféricos críticos (Impressoras Térmicas/SAT).
#   3. Executa teste de velocidade de link (Speedtest CLI) e gera logs estruturados.
#
# REQUISITOS:
#   - Windows PowerShell 5.1 ou superior.
#   - Execução com privilégios de usuário logado (para interação com GUI).
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"
$Report = @()
$AppError = $false

# --- CONFIGURAÇÕES (PERSONALIZÁVEIS) ---
# Caminho do executável do sistema de vendas (PDV)
$AppLauncherPath = "C:\Program Files (x86)\SistemaPDV\Launcher.exe" 
$ProcessNameString = "javaw" # Nome do processo real (ex: javaw, pdv_main)

# Lista de Dispositivos Críticos (Nome = IP)
$NetworkDevices = @{
    "Impressora Fiscal (SAT)" = "192.168.1.10"
    "Impressora Cozinha"      = "192.168.1.11"
    "Impressora Bar"          = "192.168.1.12"
    "Terminal Pedidos"        = "192.168.1.20"
}

# --- ETAPA 1: SELF-HEALING (VERIFICAÇÃO E REINÍCIO DO APP) ---
$Report += "=== 1. STATUS DA APLICAÇÃO (SELF-HEALING) ==="

# Verifica se há processos travados ou "zumbis"
$TargetProcesses = Get-Process | Where-Object { $_.ProcessName -eq $ProcessNameString }

if ($TargetProcesses) {
    $Report += "[ACAO] Processo detectado. Executando finalização forçada para reinício limpo..."
    $TargetProcesses | Stop-Process -Force
    Start-Sleep -Seconds 5
} else {
    $Report += "[INFO] Nenhum processo travado encontrado. Iniciando aplicação..."
}

# Tenta iniciar a aplicação
if (Test-Path $AppLauncherPath) {
    try {
        Write-Host "Iniciando Sistema PDV..."
        # Inicia o processo no diretório de trabalho correto para evitar erros de dependência
        Start-Process -FilePath $AppLauncherPath -WindowStyle Normal -WorkingDirectory (Split-Path $AppLauncherPath)
        
        Start-Sleep -Seconds 15 # Tempo de espera para carga da aplicação (ajustar conforme hardware)
        
        # Validação pós-execução
        if (Get-Process -Name $ProcessNameString -ErrorAction SilentlyContinue) {
            $Report += "[SUCESSO] Aplicação iniciada e processo ativo ($ProcessNameString)."
        } else {
            $Report += "[ALERTA] O comando de início foi enviado, mas o processo não foi detectado."
            $AppError = $true
        }
    } catch {
        $Report += "[ERRO CRÍTICO] Falha ao executar o launcher: $_"
        $AppError = $true
    }
} else {
    $Report += "[ERRO] Executável não encontrado no caminho: $AppLauncherPath"
    $AppError = $true
}

# --- ETAPA 2: MONITORAMENTO DE INFRAESTRUTURA (PING) ---
$Report += "`n=== 2. DISPONIBILIDADE DE PERIFÉRICOS ==="
$PingErrors = $false

foreach ($DeviceName in ($NetworkDevices.Keys | Sort-Object)) {
    $IP = $NetworkDevices[$DeviceName]
    # Ping rápido (Count 1) para validação de disponibilidade
    if (Test-Connection -ComputerName $IP -Count 1 -Quiet) {
        $Report += "[ONLINE] $DeviceName ($IP)"
    } else {
        $Report += "[OFFLINE] $DeviceName ($IP) - SEM RESPOSTA"
        $PingErrors = $true
    }
}

# --- ETAPA 3: TELEMETRIA DE REDE (SPEEDTEST CLI) ---
$Report += "`n=== 3. QUALIDADE DO LINK DE INTERNET ==="
Write-Host "Executando teste de largura de banda..."

$TempDir = "C:\Temp\NetworkTest_Tool"
if (!(Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory | Out-Null }
$ExePath = "$TempDir\speedtest.exe"

try {
    # Download automático da ferramenta oficial (Ookla) se não existir
    if (!(Test-Path $ExePath)) {
        $ZipPath = "$TempDir\speedtest.zip"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip" -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force
    }

    if (Test-Path $ExePath) {
        # Executa teste e formata saída JSON
        $TestResult = & $ExePath --accept-license --accept-gdpr --format=json | ConvertFrom-Json
        
        $Download = "{0:N0}" -f ($TestResult.download.bandwidth / 125000)
        $Upload   = "{0:N0}" -f ($TestResult.upload.bandwidth / 125000)
        $Latency  = $TestResult.ping.latency
        
        $Report += "ISP: $($TestResult.isp) | Down: $Download Mbps | Up: $Upload Mbps | Latência: $Latency ms"
    }
} catch {
    $Report += "[AVISO] Não foi possível executar o teste de velocidade. Verifique conexão externa."
}

# Limpeza de arquivos temporários
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# --- RELATÓRIO FINAL E LOGGING ---
Write-Host "`n--------------------------------------------------"
Write-Host "    RELATÓRIO DE AUTOMAÇÃO - HEALTH CHECK"
Write-Host "--------------------------------------------------"
$Report | ForEach-Object { Write-Host $_ }
Write-Host "--------------------------------------------------"

# Lógica de Saída para Ferramentas RMM (Datto, N-able, ConnectWise)
# Exit 1 gera alerta de falha no painel de monitoramento.
if ($PingErrors -or $AppError) { 
    Write-Host "`n[STATUS] FALHA DETECTADA: Verifique dispositivos offline ou erro na aplicação."
    Exit 1 
} else { 
    Write-Host "`n[STATUS] OPERACIONAL: Todos os sistemas validados."
    Exit 0 
}
