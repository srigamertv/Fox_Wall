# Fox_Wall

Sistema administrativo de identificação 3D para RedM.

## 🔥 Funcionalidades

- Exibe **ID, nome e emprego** dos jogadores próximos.
- Mostra quando o jogador está falando no voice chat.
- Distância e atualização configuráveis.
- Compatível com **VORP, RSG e standalone**.
- Permissão por **ACE** e grupos dos frameworks.
- Sem item de inventário: o Wall é usado apenas pelo comando `/wall`.

## 🛠️ Instalação

1. Coloque a pasta `Fox_Wall` em `resources`.
2. Adicione `ensure Fox_Wall` ao `server.cfg`.
3. Configure `shared/config.lua`.

### ACE

O ACE padrão é:

```cfg
add_ace group.admin fox.wall allow
```

No **VORP**, o recurso verifica os dois métodos de grupo usados pela base: `users.group` e `characters.group`. Os grupos aceitos ficam em `Config.Permission.VORP.Groups`.

No **RSG**, ele usa `RSGCore.Functions.HasPermission` com `admin`/`god`. Também existe suporte opcional para a tabela `admin_roles` por `citizenid`, configurável em `Config.Permission.RSG`.

## ⚙️ Framework

```lua
Config.Framework = 'auto' -- auto / vorp / rsg / standalone
```

No VORP o recurso lê nome/job do personagem e verifica tanto o grupo da conta quanto o grupo do personagem. No RSG usa `PlayerData.charinfo`, `PlayerData.job` e as permissões nativas do RSG Core.

## ✍️ Créditos

Desenvolvido e adaptado por **SR.IGAMER TV | FOX**.

<br>

**MINHA LOJA:**
<div>
  <a href="https://discord.gg/ySk8WVzY5n" target="_blank"><img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" target="_blank"></a>
</div>

<br>

**Siga-nos:**
<div>
  <a href="https://www.youtube.com/@SRIGAMERTV" target="_blank"><img src="https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" target="_blank"></a>
  <a href="https://www.instagram.com/sr.igamer_tv" target="_blank"><img src="https://img.shields.io/badge/-Instagram-%23E4405F?style=for-the-badge&logo=instagram&logoColor=white" target="_blank"></a>
  <a href="https://discord.gg/kh2KTGvaVX" target="_blank"><img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" target="_blank"></a>
</div>

<br>

**Entrar-contato:**
<div>
  <a href="mailto:kelvinsom22kb@gmail.com"><img src="https://img.shields.io/badge/-Gmail-%23333?style=for-the-badge&logo=gmail&logoColor=white" target="_blank"></a>
</div>


## 🛡️ Licença

Distribuído sob a licença MIT. Consulte `LICENSE`.
