# quantic-bird
Quantic Bird é uma stack Proxy TCP simples para acessar serviços atrás de CGNAT através de redes privadas, sem exigir VPN nos dispositivos dos usuários.


# 🐦 Quantic Bird

> A simple TCP proxy stack for exposing services behind CGNAT through a machine connected to a private overlay network.

## 📖 Sobre o projeto

O **Quantic Bird** nasceu para resolver um problema bastante específico de infraestrutura.

A ideia surgiu a partir de um cenário onde duas empresas estão geograficamente separadas e possuem serviços importantes rodando em servidores próprios. Uma dessas empresas utiliza **Starlink**, ficando atrás de **CGNAT**, o que impede o tradicional redirecionamento de portas no roteador.

Inicialmente, a solução foi utilizar o **NetBird** para criar uma rede privada entre os servidores. Isso resolveu o problema de conectividade entre as redes.

Porém, surgiu uma segunda necessidade:

> **Como acessar os serviços do servidor remoto sem precisar instalar o NetBird em cada computador que precisa utilizar esses serviços?**

Foi a partir desse problema que surgiu o Quantic Bird.

---

## 💡 A ideia

O Quantic Bird utiliza uma máquina que possui acesso à rede privada criada pelo NetBird como um **ponto de acesso/proxy TCP**.

Em vez de fazer com que cada cliente precise participar da rede do NetBird, o cliente acessa o servidor de acesso normalmente, e esse servidor encaminha a conexão através da rede privada até o serviço de destino.

A comunicação fica, conceitualmente, assim:

```text
                 INTERNET
                     │
                     │
              ┌──────▼──────┐
              │    CLIENTE   │
              │              │
              │ Sem NetBird  │
              └──────┬───────┘
                     │
                     │ TCP
                     ▼
          ┌─────────────────────┐
          │   SERVIDOR DE       │
          │      ACESSO         │
          │                     │
          │  NetBird / VPN      │
          │        +            │
          │       socat         │
          └──────────┬──────────┘
                     │
                     │ Rede privada
                     │ NetBird
                     ▼
             ┌───────────────┐
             │    SERVIDOR   │
             │    REMOTO     │
             │               │
             │  CGNAT/       │
             │  Starlink     │
             └───────┬───────┘
                     │
                     ▼
                ┌─────────┐
                │ Serviço │
                │   TCP   │
                └─────────┘
```

O servidor remoto não precisa possuir IP público nem permitir redirecionamento de portas.

O servidor de acesso funciona como uma espécie de **ponte TCP** entre o cliente e o serviço remoto.

---

## 🧩 Como funciona

O Quantic Bird é baseado em uma stack Docker bastante simples.

