# POS System Auto-Healer & Network Monitor 🩺

> Automação em PowerShell para monitoramento proativo, self-healing de aplicações e telemetria de rede em ambientes de Varejo (PDV).

## 🎯 O Problema
Em operações de varejo e food service, a alta disponibilidade do PDV é crítica. Falhas no software de vendas (travamentos do Java) ou periféricos offline (impressoras fiscais/térmicas) geram paradas de operação e demandam intervenção manual constante do suporte (Toil), especialmente em plantões de fim de semana.

## 🚀 A Solução
Este script foi desenvolvido para rodar via **RMM (Remote Monitoring and Management)**. Ele transforma o suporte reativo em monitoramento proativo com capacidade de autocorreção.

### Principais Funcionalidades:

* **🔄 Self-Healing de Aplicação:** Monitora processos críticos (ex: `javaw.exe`). Se identificar processos travados ou "zumbis", realiza o encerramento forçado e reinicia a aplicação limpa automaticamente.
* **🖨️ Monitoramento de Periféricos:** Valida a conectividade (Ping/ICMP) de dispositivos críticos como SAT Fiscal e Impressoras de Produção.
* **📊 Telemetria de Rede:** Executa testes de largura de banda (Download/Upload/Latência) utilizando a CLI oficial do Speedtest, garantindo que o link esteja apto para transações TEF e Delivery.
* **🔔 Alertas Inteligentes:** Integração com o painel do RMM. O script retorna `Exit Code 1` apenas se houver falhas críticas, gerando tickets automáticos para a equipe.

## 🛠️ Tecnologias Utilizadas

* **Linguagem:** PowerShell 5.1+
* **Ferramentas:** Datto RMM (compatível com N-able, ConnectWise), Speedtest CLI (Ookla).
* **Conceitos:** Automation, Observability, Error Handling.

## 📋 Como Usar

1.  Clone este repositório.
2.  Edite as variáveis no início do script `AutoHealer-POS-Monitor.ps1` para refletir o seu ambiente:
    * `$AppLauncherPath`: Caminho do executável do seu PDV.
    * `$NetworkDevices`: Lista de IPs e Nomes dos dispositivos da loja.
3.  Configure seu RMM para executar o script como **"Logged on User"** (necessário para interagir com a interface gráfica do PDV).
4.  Agende a execução conforme a necessidade (ex: Diariamente antes da abertura da loja).

---
*Desenvolvido por [Gustavo Silva](https://www.linkedin.com/in/gustavosfs/)*