O container utiliza comandos do [`socat`](https://github.com/3proxy/socat) para criar listeners TCP e encaminhar as conexões para os respectivos serviços através da rede privada.

Por exemplo:

```text
Cliente
   │
   │ TCP :3307
   ▼
Servidor de acesso
   │
   │ socat
   │
   ▼
NetBird
   │
   │ TCP :3306
   ▼
Servidor remoto
   │
   ▼
MySQL
```

Dessa forma, um cliente pode utilizar:

```text
servidor-de-acesso:3307
```

para chegar ao:

```text
servidor-remoto:3306
```

sem precisar estar diretamente conectado ao NetBird.

---

# 🎯 Motivação

O problema que originou o projeto foi basicamente:

* duas empresas em locais diferentes;
* servidores em redes diferentes;
* uma das redes atrás de CGNAT;
* Starlink como conexão de Internet;
* impossibilidade de realizar port forwarding tradicional;
* necessidade de acessar serviços internos remotamente;
* usuários finais que não deveriam precisar instalar uma VPN.

Soluções tradicionais poderiam resolver o problema, mas adicionariam outros requisitos.

O objetivo do Quantic Bird foi manter a solução:

> **simples, barata e independente do acesso direto à rede do cliente.**

---

# 🐦 Por que "Quantic Bird"?

O nome não possui nenhuma relação técnica específica com o funcionamento do projeto.

A ideia foi simplesmente criar um nome para uma pequena stack de infraestrutura que funciona como um "pássaro" levando o tráfego de um ponto para outro. 🐦

---

# 🔐 Por que não usar somente NetBird?

O NetBird por si só já resolve uma grande parte do problema.

Com todos os dispositivos conectados ao NetBird, seria possível acessar diretamente os serviços através da rede privada.

Porém, isso cria uma exigência:

```text
Computador do usuário
        │
        ▼
   NetBird instalado
        │
        ▼
Rede privada
        │
        ▼
Servidor remoto
```

Para um ambiente onde vários funcionários precisam acessar apenas alguns serviços, instalar e gerenciar um cliente VPN em cada máquina pode não ser a abordagem desejada.

Com o Quantic Bird:

```text
Computador do usuário
        │
        │ conexão normal
        ▼
Servidor de acesso
        │
        │ NetBird
        ▼
Servidor remoto
```

O usuário final não precisa necessariamente conhecer ou participar da rede privada.

---

# 🌐 E por que não usar Cloudflare?

Também é perfeitamente possível utilizar soluções como:

* Cloudflare Tunnel;
* Nginx;
* Traefik;
* outros reverse proxies;
* VPNs tradicionais;
* port forwarding;
* soluções de acesso remoto.

Inclusive, o próprio Quantic Bird pode ser combinado com um **Cloudflare Tunnel**.

Por exemplo:

```text
Internet
   │
   ▼
Cloudflare
   │
   ▼
Cloudflare Tunnel
   │
   ▼
Servidor de acesso
   │
   ▼
Quantic Bird
   │
   ▼
NetBird
   │
   ▼
Servidor remoto
```

Porém, esse não é o objetivo principal do projeto.

O objetivo inicial é resolver o problema utilizando a infraestrutura existente, sem adicionar obrigatoriamente:

* domínio;
* IP público;
* IP fixo;
* infraestrutura externa;
* serviços pagos.

A prioridade é manter a solução com **custo próximo de zero**.

---

# 🔌 Não depende necessariamente do NetBird

Apesar de o projeto ter sido criado utilizando o NetBird, o conceito não é exclusivo dele.

O requisito principal é possuir algum tipo de **rede privada/overlay network** capaz de conectar o servidor de acesso ao servidor remoto.

Por exemplo:

* NetBird;
* Tailscale;
* WireGuard;
* ZeroTier;
* outras soluções baseadas em VPN/overlay network.

A arquitetura pode ser representada assim:

```text
                    Overlay Network
                          │
              ┌───────────┴───────────┐
              │                       │
      Servidor de acesso        Servidor remoto
              │                       │
              │                       │
           socat ──────────────────► Serviço
```

O Quantic Bird utiliza a rede privada apenas como meio de transporte.

---

# 🏗️ Arquitetura

Uma implantação típica possui três componentes:

### 1. Cliente

É o computador que precisa acessar o serviço.

Ele não precisa necessariamente possuir o cliente da VPN/overlay network.

### 2. Servidor de acesso

É o servidor que possui conectividade com a rede privada.

Nele roda o Quantic Bird.

Esse servidor recebe as conexões TCP e encaminha o tráfego para o servidor remoto.

### 3. Servidor remoto

É o servidor que hospeda o serviço.

Ele pode estar atrás de:

* CGNAT;
* Starlink;
* NAT;
* firewall;
* rede sem IP público.

Desde que o servidor remoto consiga estabelecer comunicação com a rede privada, ele pode ser alcançado pelo proxy.

---

# 📦 Exemplo

Suponha que exista um MySQL no servidor remoto:

```text
Servidor remoto
IP NetBird: 100.100.100.20
Porta: 3306
```

No servidor de acesso podemos criar:

```text
Porta de entrada: 3307
Destino: 100.100.100.20:3306
```

O fluxo será:

```text
Cliente
   │
   │  servidor-acesso:3307
   ▼
Quantic Bird
   │
   │  100.100.100.20:3306
   ▼
MySQL
```

O cliente pode então utilizar:

```text
Host: servidor-acesso
Port: 3307
```

sem precisar conhecer ou acessar diretamente o IP privado do servidor remoto.

---

# ⚙️ Stack

O projeto foi desenvolvido utilizando principalmente:

* Docker
* Docker Compose
* socat
* uma rede overlay/VPN

A escolha pelo Docker permite manter a configuração isolada e facilita a criação de múltiplos proxies.

---

# 🚀 Objetivos do projeto

O Quantic Bird foi criado com alguns objetivos simples:

* ✅ Acessar serviços atrás de CGNAT
* ✅ Funcionar com Starlink
* ✅ Evitar port forwarding
* ✅ Evitar a necessidade de IP público
* ✅ Evitar a necessidade de IP fixo
* ✅ Permitir acesso sem instalar a VPN em todos os clientes
* ✅ Criar proxies TCP de forma simples
* ✅ Ser executado através de Docker
* ✅ Ter zero custo de operação
* ✅ Ser independente do provedor de Internet

---

# ⚠️ O que o Quantic Bird não é

O Quantic Bird não pretende substituir:

* VPNs;
* reverse proxies;
* firewalls;
* soluções Zero Trust;
* Cloudflare Tunnel;
* sistemas de autenticação;
* balanceadores de carga.

Ele é uma ferramenta simples para um problema específico:

> **encaminhar conexões TCP de um ponto acessível até um serviço que só pode ser alcançado através de uma rede privada.**

---

# 🔒 Segurança

O Quantic Bird deve ser utilizado com atenção quando portas forem expostas para a Internet.

O proxy TCP não deve ser considerado, por si só, uma camada de autenticação ou segurança.

Por exemplo, simplesmente criar:

```text
Internet
   │
   ▼
TCP Proxy
   │
   ▼
MySQL
```

pode expor um serviço sensível diretamente.

Sempre que possível, recomenda-se combinar o Quantic Bird com mecanismos adicionais, como:

* firewall;
* restrição de IP;
* autenticação do próprio serviço;
* VPN;
* Cloudflare Tunnel;
* Zero Trust;
* TLS;
* controle de portas expostas.

Uma arquitetura mais segura pode ser:

```text
Internet
   │
   ▼
Cloudflare / VPN / Firewall
   │
   ▼
Quantic Bird
   │
   ▼
Overlay Network
   │
   ▼
Serviço
```

---

# 🛠️ Próximos passos

O projeto ainda é bastante simples e surgiu originalmente como uma solução prática para uma necessidade real.

Algumas melhorias que podem ser implementadas futuramente:

* [x] geração automática do `docker-compose.yml`;
* [ ] gerenciamento de múltiplos serviços;
* [ ] configuração através de arquivo `.env`;
* [ ] health checks;
* [ ] logs mais detalhados;
* [ ] métricas;
* [ ] suporte a UDP;
* [ ] configuração dinâmica de proxies;
* [ ] interface web para gerenciamento;
* [ ] autenticação;
* [ ] TLS;
* [ ] integração mais direta com diferentes redes overlay;
* [ ] documentação de arquiteturas com Cloudflare Tunnel;
* [ ] suporte a múltiplos servidores de acesso.

---

# 📐 Conceito resumido

O Quantic Bird pode ser resumido em uma ideia:

```text
                 SEM ACESSO DIRETO
                 À REDE REMOTA
                       │
                       ▼
                ┌─────────────┐
                │   Cliente   │
                └──────┬──────┘
                       │
                       │ TCP
                       ▼
                ┌─────────────┐
                │   Quantic   │
                │    Bird     │
                └──────┬──────┘
                       │
                       │ Overlay VPN
                       ▼
                ┌─────────────┐
                │   Servidor  │
                │    remoto   │
                └──────┬──────┘
                       │
                       ▼
                   Serviço
```

Uma pequena camada de proxy permite que uma rede privada seja utilizada como **meio de transporte**, sem obrigar todos os clientes a fazer parte dessa rede.

---

# 🤝 Contribuições

Contribuições, sugestões e melhorias são bem-vindas.

Se você encontrar algum problema ou tiver uma ideia para melhorar o projeto, fique à vontade para abrir uma **Issue** ou enviar um **Pull Request**.

---

## 👨‍💻 Autor

Desenvolvido por **Anorahk**.

Projeto criado a partir de uma necessidade real de infraestrutura e posteriormente transformado em uma stack reutilizável para cenários semelhantes.

---

> **Quantic Bird — Simple TCP proxying through private networks. 🐦**
